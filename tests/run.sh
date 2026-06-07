#!/bin/bash
# Test harness for the context-engineer hook scripts.
# Self-contained: generates fixtures on the fly, feeds them to the hooks on
# stdin (the PostToolUse contract), and asserts on the emitted JSON.
# Requires: bash, jq. Run from anywhere: bash tests/run.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS="$ROOT/hooks/scripts"

PASS=0
FAIL=0

ok()   { printf "  PASS  %s\n" "$1"; PASS=$((PASS + 1)); }
bad()  { printf "  FAIL  %s\n" "$1"; printf "        %s\n" "$2"; FAIL=$((FAIL + 1)); }

assert_contains() {
  # $1 label  $2 haystack  $3 needle
  case "$2" in
    *"$3"*) ok "$1" ;;
    *) bad "$1" "expected to contain: $3 | got: ${2:-<empty>}" ;;
  esac
}

assert_empty() {
  # $1 label  $2 output
  if [ -z "$2" ]; then ok "$1"; else bad "$1" "expected empty output, got: $2"; fi
}

# Build a PostToolUse input JSON from a command + response string.
make_input() { jq -n --arg cmd "$1" --arg resp "$2" '{tool_input:{command:$cmd}, tool_response:$resp}'; }

noise() { seq 40 | sed 's/^/noise line /'; }

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to run the tests" >&2
  exit 2
fi

echo "context-engineer hook tests"
echo "---------------------------"

# --- filter-build-output.sh ---
build_resp=$(printf 'src/x.ts(3,5): error TS2304: Cannot find name foo\nwarning TS6133: unused var\n%s\nCompiled successfully' "$(noise)")
out=$(make_input "npm run build" "$build_resp" | bash "$HOOKS/filter-build-output.sh")
assert_contains "build: matching command is filtered" "$out" '"suppressOutput": true'
assert_contains "build: keeps the error line"          "$out" 'error TS2304'
assert_contains "build: labels output as Build"        "$out" '[token-saving] Build'

# new matcher added from the review (gradle)
out=$(make_input "gradle build" "$build_resp" | bash "$HOOKS/filter-build-output.sh")
assert_contains "build: gradle matcher fires"          "$out" '[token-saving] Build'

# defensive: tolerate tool_response delivered as an object instead of a string
obj_input=$(jq -n --arg resp "$build_resp" '{tool_input:{command:"npm run build"}, tool_response:{stdout:$resp, stderr:"", interrupted:false}}')
out=$(printf '%s' "$obj_input" | bash "$HOOKS/filter-build-output.sh")
assert_contains "build: object tool_response (.stdout) is filtered" "$out" 'error TS2304'

# --- filter-test-output.sh ---
test_resp=$(printf 'FAIL src/a.test.ts\n  AssertionError: Expected 1 Received 2\n%s\nTests: 1 failed, 5 passed' "$(noise)")
out=$(make_input "npx jest" "$test_resp" | bash "$HOOKS/filter-test-output.sh")
assert_contains "test: matching command is filtered" "$out" '"suppressOutput": true'
assert_contains "test: keeps the failure line"        "$out" 'AssertionError'
assert_contains "test: labels output as Test"         "$out" '[token-saving] Test'

# --- filter-lint-output.sh ---
lint_resp=$(printf '/src/a.ts\n  3:1  error  Missing semicolon\n  4:2  warning  Unused var\n%s\n✖ 2 problems (1 error, 1 warning)' "$(noise)")
out=$(make_input "npx eslint ." "$lint_resp" | bash "$HOOKS/filter-lint-output.sh")
assert_contains "lint: matching command is filtered"  "$out" '"suppressOutput": true'
assert_contains "lint: extracts an issue line"        "$out" '3:1'
assert_contains "lint: labels output as Lint"         "$out" '[token-saving] Lint'

# new matcher added from the review (biome)
out=$(make_input "npx @biomejs/biome lint" "$lint_resp" | bash "$HOOKS/filter-lint-output.sh")
assert_contains "lint: biome matcher fires"           "$out" '[token-saving] Lint'

