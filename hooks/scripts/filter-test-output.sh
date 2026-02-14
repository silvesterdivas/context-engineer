#!/bin/bash
# Token-saving filter for test runner output (npm test, jest, pytest, vitest, etc.)
# Reduces verbose test output to failures + summary only.

# Bail if jq is not available
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null) || exit 0
RESPONSE=$(echo "$INPUT" | jq -r '.tool_response // ""' 2>/dev/null) || exit 0

# Only filter test commands
case "$COMMAND" in
  *"npm test"*|*"npx jest"*|*"npx vitest"*|*"pytest"*|*"go test"*|*"cargo test"*|*"npm run test"*)
    ;;
  *)
    exit 0
    ;;
esac

# Skip short output (< 30 lines) — not worth filtering
LINE_COUNT=$(echo "$RESPONSE" | wc -l | tr -d ' ')
if [ "$LINE_COUNT" -lt 30 ]; then
  exit 0
fi

# Extract failures and summary lines
FAILURES=$(echo "$RESPONSE" | grep -E "FAIL|✕|✗|FAILED|Error:|error TS|AssertionError|Expected|Received|●" | head -30)
SUMMARY=$(echo "$RESPONSE" | grep -E "Tests:|Test Suites:|passed|failed|Ran [0-9]|[0-9]+ (passed|failed)|PASS|FAIL" | tail -5)

# Build filtered output
FILTERED=""
[ -n "$FAILURES" ] && FILTERED="$FAILURES"
[ -n "$SUMMARY" ] && FILTERED="${FILTERED:+$FILTERED
---
}$SUMMARY"

# If we captured something, return filtered version
if [ -n "$FILTERED" ]; then
  jq -n --arg filtered "$FILTERED" --arg lines "$LINE_COUNT" '{
    suppressOutput: true,
    message: ("[token-saving] Test output filtered: " + $lines + " lines → summary\n" + $filtered)
  }'
fi

exit 0
