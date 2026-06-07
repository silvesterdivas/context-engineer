---
description: Run a context engineering health scorecard for this project
allowed-tools: Read, Glob, Grep, Bash
---

# Context Engineering Diagnosis

Run the visual health scorecard and provide actionable recommendations.

## Instructions

### Step 1: Run the scorecard script

The scorecard lives at `scripts/scorecard.sh` in the plugin. Locate the plugin root, then run that script against the user's current working directory. Replace `<project-root>` with the user's current working directory:

```bash
bash -c '
PROJECT_ROOT="${1:-.}"

# ── Find plugin root (search common locations) ──
# Works whether the plugin is installed, linked, or running from the marketplace cache.
PLUGIN_ROOT=""
CACHE_LATEST=$(ls -d "$HOME/.claude/plugins/cache/context-engineer-marketplace/context-engineer"/*/ 2>/dev/null | sort -rV | head -1)
for candidate in \
  "${CLAUDE_PLUGIN_ROOT:-}" \
  "$HOME/.claude/plugins/context-engineer" \
  "$HOME/.claude/plugins/context-engineer-marketplace/context-engineer" \
  "$CACHE_LATEST" \
  "$PROJECT_ROOT"; do
  if [[ -n "$candidate" && ( -f "$candidate/scripts/scorecard.sh" || -f "$candidate/hooks/scripts/filter-test-output.sh" ) ]]; then
    PLUGIN_ROOT="$candidate"; break
  fi
done

if [[ -z "$PLUGIN_ROOT" || ! -f "$PLUGIN_ROOT/scripts/scorecard.sh" ]]; then
  echo "Could not locate scripts/scorecard.sh in any known plugin path." >&2
  exit 2
fi

bash "$PLUGIN_ROOT/scripts/scorecard.sh" "$PROJECT_ROOT"
' -- <project-root>
```

### Step 2: MCP Server Hygiene (manual check)

The scorecard doesn't check MCP servers - that requires inspecting the system context. Check manually:
- Count the number of MCP servers active in this session (visible in the system prompt)
- Count the total MCP tools available
- **PASS:** All servers are relevant, total tools < 20
- **WARN:** 1-2 potentially unused servers
- **FAIL:** 3+ unused servers or > 20 total tools

Report MCP status as a line after the scorecard output:
```
MCP Hygiene: X servers, Y tools - [assessment]
```

### Step 3: Recommendations

If any checks show WARN or FAIL, list specific fix actions ordered by impact:
- CLAUDE.md missing → Run `/context-engineer:setup`
- Hooks missing → Reinstall the plugin
- Large files → Suggest splitting specific files
- Git hygiene → Suggest committing or stashing
- MCP bloat → Run `/context-engineer:audit-mcp`

If all checks pass, just say the project is fully configured - no further action needed.
