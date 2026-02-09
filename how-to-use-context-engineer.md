# How to Use Context Engineer: The Complete Guide

Whether you're starting a brand-new project or adding context engineering to a codebase you've been working on for months, this guide walks you through everything — from installation to daily workflow.

---

## What Is Context Engineer?

Context Engineer is an open-source plugin for Claude Code that ships 9 techniques to stop your AI coding assistant from wasting tokens on noise. It filters verbose output, adapts behavior as your context window fills up, catches degradation before it ruins your session, and routes tasks to the right model.

One install. Zero configuration. It just works.

---

## Prerequisites

Before you start, make sure you have:

- **Claude Code** installed and working
- **jq** (JSON processor) — pre-installed on most dev machines
  - Mac: `brew install jq`
  - Linux: `apt install jq`

That's it.

---

## Installation (Same for New and Existing Projects)

Installation is global — you do this once, and it works across all your projects.

**Step 1: Add the marketplace**

```bash
claude plugin marketplace add silvesterdivas/context-engineer
```

**Step 2: Install the plugin**

```bash
claude plugin install context-engineer@context-engineer-marketplace
```

Done. The plugin is now installed at `~/.claude/plugins/marketplaces/context-engineer-marketplace/`.

The three token-saving hooks (test, build, lint output filters) are already active. Every time Claude Code runs a test suite, build command, or linter, the output gets filtered automatically — no setup needed.

---

## Part 1: Using Context Engineer for New Projects

You're starting fresh. No CLAUDE.md, no existing configuration, clean slate.

### Step 1: Create Your Project

```bash
mkdir my-new-project
cd my-new-project
git init
```

### Step 2: Run the Setup Command

Open Claude Code in your project directory and run:

```
/context-engineer:setup
```

This creates a `CLAUDE.md` file in your project root with the full Context Engineering Rules section:

- **Budget Zones** — GREEN/YELLOW/ORANGE/RED behavior thresholds
- **Fresh Context Pattern** — instructions for creating handoff files
- **Tool Efficiency** — when to use Grep vs Read vs Glob
- **Model Switching** — which model to use for which task type
- **Output Filtering** — confirmation that token-saving hooks are active

Your `CLAUDE.md` is the brain of your project's AI configuration. Claude Code reads it at the start of every session.

### Step 3: Run the Health Check

Verify everything is wired up correctly:

```
/context-engineer:diagnose
```

This runs a health scorecard that checks 6 areas:

| Area | What It Checks |
|------|---------------|
| CLAUDE.md configuration | Rules section exists and is complete |
| Token-saving hooks | All 3 hooks installed and functional |
| MCP server hygiene | No unnecessary servers wasting tokens |
| Fresh context files | TASK.md/PROGRESS.md templates ready |
| Git hygiene | Repository is clean and well-structured |
| Project structure | Files organized for efficient AI navigation |

You'll get a Pass/Warn/Fail table with specific recommendations for anything that needs attention.

### Step 4: Start Working

That's it. Start coding normally. Here's what happens behind the scenes:

**When you run tests:**
```bash
npm test
```
Before context-engineer: Claude sees all 200 lines of test output (196 passed, 4 failed).
After context-engineer: Claude sees only the 4 failures + the summary. **~80% token savings.**

**When you run a build:**
```bash
npm run build
```
Before: Claude reads 500 lines of webpack output.
After: Claude sees only errors and warnings. **~90% token savings.**

**When you run a linter:**
```bash
npx eslint src/
```
Before: Claude processes 150 lines of lint output.
After: Claude sees only the problems. **~70% token savings.**

All of this happens automatically. The hooks only activate when output exceeds 40 lines, so short outputs pass through unchanged.

### New Project Workflow Tips

1. **Let Claude Code explore freely at first.** In a new project, you're in GREEN zone (context usage < 60%). Take advantage of this — read full files, explore the codebase, make architecture decisions.

2. **Use Opus for early decisions.** The model switching skill will guide Claude to use Opus for architecture decisions at the start of a project. This is where it matters most.

3. **Create your TASK.md early for complex features.** If you know a feature will take multiple sessions, run `/context-engineer:fresh-context "building the authentication system"` before you start. This creates TASK.md and PROGRESS.md so you can hand off cleanly between sessions.

---

## Part 2: Using Context Engineer for Existing Projects

You have a codebase. Maybe it already has a CLAUDE.md. Maybe it doesn't. Either way, context-engineer fits right in.

### Step 1: Navigate to Your Project

```bash
cd /path/to/your/existing-project
```

### Step 2: Run the Setup Command

Open Claude Code and run:

```
/context-engineer:setup
```

**If you don't have a CLAUDE.md:** One gets created with the complete Context Engineering Rules section.

**If you already have a CLAUDE.md:** The setup command reads your existing file and appends the Context Engineering Rules section. Your existing content — project-specific instructions, coding standards, architecture notes — stays untouched.

**If you already have the rules section:** Setup detects it and skips. No duplication.

### Step 3: Audit Your MCP Servers

Existing projects often accumulate MCP servers over time. Each one adds token overhead to every conversation. Run:

```
/context-engineer:audit-mcp
```

