---
description: Show context-engineer status (budget zone, session cost) and list everything the plugin offers
allowed-tools: Bash, Read
---

# Context Engineer Status

Give the user a quick overview: current context budget status, then the commands, skills, and hooks the plugin provides. This is the discoverability entrypoint.

## Step 1: Quick status

Locate and run the scorecard script (same discovery as `/context-engineer:diagnose`), showing only its Score and Session lines so the user sees their current budget zone, context size, cache-hit rate, and per-model cost. Replace `<project-root>` with the user's current working directory:

```bash
bash -c '
PROJECT_ROOT="${1:-.}"
PLUGIN_ROOT=""
CACHE_LATEST=$(ls -d "$HOME/.claude/plugins/cache/context-engineer-marketplace/context-engineer"/*/ 2>/dev/null | sort -rV | head -1)
for candidate in "${CLAUDE_PLUGIN_ROOT:-}" "$HOME/.claude/plugins/context-engineer" "$CACHE_LATEST" "$PROJECT_ROOT"; do
  if [[ -n "$candidate" && -f "$candidate/scripts/scorecard.sh" ]]; then PLUGIN_ROOT="$candidate"; break; fi
done
if [[ -n "$PLUGIN_ROOT" ]]; then
  bash "$PLUGIN_ROOT/scripts/scorecard.sh" "$PROJECT_ROOT" 2>/dev/null | grep -E "Score:|Session:"
else
  echo "Run /context-engineer:setup first."
fi
' -- <project-root>
```

## Step 2: Present the menu

Show the user what is available:

**Commands**
- `/context-engineer:setup` - add the Context Engineering Rules to this project's CLAUDE.md
- `/context-engineer:diagnose` - full health scorecard with fix recommendations
- `/context-engineer:audit-mcp` - list MCP servers and flag token-heavy ones to trim
- `/context-engineer:fresh-context "<task>"` - write TASK.md + PROGRESS.md for a clean handoff
- `/context-engineer:status` - this overview

**Background skills** (activate automatically; describe your situation to trigger one on demand)
- Budget Zones, Degradation Detection, Code Intelligence, Model Switching, Prompt Caching, Thinking Control, Auto-Pilot Handoff

**Token-saving hooks** filter verbose test, build, and lint output automatically. Set `CONTEXT_ENGINEER_FILTER_OFF=1` to see raw output, or `CONTEXT_ENGINEER_FILTER_MIN_LINES` to change the threshold.

Close by suggesting `/context-engineer:diagnose` for a full health check if anything in the status line looks off.
