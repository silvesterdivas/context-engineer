# context-engineer

Context engineering best practices for Claude Code. Budget zones, degradation detection, token-saving hooks, model switching, and more.

**9 techniques** packaged as one installable plugin — no configuration needed.

## What It Does

| Technique | Type | Purpose |
|-----------|------|---------|
| Budget Zones | Skill | GREEN/YELLOW/ORANGE/RED context usage zones |
| Degradation Detection | Skill | Self-diagnosis when Claude starts forgetting |
| Code Intelligence | Skill (background) | Efficient tool selection for code navigation |
| Model Switching | Skill (background) | Task-to-model mapping (Haiku/Sonnet/Opus) |
| Thinking Control | Skill (background) | Calibrated reasoning depth per task type |
| Test Output Filter | Hook | ~80% token savings on test runs |
| Build Output Filter | Hook | ~90% token savings on builds |
| Lint Output Filter | Hook | ~70% token savings on lints |
| Fresh Context Pattern | Command | TASK.md + PROGRESS.md handoff files |

## Installation

```bash
# Add the marketplace
claude plugin marketplace add silvesterdivas/context-engineer

# Install the plugin
claude plugin install context-engineer@context-engineer-marketplace
```

## Quick Start

After installing, run the setup command to add context engineering rules to your project:

```
/context-engineer:setup
```

Then run a health check:

```
/context-engineer:diagnose
```

That's it. The background skills and hooks activate automatically.

## Commands Reference

### `/context-engineer:setup`
Adds context engineering rules (budget zones, fresh context pattern, tool efficiency guidelines) to your project's CLAUDE.md.

### `/context-engineer:fresh-context "Build auth feature"`
Creates TASK.md and PROGRESS.md with current progress so you can continue in a new conversation with full context. Use when your context is getting heavy or before a complex task.

### `/context-engineer:audit-mcp`
Lists all configured MCP servers, estimates their token overhead, and flags unused ones that are wasting context space.

### `/context-engineer:diagnose`
Runs a health scorecard checking: CLAUDE.md config, hooks, MCP hygiene, fresh context files, git state, and project structure. Produces a pass/warn/fail table with specific fix recommendations.

## Skills Reference

### Budget Zones (user-invocable)
Defines four context usage zones — GREEN (free), YELLOW (selective), ORANGE (conserve), RED (wrap up). Activates automatically when context fills, or invoke manually to check your current zone.

### Degradation Detection (user-invocable)
Four stages of context degradation with specific signs and corrective actions. Helps Claude recognize when it's starting to forget, hallucinate, or loop.

### Code Intelligence (background)
Guides efficient tool selection: when to Grep vs Read, how to navigate imports and type hierarchies, token cost comparisons for different navigation approaches.

### Model Switching (background)
Maps task types to optimal models. Haiku for searches, Sonnet for reviews, Opus for architecture. Includes cost ratios and delegation guidance.

### Thinking Control (background)
Calibrates reasoning depth: minimal for mechanical tasks, deep for security/architecture. Prevents over-thinking simple tasks and under-thinking complex ones.

## Agents Reference

### Investigator (Haiku)
Fast, cheap codebase search agent. Use via the Task tool for broad searches that would clutter your main context. Tools: Read, Grep, Glob.

### Reviewer (Sonnet)
Code review agent with fresh context. Reads code thoroughly and provides structured feedback (critical/warning/suggestion). Tools: Read, Grep, Glob, Bash (git only).

## Hooks Reference

Three PostToolUse hooks automatically filter verbose Bash output:

| Hook | Matches | Keeps | Savings |
|------|---------|-------|---------|
| `filter-test-output.sh` | jest, vitest, pytest, go test, cargo test, etc. | FAIL/ERROR lines + summary | ~80% |
| `filter-build-output.sh` | tsc, gradle, xcodebuild, cargo build, etc. | Error/warning lines | ~90% |
| `filter-lint-output.sh` | eslint, pylint, clippy, biome, etc. | Problem lines only | ~70% |

Hooks only activate on output > 40 lines. Short output passes through unfiltered.

**Dependency:** `jq` (pre-installed on most dev machines; `brew install jq` / `apt install jq` if missing).

## Customization

### Disable a specific hook
Remove the corresponding entry from `hooks/hooks.json`.

### Adjust the 40-line threshold
Edit the `LINE_COUNT` check in any script under `hooks/scripts/`.

### Add project-specific budget zone rules
Run `/context-engineer:setup` then edit the generated section in your CLAUDE.md.

### Use agents with different models
Copy the agent files to your project's `.claude/agents/` directory and modify the `model` frontmatter.

## Credits

Built by [ShipPrompt](https://silvesterdivas.github.io/shipprompt/). Based on the 9 context engineering techniques from the ShipPrompt prompt generator.

## License

MIT