This checks your MCP configuration across:
- `.claude/settings.json` (project-level)
- `~/.claude/settings.json` (global)
- `.mcp.json` (legacy)

You'll get a table showing each server's name, tool count, estimated token overhead, and a recommendation (keep, review, or remove).

### Step 4: Run the Health Check

```
/context-engineer:diagnose
```

For existing projects, pay special attention to:
- **Token-saving hooks** — make sure they're installed and matching your build tools
- **CLAUDE.md configuration** — verify the rules section integrated cleanly with your existing content
- **Project structure** — the scorecard may flag opportunities to reorganize for better AI navigation

### Step 5: Start Working

Everything is now active. Your existing workflow doesn't change — you just get dramatically better sessions.

### Existing Project Workflow Tips

1. **Your first session will feel different.** If you're used to sessions dying at 45 minutes, you'll notice they last much longer now. The hooks are silently saving thousands of tokens per test/build/lint cycle.

2. **Watch the budget zones.** On large codebases, you'll hit YELLOW and ORANGE faster because there's more code to read. The budget zone skill will automatically guide Claude to be more selective — using Grep instead of reading full files, summarizing before diving in.

3. **Use fresh context for big refactors.** If you're refactoring a major system, run `/context-engineer:fresh-context "refactoring the payment processing module"` before you start. When the context gets heavy, you'll have TASK.md and PROGRESS.md ready for a clean handoff to a new session.

4. **Don't fight the RED zone.** When context usage exceeds 85%, the plugin will guide Claude to wrap up and suggest starting a new conversation. Trust this. A fresh session with handoff files will outperform a degraded session every time.

---

## The 9 Techniques: What Each One Does

### Hooks (Automatic — Always Running)

| Hook | Triggers On | What It Filters | Savings |
|------|------------|----------------|---------|
| **Test Output Filter** | `npm test`, `jest`, `vitest`, `pytest`, `go test`, `cargo test` | Keeps failures + summary, discards passed tests | ~80% |
| **Build Output Filter** | `npm run build`, `tsc`, `webpack`, `vite`, `cargo build`, `gradle`, `xcodebuild` | Keeps errors + warnings only | ~90% |
| **Lint Output Filter** | `eslint`, `prettier`, `stylelint`, `pylint`, `flake8`, `clippy` | Keeps problem lines only | ~70% |

Hooks only activate when output exceeds 40 lines. Short outputs pass through unchanged.

### Skills (Background — Activate Contextually)

| Skill | What It Does | When It Activates |
|-------|-------------|-------------------|
| **Budget Zones** | Adapts Claude's behavior based on context usage (GREEN/YELLOW/ORANGE/RED) | Continuously monitors context window |
| **Degradation Detection** | Catches when Claude starts forgetting, hallucinating, or looping | When quality signals drop |
| **Code Intelligence** | Guides efficient tool selection (Grep vs Read vs Glob) | When Claude navigates the codebase |
| **Model Switching** | Routes tasks to the right model (Haiku/Sonnet/Opus) | When Claude spawns subagents |
| **Thinking Control** | Calibrates reasoning depth based on task complexity | Every task |

### Commands (Manual — You Invoke When Needed)

| Command | What It Does | When to Use |
|---------|-------------|-------------|
| `/context-engineer:setup` | Adds context engineering rules to CLAUDE.md | Once per project |
| `/context-engineer:fresh-context` | Creates TASK.md + PROGRESS.md for session handoff | Before complex tasks or when context is heavy |
| `/context-engineer:audit-mcp` | Lists MCP servers and flags token waste | When sessions feel slow or bloated |
| `/context-engineer:diagnose` | Runs a health scorecard on your setup | After installation or when something feels off |

---

## Understanding Budget Zones

This is the technique that changes how your sessions feel day-to-day.

### GREEN Zone (< 60% context used)

You're in the clear. Claude works at full capacity:
- Reads entire files freely
- Explores the codebase without restriction
- Uses the most capable model for complex decisions
- No constraints on tool usage

**What you should do:** Take advantage of this space for architecture decisions, exploration, and complex reasoning.

### YELLOW Zone (60-75% context used)

Getting warm. Claude starts being selective:
- Prefers Grep over Read for searching
- Summarizes content before processing
- Batches related operations together
- Delegates simple tasks to Haiku subagents

**What you should do:** Focus on your primary task. Avoid tangential exploration.

### ORANGE Zone (75-85% context used)

Conservation mode. Claude gets aggressive about saving tokens:
- Uses line ranges instead of full file reads
- No exploratory browsing
- Targeted Grep searches only
- Delegates everything possible to subagents

**What you should do:** Wrap up your current task. Consider whether you need a fresh context handoff.

### RED Zone (> 85% context used)

Time to go. Claude focuses on:
- Finishing the immediate task
- Creating TASK.md + PROGRESS.md for continuation
- Suggesting a new conversation

**What you should do:** Let Claude create the handoff files. Start a new session. The new session with fresh context will dramatically outperform continuing in a degraded one.

---

## The Fresh Context Pattern

This is how complex tasks survive across multiple sessions.

### When to Use It

