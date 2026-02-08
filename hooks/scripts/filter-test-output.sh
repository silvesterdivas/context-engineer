#!/usr/bin/env bash
# filter-test-output.sh — Filters verbose test output to keep only failures + summary.
# Saves ~80% of tokens on test runs.
# Triggered as a PostToolUse hook on Bash commands.

set -euo pipefail

INPUT=$(cat)

# Extract the command that was run
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
if [ -z "$COMMAND" ]; then
  exit 0
fi

# Only process test commands
if ! echo "$COMMAND" | grep -qiE '(npm test|npx (jest|vitest)|yarn test|pnpm test|pytest|python -m pytest|swift test|go test|cargo test|bundle exec rspec|mix test|dart test|flutter test)'; then
  exit 0
fi

# Extract the tool result
RESULT=$(echo "$INPUT" | jq -r '.tool_result // empty' 2>/dev/null)
if [ -z "$RESULT" ]; then
  exit 0
fi

# Skip filtering for short output (< 40 lines)
LINE_COUNT=$(echo "$RESULT" | wc -l | tr -d ' ')
if [ "$LINE_COUNT" -lt 40 ]; then
  exit 0
fi

# Filter: keep FAIL, ERROR, FAILED, panic, summary lines
FILTERED=$(echo "$RESULT" | grep -iE '(FAIL|ERROR|FAILED|panic|✗|✘|×|BROKEN|Tests:|test result:|Test Suites:|Tests run:|Ran [0-9]+ test|passed|failed|skipped|[0-9]+ (passing|failing|pending)|PASS$|assert|Expected|Received|at .*:[0-9]+)' | head -100)

# If nothing matched (all tests passed), provide a short summary
if [ -z "$FILTERED" ]; then
  PASS_COUNT=$(echo "$RESULT" | grep -ciE '(pass|✓|✔|ok)' || echo "0")
  FILTERED="All tests passed. ($PASS_COUNT passing indicators found in $LINE_COUNT lines of output)"
fi

# Output the filtered result as a system message
jq -n --arg msg "[test-filter] Filtered $LINE_COUNT lines → $(echo "$FILTERED" | wc -l | tr -d ' ') lines:
$FILTERED" \
  '{"systemMessage": $msg}'
