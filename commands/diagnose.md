---
description: Run a context engineering health scorecard for this project
allowed-tools: Read, Glob, Grep, Bash
---

# Context Engineering Diagnosis

Run the visual health scorecard and provide actionable recommendations.

## Instructions

### Step 1: Find and run the scorecard script

Use the Glob tool to find the script:
```
Glob: **/context-engineer/scripts/scorecard.sh
```

Then run it with the current project root:
```
bash <script-path> <project-root>
```

The script outputs a formatted terminal scorecard with colored pass/warn/fail indicators, token savings bars, and a score summary.

### Step 2: MCP Server Hygiene (manual check)

The script doesn't check MCP servers — that requires inspecting the system context. Check yourself:
- Count the number of MCP servers active in this session (visible in the system prompt)
- Count the total MCP tools available
- **PASS:** All servers are relevant, total tools < 20
- **WARN:** 1-2 potentially unused servers
- **FAIL:** 3+ unused servers or > 20 total tools

Report MCP status as a line after the scorecard output:
```
MCP Hygiene: X servers, Y tools — [assessment]
```

### Step 3: Recommendations

If any checks show WARN or FAIL, list specific fix actions ordered by impact:
- CLAUDE.md missing → Run `/context-engineer:setup`
- Hooks missing → Reinstall the plugin
- Large files → Suggest splitting specific files
- Git hygiene → Suggest committing or stashing
- MCP bloat → Run `/context-engineer:audit-mcp`

If all checks pass, just say the project is fully configured — no further action needed.
