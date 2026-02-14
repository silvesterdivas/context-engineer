#!/bin/bash
# Context Budget Warning Hook (PostToolUse)
# Uses real token counts from the transcript to detect context budget zones.
# Falls back to heuristic scoring when token data is unavailable.
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

BUDGET=200000
CONTEXT_PCT=0
SOURCE="unknown"

# --- Primary: Real token data from last assistant message ---
# Each assistant message in the transcript has usage.input_tokens,
# usage.cache_read_input_tokens, and usage.cache_creation_input_tokens.
# Their sum = actual context window usage for that API call.
LAST_USAGE=$(grep '"type":"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null | tail -1 | \
  jq '(.message.usage.input_tokens // 0) + (.message.usage.cache_read_input_tokens // 0) + (.message.usage.cache_creation_input_tokens // 0)' 2>/dev/null) || LAST_USAGE=0

if [ -n "$LAST_USAGE" ] && [ "$LAST_USAGE" -gt 0 ]; then
  CONTEXT_PCT=$((LAST_USAGE * 100 / BUDGET))
  if [ "$CONTEXT_PCT" -gt 100 ]; then
    CONTEXT_PCT=100
  fi
  SOURCE="tokens"
else
  # --- Fallback: Heuristic scoring when token data unavailable ---
  FILE_SIZE=$(wc -c < "$TRANSCRIPT_PATH" | tr -d ' ')
  ESTIMATED_TOKENS=$((FILE_SIZE / 4))
  FILE_SIZE_PCT=$((ESTIMATED_TOKENS * 100 / BUDGET))
  [ "$FILE_SIZE_PCT" -gt 100 ] && FILE_SIZE_PCT=100

  MSG_COUNT=$(grep -c '"role"\s*:' "$TRANSCRIPT_PATH" 2>/dev/null) || MSG_COUNT=0
  MSG_COUNT_PCT=$((MSG_COUNT * 100 / 50))
  [ "$MSG_COUNT_PCT" -gt 100 ] && MSG_COUNT_PCT=100

  TOOL_COUNT=$(grep -c '"tool_use"' "$TRANSCRIPT_PATH" 2>/dev/null) || TOOL_COUNT=0
  TOOL_DENSITY_PCT=$((TOOL_COUNT * 100 / 60))
  [ "$TOOL_DENSITY_PCT" -gt 100 ] && TOOL_DENSITY_PCT=100

  CONTEXT_PCT=$(( (FILE_SIZE_PCT * 40 + MSG_COUNT_PCT * 35 + TOOL_DENSITY_PCT * 25) / 100 ))
  SOURCE="heuristic"
fi

# --- 15-turn minimum floor ---
# Prevent false positives on early large file reads
MSG_COUNT_CHECK=$(grep -c '"role"\s*:' "$TRANSCRIPT_PATH" 2>/dev/null) || MSG_COUNT_CHECK=0
if [ "$MSG_COUNT_CHECK" -lt 15 ]; then
  CONTEXT_PCT=0
fi

# Determine current zone
if [ "$CONTEXT_PCT" -ge 85 ]; then
  ZONE="RED"
elif [ "$CONTEXT_PCT" -ge 75 ]; then
  ZONE="ORANGE"
elif [ "$CONTEXT_PCT" -ge 60 ]; then
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
    --argjson score "$CONTEXT_PCT" \
    --arg source "$SOURCE" \
    --argjson tokens "${LAST_USAGE:-0}" \
    '{
      session_id: $sid,
      timestamp: $ts,
      context_pct: $score,
      source: $source,
      total_input_tokens: $tokens,
      budget: 200000
    }' > "$TMPSENTINEL" && mv -n "$TMPSENTINEL" "$SENTINEL_FILE" 2>/dev/null
  rm -f "$TMPSENTINEL" 2>/dev/null
fi

# Build the warning message
if [ "$SOURCE" = "tokens" ]; then
  BREAKDOWN="[${LAST_USAGE}/${BUDGET} tokens, source=actual]"
else
  BREAKDOWN="[${CONTEXT_PCT}% estimated, source=heuristic]"
fi

case "$ZONE" in
  YELLOW)
    MSG="YELLOW ZONE — Context: ${CONTEXT_PCT}% ${BREAKDOWN}. Be selective: prefer Grep over Read, summarize before processing large files."
    ;;
  ORANGE)
    MSG="ORANGE ZONE — Context: ${CONTEXT_PCT}% ${BREAKDOWN}. Conserve aggressively: targeted searches only, no full file reads. Consider wrapping up soon."
    ;;
  RED)
    MSG="RED ZONE — Context: ${CONTEXT_PCT}% ${BREAKDOWN}. Context budget exhausted. Stop starting new work. Auto-handoff activated — generate TASK.md + PROGRESS.md now, then suggest a fresh conversation."
    ;;
  *)
    exit 0
    ;;
esac

jq -n --arg msg "$MSG" '{
  systemMessage: ("[context-budget] " + $msg)
}'

exit 0
