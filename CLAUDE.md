# context-engineer

Claude Code plugin packaging context engineering best practices: budget zones, degradation detection, token-saving hooks, model switching, prompt caching, and fresh-context handoffs.

## Stack
- Plugin format: Claude Code marketplace plugin (`.claude-plugin/plugin.json`)
- Skills: markdown `SKILL.md` files under `skills/`
- Commands: markdown under `commands/`
- Hooks: bash under `hooks/scripts/` (PostToolUse output filters)
- Site: static `index.html` / `guide.html`, published via `gh-pages`

## Structure
- `skills/`: budget-zones, degradation-signs, code-intelligence, model-switching, prompt-caching, thinking-control, auto-handoff
- `commands/`: setup, diagnose, audit-mcp, fresh-context
- `hooks/scripts/`: filter-test-output, filter-build-output, filter-lint-output, context-budget-warning
- `scripts/scorecard.sh`: the health scorecard script that `/context-engineer:diagnose` locates and runs (single source of truth)

## Conventions
- Keep skill files lean; progressive disclosure over walls of text
- No em dashes or double dashes in any text (workspace rule)
- Bump `version` in `.claude-plugin/plugin.json` and the README changelog on release

## Context Engineering Rules

### Budget Zones
- **GREEN (< 60% context):** Work normally. Read full files, explore freely.
- **YELLOW (60-75%):** Be selective. Summarize before reading. Prefer Grep over Read.
- **ORANGE (75-85%):** Conserve aggressively. Use targeted Grep. Avoid reading entire files.
- **RED (> 85%):** Wrap up current task. Create TASK.md + PROGRESS.md for continuation.

### Fresh Context Pattern
When context gets heavy or a task is complex:
1. Create `TASK.md` with goal, constraints, and current state
2. Create `PROGRESS.md` with completed steps and next actions
3. Start a new conversation referencing these files

### Tool Efficiency
- Prefer `Grep` with specific patterns over `Read` for large files
- Use `Glob` to find files instead of recursive `Read`
- Use the investigator agent (Haiku) for broad codebase searches
- Use the reviewer agent (Sonnet) for code reviews with fresh context

### Model Switching
- **Haiku:** File search, grep, quick lookups, simple edits
- **Sonnet:** Code review, refactoring, multi-file changes
- **Opus:** Architecture decisions, complex debugging, security review
- Opus is ~5x Haiku at current pricing (not 25x); pick Haiku/Sonnet for speed and context conservation, not just cost.

### Prompt Caching (biggest cost lever)
- Caching is a prefix match: changing early context (CLAUDE.md, files read at the start) re-reads everything after it at full price.
- Keep CLAUDE.md and early context stable; batch edits to the same file; avoid re-reading files you touched early.
- Cache reads cost ~0.1x; a warm session is far cheaper than any model downgrade.

### Output Filtering
Token-saving hooks are active for test, build, and lint output.
Only failures, errors, and summaries are retained; raw output is filtered.
