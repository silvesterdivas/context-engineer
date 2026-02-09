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
   - Run `git branch --show-current` and `git status` to capture the current branch and working state
   - Read any recently modified files (check `git diff --name-only` if in a git repo)
   - Identify the goal, constraints, and tech stack from the conversation so far
   - Note any decisions already made, including *why* they were made and what alternatives were rejected
   - Document any approaches that were tried and failed, with root causes
   - Check if `TASK.md` or `PROGRESS.md` already exist — if so, **append** a new session section rather than overwriting

2. **Create TASK.md** in the project root with this structure:

```markdown
# Task: [Brief title from $ARGUMENTS]

## Goal
[Clear description of what needs to be accomplished]

## Context
- **Branch:** [current git branch]
- **Date:** [today's date]
- **Previous sessions:** [list any prior TASK.md sections or session IDs if known]

## Constraints
- [Tech stack, patterns, style requirements]
- [Any limitations or requirements discovered]

## Key Files
- [List the most relevant files for this task, with brief purpose notes]

## Key Decisions Made
- **[Decision]:** [What was decided]
  - *Reasoning:* [Why this approach was chosen]
  - *Rejected alternatives:* [What was considered and discarded, and why]

## Approaches Tried & Failed
- **[What was attempted]:**
  - *Why it failed:* [Root cause]
  - *Lesson:* [What to avoid or do differently next time]
```

3. **Create PROGRESS.md** in the project root with this structure:

```markdown
# Progress: [Same title as TASK.md]

## Completed
- [x] [Step done — be specific about what changed and where]
- [x] [Another completed step]

## Current State
[What's working, what's broken, what's uncommitted. Be precise — the next session starts cold.]

## Next Steps
1. [ ] [Immediate next action — most important first]
2. [ ] [Following action]
3. [ ] [Further actions in priority order]

## Blockers / Open Questions
- [Anything unresolved that the next session needs to decide]
- [External dependencies, unclear requirements, etc.]

## Session Log
- **[Date/Session ID]:** [Brief summary of what was accomplished and where things stand]
```

4. **If TASK.md or PROGRESS.md already exist**, append a new session section instead of overwriting:
   - For TASK.md: add new decisions, failed approaches, or constraint updates under existing headings, or add a `## Session Update — [date]` section
   - For PROGRESS.md: move newly completed items to the Completed list, update Current State, revise Next Steps, and add an entry to the Session Log

5. **Report** the files created/updated and suggest the user start a new conversation with:
   > Read TASK.md and PROGRESS.md, then continue from where we left off.
