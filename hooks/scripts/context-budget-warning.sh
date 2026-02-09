#!/bin/bash
# Context Budget Warning Hook (PostToolUse)
# Estimates context usage from transcript file size and warns at zone thresholds.
# Fires once per zone transition — no spam.

set -euo pipefail

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')

# Bail if we don't have what we need
if [ -z "$SESSION_ID" ] || [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  exit 0
fi

CACHE_FILE="/tmp/context-budget-${SESSION_ID}"

# Fast path: if we already announced RED, nothing left to do
if [ -f "$CACHE_FILE" ]; then
  LAST_ZONE=$(cat "$CACHE_FILE")
  if [ "$LAST_ZONE" = "RED" ]; then
    exit 0
  fi
else
  LAST_ZONE="GREEN"
fi

# Estimate tokens from transcript file size
# ~4 chars per token is a rough approximation
FILE_SIZE=$(wc -c < "$TRANSCRIPT_PATH" | tr -d ' ')
ESTIMATED_TOKENS=$((FILE_SIZE / 4))

# 200k context window budget
BUDGET=200000

# Calculate percentage
if [ "$BUDGET" -gt 0 ]; then
  PERCENT=$((ESTIMATED_TOKENS * 100 / BUDGET))
else
  exit 0
fi

# Determine current zone
if [ "$PERCENT" -ge 85 ]; then
  ZONE="RED"
elif [ "$PERCENT" -ge 75 ]; then
  ZONE="ORANGE"
elif [ "$PERCENT" -ge 60 ]; then
  ZONE="YELLOW"
else
  ZONE="GREEN"
fi

# Only warn on zone transitions (escalations only, never downgrade)
# Zone ordering: GREEN=0, YELLOW=1, ORANGE=2, RED=3
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
  # No escalation — nothing to announce
  exit 0
fi

# Record the new zone
echo "$ZONE" > "$CACHE_FILE"

# Build the warning message
case "$ZONE" in
  YELLOW)
    MSG="YELLOW ZONE — Context at ~${PERCENT}%. Be selective: prefer Grep over Read, summarize before processing large files."
    ;;
  ORANGE)
    MSG="ORANGE ZONE — Context at ~${PERCENT}%. Conserve aggressively: targeted searches only, no full file reads. Consider wrapping up soon."
    ;;
  RED)
    MSG="RED ZONE — Context at ~${PERCENT}%. Wrap up now. Run /context-engineer:fresh-context to save progress, then start a new conversation."
    ;;
  *)
    exit 0
    ;;
esac

# Output warning as both a user-visible message and context for Claude
jq -n --arg msg "$MSG" '{
  systemMessage: ("[context-budget] " + $msg)
}'

exit 0
