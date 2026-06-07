#!/bin/bash
# Token-saving filter for build output (expo, tsc, webpack, vite, etc.)
# Reduces verbose build output to errors + summary only.

source "$(dirname "${BASH_SOURCE[0]}")/filter-common.sh"

match_command() {
  case "$1" in
    *"npm run build"*|*"npx expo"*|*"npx tsc"*|*"webpack"*|*"vite build"*|*"cargo build"*|*"go build"*|*"npm run compile"*) return 0 ;;
    *) return 1 ;;
  esac
}

build_filtered() {
  local response="$1" filtered="" errors warnings summary
  errors=$(echo "$response" | grep -E "error TS|ERROR|Error:|error:|fatal:|FATAL" | head -20)
  warnings=$(echo "$response" | grep -E "warning TS|WARNING|warn:" | head -10)
  summary=$(echo "$response" | grep -E "compiled|bundled|Built|Compiled|Successfully|Done in|finished|✓|✔" | tail -5)

  [ -n "$errors" ] && filtered="Errors:
$errors"
  [ -n "$warnings" ] && filtered="${filtered:+$filtered
---
}Warnings:
$warnings"
  [ -n "$summary" ] && filtered="${filtered:+$filtered
---
}$summary"
  printf '%s' "$filtered"
}

run_filter "Build"
