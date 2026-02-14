#!/bin/bash
# Token-saving filter for build output (expo, tsc, webpack, vite, etc.)
# Reduces verbose build output to errors + summary only.

# Bail if jq is not available
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null) || exit 0
RESPONSE=$(echo "$INPUT" | jq -r '.tool_response // ""' 2>/dev/null) || exit 0

# Only filter build commands
case "$COMMAND" in
  *"npm run build"*|*"npx expo"*|*"npx tsc"*|*"webpack"*|*"vite build"*|*"cargo build"*|*"go build"*|*"npm run compile"*)
    ;;
  *)
    exit 0
    ;;
esac

# Skip short output
LINE_COUNT=$(echo "$RESPONSE" | wc -l | tr -d ' ')
if [ "$LINE_COUNT" -lt 30 ]; then
  exit 0
fi

# Extract errors and warnings
ERRORS=$(echo "$RESPONSE" | grep -E "error TS|ERROR|Error:|error:|fatal:|FATAL" | head -20)
WARNINGS=$(echo "$RESPONSE" | grep -E "warning TS|WARNING|warn:" | head -10)
SUMMARY=$(echo "$RESPONSE" | grep -E "compiled|bundled|Built|Compiled|Successfully|Done in|finished|✓|✔" | tail -5)

# Build filtered output
FILTERED=""
[ -n "$ERRORS" ] && FILTERED="Errors:
$ERRORS"
[ -n "$WARNINGS" ] && FILTERED="${FILTERED:+$FILTERED
---
}Warnings:
$WARNINGS"
[ -n "$SUMMARY" ] && FILTERED="${FILTERED:+$FILTERED
---
}$SUMMARY"

if [ -n "$FILTERED" ]; then
  jq -n --arg filtered "$FILTERED" --arg lines "$LINE_COUNT" '{
    suppressOutput: true,
    message: ("[token-saving] Build output filtered: " + $lines + " lines → summary\n" + $filtered)
  }'
fi

exit 0
