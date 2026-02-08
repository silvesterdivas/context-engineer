---
description: Run a context engineering health scorecard for this project
allowed-tools: Read, Glob, Grep, Bash
---

# Context Engineering Diagnosis

Run a comprehensive health check on this project's context engineering setup and produce a scorecard.

## Instructions

Check each of the following and assign a status: PASS, WARN, or FAIL.

### 1. CLAUDE.md Configuration
- **PASS:** CLAUDE.md exists and contains context engineering rules (budget zones, fresh context pattern)
- **WARN:** CLAUDE.md exists but lacks context engineering rules
- **FAIL:** No CLAUDE.md found
- *Fix:* Run `/context-engineer:setup`

### 2. Token-Saving Hooks
- **PASS:** `hooks/` directory exists with filter scripts (test, build, lint)
- **WARN:** Some hooks exist but not all three
- **FAIL:** No token-saving hooks configured
- *Fix:* Install the context-engineer plugin hooks

### 3. MCP Server Hygiene
- **PASS:** All configured MCP servers are relevant to this project
- **WARN:** 1-2 potentially unused MCP servers
- **FAIL:** 3+ unused MCP servers or >20 total MCP tools
- *Fix:* Run `/context-engineer:audit-mcp`

### 4. Fresh Context Files
- **PASS:** TASK.md and/or PROGRESS.md exist (active fresh context pattern)
- **WARN:** Files exist but are stale (>7 days old)
- **FAIL:** No fresh context files (not necessarily bad — only needed for complex tasks)
- *Note:* This is informational, not a hard requirement

### 5. Git Hygiene
- **PASS:** Clean working tree or small diff (<500 lines)
- **WARN:** Large uncommitted diff (500-2000 lines)
- **FAIL:** Very large uncommitted diff (>2000 lines) — risk of context pressure from git operations
- *Fix:* Commit or stash work in progress

### 6. Project Structure
- **PASS:** Clear entry points, reasonable file sizes (most <500 lines)
- **WARN:** Some large files (>500 lines) that may strain context
- **FAIL:** Many files >1000 lines — refactoring recommended for context efficiency
- *Fix:* Consider splitting large files

## Output Format

```
# Context Engineering Scorecard

| Check                  | Status | Details                          |
|------------------------|--------|----------------------------------|
| CLAUDE.md              | ✅/⚠️/❌ | ...                              |
| Token-Saving Hooks     | ✅/⚠️/❌ | ...                              |
| MCP Server Hygiene     | ✅/⚠️/❌ | ...                              |
| Fresh Context Files    | ✅/⚠️/❌ | ...                              |
| Git Hygiene            | ✅/⚠️/❌ | ...                              |
| Project Structure      | ✅/⚠️/❌ | ...                              |

Score: X/6 passing

## Recommendations
[List specific actions to improve, ordered by impact]
```
