#!/bin/bash
# Token-saving filter for test runner output (npm test, jest, pytest, vitest, etc.)
# Reduces verbose test output to failures + summary only.

source "$(dirname "${BASH_SOURCE[0]}")/filter-common.sh"

match_command() {
  case "$1" in
    *"npm test"*|*"npx jest"*|*"npx vitest"*|*"pytest"*|*"go test"*|*"cargo test"*|*"npm run test"*) return 0 ;;
    *) return 1 ;;
  esac
}

build_filtered() {
  local response="$1" filtered="" failures summary
  failures=$(echo "$response" | grep -E "FAIL|✕|✗|FAILED|Error:|error TS|AssertionError|Expected|Received|●" | head -30)
  summary=$(echo "$response" | grep -E "Tests:|Test Suites:|passed|failed|Ran [0-9]|[0-9]+ (passed|failed)|PASS|FAIL" | tail -5)

  [ -n "$failures" ] && filtered="$failures"
  [ -n "$summary" ] && filtered="${filtered:+$filtered
---
}$summary"
  printf '%s' "$filtered"
}

run_filter "Test"
