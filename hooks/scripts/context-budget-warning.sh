#!/bin/bash
# Context Budget Warning Hook (PostToolUse)
# Uses multi-signal scoring to estimate context usage and warns at zone thresholds.
# Fires once per zone transition — no spam.
# Creates a sentinel file on RED zone to trigger auto-handoff.

set -euo pipefail

# Bail if jq is not available (needed for JSON parsing)
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')

# Bail if we don't have what we need or file is empty
if [ -z "$SESSION_ID" ] || [ -z "$TRANSCRIPT_PATH" ] || [ ! -s "$TRANSCRIPT_PATH" ]; then
  exit 0
fi

CACHE_FILE="/tmp/context-budget-${SESSION_ID}"
SENTINEL_FILE="/tmp/context-engineer-handoff-${SESSION_ID}"

# Fast path: if we already announced RED, nothing left to do
if [ -f "$CACHE_FILE" ]; then
  LAST_ZONE=$(cat "$CACHE_FILE")
  if [ "$LAST_ZONE" = "RED" ]; then
    exit 0
  fi
else
  LAST_ZONE="GREEN"
fi

# --- Signal 1: File size (proxy for total context) ---
FILE_SIZE=$(wc -c < "$TRANSCRIPT_PATH" | tr -d ' ')
ESTIMATED_TOKENS=$((FILE_SIZE / 4))
BUDGET=200000

if [ "$BUDGET" -gt 0 ]; then
  FILE_SIZE_PCT=$((ESTIMATED_TOKENS * 100 / BUDGET))
  if [ "$FILE_SIZE_PCT" -gt 100 ]; then
    FILE_SIZE_PCT=100
  fi
else
  exit 0
fi

# --- Signal 2: Message count ---
count_messages() {
  grep -c '"role"\s*:' "$TRANSCRIPT_PATH" 2>/dev/null || echo 0
}
MSG_COUNT=$(count_messages)
# Normalize: 50 messages = 100%
MSG_COUNT_PCT=$((MSG_COUNT * 100 / 50))
if [ "$MSG_COUNT_PCT" -gt 100 ]; then
  MSG_COUNT_PCT=100
fi

# --- Signal 3: Compression/summarization markers ---
detect_compression() {
  # Match system compression markers, not user content about compression
  # Look for patterns like "messages have been compressed" or "context was summarized"
  if grep -qE '(messages|context|conversation|prior messages).*(compressed|summarized|truncated)|automatically compress|system-reminder.*compress' "$TRANSCRIPT_PATH" 2>/dev/null; then
    echo 100
  else
    echo 0
  fi
}
COMPRESSION_PCT=$(detect_compression)

# --- Signal 4: Tool call density ---
count_tool_calls() {
  grep -c '"tool_use"' "$TRANSCRIPT_PATH" 2>/dev/null || echo 0
}
TOOL_COUNT=$(count_tool_calls)
# Normalize: 60 tool calls = 100%
TOOL_DENSITY_PCT=$((TOOL_COUNT * 100 / 60))
if [ "$TOOL_DENSITY_PCT" -gt 100 ]; then
  TOOL_DENSITY_PCT=100
fi

# --- Composite score ---
# Weights: file_size 30%, message_count 30%, compression 25%, tool_density 15%
SCORE=$(( (FILE_SIZE_PCT * 30 + MSG_COUNT_PCT * 30 + COMPRESSION_PCT * 25 + TOOL_DENSITY_PCT * 15) / 100 ))

# --- 15-turn minimum floor ---
# Prevent false positives on early large file reads
if [ "$MSG_COUNT" -lt 15 ]; then
  SCORE=0
fi

# Determine current zone from composite score
if [ "$SCORE" -ge 85 ]; then
  ZONE="RED"
elif [ "$SCORE" -ge 75 ]; then
  ZONE="ORANGE"
elif [ "$SCORE" -ge 60 ]; then
  ZONE="YELLOW"
else
  ZONE="GREEN"
fi

# Only warn on zone transitions (escalations only, never downgrade)
zone_rank() {
  case "$1" in
    GREEN)  echo 0 ;;
    YELLOW) echo 1 ;;
    ORANGE) echo 2 ;;
    RED)    echo 3 ;;
    *)      echo 0 ;;
  esac
}

CURRENT_RANK=$(zone_rank "$ZONE")
LAST_RANK=$(zone_rank "$LAST_ZONE")

if [ "$CURRENT_RANK" -le "$LAST_RANK" ]; then
  exit 0
fi

# Record the new zone
echo "$ZONE" > "$CACHE_FILE"

# Create sentinel file on RED zone (atomic write to avoid race conditions)
if [ "$ZONE" = "RED" ] && [ ! -f "$SENTINEL_FILE" ]; then
  TMPSENTINEL=$(mktemp "${SENTINEL_FILE}.tmp.XXXXXX" 2>/dev/null) || TMPSENTINEL="${SENTINEL_FILE}.tmp.$$"
  jq -n \
    --arg sid "$SESSION_ID" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson score "$SCORE" \
    --argjson file_size_pct "$FILE_SIZE_PCT" \
    --argjson msg_count "$MSG_COUNT" \
    --argjson msg_count_pct "$MSG_COUNT_PCT" \
    --argjson compression_pct "$COMPRESSION_PCT" \
    --argjson tool_count "$TOOL_COUNT" \
    --argjson tool_density_pct "$TOOL_DENSITY_PCT" \
    '{
      session_id: $sid,
      timestamp: $ts,
      composite_score: $score,
      signals: {
        file_size_pct: $file_size_pct,
        message_count: $msg_count,
        message_count_pct: $msg_count_pct,
        compression_detected_pct: $compression_pct,
        tool_call_count: $tool_count,
        tool_density_pct: $tool_density_pct
      }
    }' > "$TMPSENTINEL" && mv -n "$TMPSENTINEL" "$SENTINEL_FILE" 2>/dev/null
  rm -f "$TMPSENTINEL" 2>/dev/null
fi

# Build the warning message with score breakdown
BREAKDOWN="[file_size=${FILE_SIZE_PCT}% msgs=${MSG_COUNT}(${MSG_COUNT_PCT}%) compression=${COMPRESSION_PCT}% tools=${TOOL_COUNT}(${TOOL_DENSITY_PCT}%)]"

case "$ZONE" in
  YELLOW)
    MSG="YELLOW ZONE — Composite score: ${SCORE}% ${BREAKDOWN}. Be selective: prefer Grep over Read, summarize before processing large files."
    ;;
  ORANGE)
    MSG="ORANGE ZONE — Composite score: ${SCORE}% ${BREAKDOWN}. Conserve aggressively: targeted searches only, no full file reads. Consider wrapping up soon."
    ;;
  RED)
    MSG="RED ZONE — Composite score: ${SCORE}% ${BREAKDOWN}. Context budget exhausted. Stop starting new work. Auto-handoff activated — generate TASK.md + PROGRESS.md now, then suggest a fresh conversation."
    ;;
  *)
    exit 0
    ;;
esac

jq -n --arg msg "$MSG" '{
  systemMessage: ("[context-budget] " + $msg)
}'

exit 0
