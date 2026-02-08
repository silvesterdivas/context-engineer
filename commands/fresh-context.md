---
description: Create TASK.md + PROGRESS.md for a fresh context handoff (Ralph Loop pattern)
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git:*)
argument-hint: "<task description>"
---

# Fresh Context Handoff

Create TASK.md and PROGRESS.md files so the current task can be continued in a new conversation with full context.

## Instructions

**Task description:** $ARGUMENTS

1. **Gather context** about the current task:
   - Read any recently modified files (check `git diff --name-only` if in a git repo)
   - Identify the goal, constraints, and tech stack from the conversation so far
   - Note any decisions already made

2. **Create TASK.md** in the project root with this structure:

```markdown
# Task: [Brief title from $ARGUMENTS]

## Goal
[Clear description of what needs to be accomplished]

## Constraints
- [Tech stack, patterns, style requirements]
- [Any limitations or requirements discovered]

## Key Files
- [List the most relevant files for this task]

## Decisions Made
- [Any architectural or implementation decisions already settled]

## Context
- Started: [today's date]
- Status: In progress
```

3. **Create PROGRESS.md** in the project root with this structure:

```markdown
# Progress: [Same title as TASK.md]

## Completed
- [x] [Steps already done in this conversation]

## Current State
[What's working, what's broken, where things stand]

## Next Steps
- [ ] [Immediate next action]
- [ ] [Following actions in priority order]

## Notes
- [Gotchas, edge cases, or things to watch out for]
```

4. **Report** the files created and suggest the user start a new conversation with:
   > Read TASK.md and PROGRESS.md, then continue from where we left off.
