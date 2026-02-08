#!/usr/bin/env bash
# filter-lint-output.sh — Filters verbose lint output to keep only problems.
# Saves ~70% of tokens on lint runs.
# Triggered as a PostToolUse hook on Bash commands.

set -euo pipefail

INPUT=$(cat)

# Extract the command that was run
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
if [ -z "$COMMAND" ]; then
  exit 0
fi

# Only process lint commands
if ! echo "$COMMAND" | grep -qiE '(eslint|npx eslint|biome (check|lint)|swiftlint|pylint|flake8|clippy|cargo clippy|rubocop|golangci-lint|ktlint|stylelint|prettier --check|tslint)'; then
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

# Filter: keep problem lines (errors, warnings, file:line references)
FILTERED=$(echo "$RESULT" | grep -iE '(error|warning|problem|✖|✗|×|[0-9]+ error|[0-9]+ warning|^\s*[0-9]+:[0-9]+|/.*\.[a-z]+:[0-9]+:[0-9]+|^\s*(E|W|C|F)[0-9]+)' | head -100)

# If nothing matched (clean lint), provide a short summary
if [ -z "$FILTERED" ]; then
  FILTERED="Lint passed with no issues. ($LINE_COUNT lines of output filtered)"
fi

# Output the filtered result as a system message
jq -n --arg msg "[lint-filter] Filtered $LINE_COUNT lines → $(echo "$FILTERED" | wc -l | tr -d ' ') lines:
$FILTERED" \
  '{"systemMessage": $msg}'