- A feature will clearly take more than one session
- You're approaching ORANGE/RED zone and have more work to do
- You want to hand off work to a different developer (or yourself tomorrow)

### How It Works

Run the command with a description of your task:

```
/context-engineer:fresh-context "implementing user authentication with JWT"
```

This creates two files in your project root:

**TASK.md** — The goal:
- What you're building
- Constraints and requirements
- Key files involved
- Decisions already made
- Current context and state

**PROGRESS.md** — Where you are:
- Steps completed
- Current state of the work
- Next steps to take
- Notes and blockers

### Starting a New Session

Open a new Claude Code conversation in the same project directory. Claude will automatically read CLAUDE.md (which tells it about context engineering) and you can point it to:

```
Read TASK.md and PROGRESS.md and continue where the last session left off.
```

The new session starts with full context about the task, none of the token baggage from the previous session, and clear next steps.

---

## Model Switching: The Right Tool for the Job

Context engineer guides Claude to use subagents efficiently:

| Task Type | Model | Why |
|-----------|-------|-----|
| File search, grep, quick lookups | **Haiku** | Fast, cheap, perfect for mechanical tasks. 1x cost. |
| Code review, refactoring, multi-file changes | **Sonnet** | Balanced capability and cost. 5x cost. |
| Architecture decisions, complex debugging, security review | **Opus** | Maximum reasoning power for decisions that matter. 25x cost. |

You don't configure this manually. The model switching skill guides Claude's decisions about when to spawn subagents and which model to use for each task type.

---

## Degradation Detection: Your Safety Net

This skill monitors for signs that Claude is losing coherence:

**Stage 1 (~60% context):** Forgetting details, asking for re-confirmation of things discussed earlier.

**Stage 2 (~75% context):** Contradicting earlier decisions, missing imports, inconsistent naming.

**Stage 3 (~85% context):** Hallucinating APIs that don't exist, looping on the same fix attempt.

**Stage 4 (~90%+ context):** Incoherent reasoning, nonsensical code generation.

When degradation is detected, the skill flags it in real time. You'll see a clear signal that it's time to wrap up and hand off to a fresh session.

---

## Daily Workflow Cheat Sheet

### Starting a Session

1. Open Claude Code in your project directory
2. Claude reads CLAUDE.md automatically — budget zones, model switching, and tool efficiency rules are loaded
3. Hooks are already active — no action needed
4. If continuing previous work: "Read TASK.md and PROGRESS.md and pick up where we left off"

### During a Session

- **Tests/builds/linting run automatically filtered** — you'll notice shorter outputs
- **Budget zones adapt silently** — Claude gets more selective as context fills
- **Degradation detection watches in the background** — you'll get flagged if quality drops
- **Model switching guides subagent usage** — cheap tasks go to Haiku, complex ones stay on Opus

### Ending a Session

- If the task is done: commit your code, done
- If the task continues: run `/context-engineer:fresh-context "description of remaining work"`
- If context hit RED: Claude will suggest creating handoff files automatically

### Periodic Maintenance

- Run `/context-engineer:diagnose` if sessions feel slow or something seems off
- Run `/context-engineer:audit-mcp` if you've added new MCP servers recently
- Update your CLAUDE.md if project architecture changes significantly

---

## Troubleshooting

### "Hooks don't seem to be filtering output"

Hooks only activate on output exceeding 40 lines. Run a test suite with enough tests to generate verbose output and check if the filtered version appears.

### "I already have a CLAUDE.md and setup added duplicate content"

Run `/context-engineer:diagnose` to check. The setup command checks for an existing Context Engineering Rules section before adding one. If duplication occurred, simply remove the duplicate section from CLAUDE.md.

### "Context still fills up quickly on a large codebase"

This is expected for large codebases — there's simply more code to process. The budget zones and model switching are working to extend your session, but you may need to use the fresh context pattern more frequently. Focus sessions on specific subsystems rather than the entire codebase.

### "I want to customize which commands trigger the hooks"

Edit the hook scripts directly at:
```
~/.claude/plugins/marketplaces/context-engineer-marketplace/hooks/scripts/
```

Each script has a pattern matcher at the top that determines which commands trigger it. Add or remove patterns as needed.

### "I want to change the 40-line threshold"

Edit the `LINE_COUNT` check in any hook script under `hooks/scripts/`. Lower the number for more aggressive filtering, raise it for less.

---

## Quick Reference

| What You Want | What to Run |
|--------------|-------------|
| Install the plugin | `claude plugin marketplace add silvesterdivas/context-engineer` then `claude plugin install context-engineer@context-engineer-marketplace` |
| Set up a project | `/context-engineer:setup` |
| Check your setup | `/context-engineer:diagnose` |
| Hand off to a new session | `/context-engineer:fresh-context "task description"` |
| Audit MCP token waste | `/context-engineer:audit-mcp` |

---

## Links

- **Landing page:** [silvesterdivas.github.io/context-engineer](https://silvesterdivas.github.io/context-engineer/)
- **GitHub:** [github.com/silvesterdivas/context-engineer](https://github.com/silvesterdivas/context-engineer)
- **License:** MIT — free and open source
