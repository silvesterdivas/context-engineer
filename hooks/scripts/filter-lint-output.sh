#!/bin/bash
# Token-saving filter for linter output (eslint, prettier, stylelint, etc.)
# Reduces verbose lint output to error count + top issues only.

source "$(dirname "${BASH_SOURCE[0]}")/filter-common.sh"

match_command() {
  case "$1" in
    *"npm run lint"*|*"npx eslint"*|*"npx prettier"*|*"stylelint"*|*"pylint"*|*"flake8"*|*"clippy"*) return 0 ;;
    *) return 1 ;;
  esac
}

build_filtered() {
  local response="$1" filtered="" issues summary
  issues=$(echo "$response" | grep -E "error|warning" | grep -E "^\s*/|^\s*[0-9]+:" | head -15)
  summary=$(echo "$response" | grep -E "✖|problems?|errors?.*warnings?|[0-9]+ error|All files pass" | tail -3)

  [ -n "$issues" ] && filtered="Top issues:
$issues"
  [ -n "$summary" ] && filtered="${filtered:+$filtered
---
}$summary"
  printf '%s' "$filtered"
}

run_filter "Lint"
