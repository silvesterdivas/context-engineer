#!/bin/bash
# Token-saving filter for linter output (eslint, prettier, stylelint, etc.)
# Reduces verbose lint output to error count + top issues only.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
RESPONSE=$(echo "$INPUT" | jq -r '.tool_response // ""')

# Only filter lint commands
case "$COMMAND" in
  *"npm run lint"*|*"npx eslint"*|*"npx prettier"*|*"stylelint"*|*"pylint"*|*"flake8"*|*"clippy"*)
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

# Extract error lines (file:line:col pattern) and summary
ISSUES=$(echo "$RESPONSE" | grep -E "error|warning" | grep -E "^\s*/|^\s*[0-9]+:" | head -15)
SUMMARY=$(echo "$RESPONSE" | grep -E "✖|problems?|errors?.*warnings?|[0-9]+ error|All files pass" | tail -3)

# Build filtered output
FILTERED=""
[ -n "$ISSUES" ] && FILTERED="Top issues:
$ISSUES"
[ -n "$SUMMARY" ] && FILTERED="${FILTERED:+$FILTERED
---
}$SUMMARY"

if [ -n "$FILTERED" ]; then
  jq -n --arg filtered "$FILTERED" --arg lines "$LINE_COUNT" '{
    suppressOutput: true,
    message: ("[token-saving] Lint output filtered: " + $lines + " lines → summary\n" + $filtered)
  }'
fi

exit 0