# --- guard rails shared by all filters ---
out=$(make_input "ls -la" "$build_resp" | bash "$HOOKS/filter-build-output.sh")
assert_empty "build: non-matching command passes through" "$out"

out=$(make_input "npm run build" "short output" | bash "$HOOKS/filter-build-output.sh")
assert_empty "build: short output is not filtered" "$out"

# --- context-budget-warning.sh ---
# 16 assistant turns (clears the 15-turn floor); last usage = 650k/1M = 65% -> YELLOW.
tr_file="$(mktemp)"
i=0
while [ "$i" -lt 16 ]; do
  printf '{"type":"assistant","role":"assistant","message":{"usage":{"input_tokens":650000,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}}}\n'
  i=$((i + 1))
done > "$tr_file"
sid="cetest-$$"
budget_input=$(jq -n --arg sid "$sid" --arg tp "$tr_file" '{session_id:$sid, transcript_path:$tp}')
out=$(printf '%s' "$budget_input" | bash "$HOOKS/context-budget-warning.sh")
rm -f "$tr_file" "/tmp/context-budget-$sid" "/tmp/context-engineer-handoff-$sid"
assert_contains "budget: 65% usage fires YELLOW zone"  "$out" 'YELLOW ZONE'
assert_contains "budget: reports context percentage"  "$out" '65%'

# floor: under 15 turns, no warning regardless of usage
tr_file="$(mktemp)"
printf '{"type":"assistant","role":"assistant","message":{"usage":{"input_tokens":650000,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}}}\n' > "$tr_file"
sid="cetest-floor-$$"
budget_input=$(jq -n --arg sid "$sid" --arg tp "$tr_file" '{session_id:$sid, transcript_path:$tp}')
out=$(printf '%s' "$budget_input" | bash "$HOOKS/context-budget-warning.sh")
rm -f "$tr_file" "/tmp/context-budget-$sid"
assert_empty "budget: under 15-turn floor stays silent" "$out"

# an invalid CONTEXT_ENGINEER_BUDGET override must fall back, never crash the hook
tr_file="$(mktemp)"
i=0
while [ "$i" -lt 16 ]; do
  printf '{"type":"assistant","role":"assistant","message":{"usage":{"input_tokens":650000,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}}}\n'
  i=$((i + 1))
done > "$tr_file"
for badbudget in 0 abc ""; do
  sid="cetest-badbudget-$$"
  binput=$(jq -n --arg sid "$sid" --arg tp "$tr_file" '{session_id:$sid, transcript_path:$tp}')
  out=$(printf '%s' "$binput" | CONTEXT_ENGINEER_BUDGET="$badbudget" bash "$HOOKS/context-budget-warning.sh" 2>&1)
  rm -f "/tmp/context-budget-$sid" "/tmp/context-engineer-handoff-$sid"
  case "$out" in
    *"division by"*|*"unbound"*|*"syntax error"*) bad "budget: invalid BUDGET='$badbudget' is guarded" "errored: $out" ;;
    *"YELLOW ZONE"*) ok "budget: invalid BUDGET='$badbudget' falls back to default" ;;
    *) bad "budget: invalid BUDGET='$badbudget' falls back to default" "expected YELLOW, got: ${out:-<empty>}" ;;
  esac
done
rm -f "$tr_file"

# --- scripts/scorecard.sh (the script /context-engineer:diagnose locates and runs) ---
sc_out=$(bash "$ROOT/scripts/scorecard.sh" "$ROOT" 2>/dev/null)
assert_contains "scorecard: renders the health scorecard" "$sc_out" "Health Scorecard"
assert_contains "scorecard: prints a score line"          "$sc_out" "Score:"
assert_contains "scorecard: prints the token-savings line" "$sc_out" "Tokens saved"

echo "---------------------------"
echo "passed: $PASS   failed: $FAIL"
[ "$FAIL" -eq 0 ]
