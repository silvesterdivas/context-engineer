#!/usr/bin/env bash
# filter-build-output.sh — Filters verbose build output to keep only errors + warnings.
# Saves ~90% of tokens on build runs.
# Triggered as a PostToolUse hook on Bash commands.

set -euo pipefail

INPUT=$(cat)

# Extract the command that was run
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
if [ -z "$COMMAND" ]; then
  exit 0
fi

# Only process build commands
if ! echo "$COMMAND" | grep -qiE '(npm run build|npx tsc|yarn build|pnpm build|tsc --build|tsc -b|gradlew|gradle build|xcodebuild|cargo build|make( |$)|cmake --build|go build|dotnet build|swift build|mix compile)'; then
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

# Filter: keep errors, warnings, and build result summary
FILTERED=$(echo "$RESULT" | grep -iE '(error[: \[]|warning[: \[]|failed|fatal|cannot find|not found|undefined|TS[0-9]{4}|BUILD (SUCCEEDED|FAILED)|Build completed|build failed|Compiling .* error|error\[E[0-9]+\])' | head -100)

# If nothing matched (clean build), provide a short summary
if [ -z "$FILTERED" ]; then
  FILTERED="Build completed successfully. ($LINE_COUNT lines of output filtered)"
fi

# Output the filtered result as a system message
jq -n --arg msg "[build-filter] Filtered $LINE_COUNT lines → $(echo "$FILTERED" | wc -l | tr -d ' ') lines:
$FILTERED" \
  '{"systemMessage": $msg}'
