#!/bin/bash
# Shared scaffold for the token-saving output filters (build, lint, test).
#
# Each filter sources this file, defines two functions, then calls run_filter:
#   match_command <command>    return 0 to filter this command, 1 to skip it
#   build_filtered <response>  echo the filtered body (empty output emits nothing)
#   run_filter "<Label>"
#
# Minimum output length worth filtering. Override with CONTEXT_ENGINEER_FILTER_MIN_LINES.
FILTER_MIN_LINES="${CONTEXT_ENGINEER_FILTER_MIN_LINES:-30}"

run_filter() {
  local label="$1"

  # Global off switch: skip filtering so raw tool output passes through.
  case "${CONTEXT_ENGINEER_FILTER_OFF:-}" in 1|true|yes|on) exit 0 ;; esac

  # Bail if jq is not available
  command -v jq >/dev/null 2>&1 || exit 0

  local input command response line_count filtered
  input=$(cat)
  command=$(echo "$input" | jq -r '.tool_input.command // ""' 2>/dev/null) || exit 0
  # tool_response is a string today, but tolerate an object form defensively
  # (extract stdout/content/stderr) so the filters never scan raw JSON.
  response=$(echo "$input" | jq -r 'if (.tool_response|type)=="object" then (.tool_response.stdout // .tool_response.content // .tool_response.stderr // (.tool_response|tojson)) else (.tool_response // "") end' 2>/dev/null) || exit 0

  # Only filter matching commands
  match_command "$command" || exit 0

  # Skip short output
  line_count=$(echo "$response" | wc -l | tr -d ' ')
  if [ "$line_count" -lt "$FILTER_MIN_LINES" ]; then
    exit 0
  fi

  filtered=$(build_filtered "$response")

  if [ -n "$filtered" ]; then
    jq -n --arg filtered "$filtered" --arg lines "$line_count" --arg label "$label" '{
      suppressOutput: true,
      message: ("[token-saving] " + $label + " output filtered: " + $lines + " lines → summary\n" + $filtered + "\n(set CONTEXT_ENGINEER_FILTER_OFF=1 for raw output)")
    }'
  fi
}
