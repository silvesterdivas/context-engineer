---
name: Auto-Pilot Handoff
description: Always active. After completing atomic work units, checks for context budget exhaustion and guides handoff file creation.
version: 1.1.0
user-invocable: false
---

# Auto-Pilot Handoff

This skill activates automatically when the context budget warning hook announces RED zone via a `[context-budget] RED ZONE` systemMessage. You do not invoke it — it governs your behavior after the hook fires.

## When Handoff is Triggered

After completing any atomic unit of work (a file edit, a commit, a test run, a search), if the budget warning hook has announced **RED zone** via systemMessage:

1. **Stop starting new work.** Finish only the immediately active operation.
2. **Do not read new files** or begin exploratory searches.
3. **Proceed directly** to generating the handoff files below.

## Generate Enhanced TASK.md

Create or append to `TASK.md` in the project root using this template:

```markdown
# Task: [Brief title]

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

## Generate Enhanced PROGRESS.md

Create or append to `PROGRESS.md` in the project root using this template:

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

## Handle Existing Files

If `TASK.md` or `PROGRESS.md` already exist in the project root:

- **Do not overwrite.** Append a new session section.
- For TASK.md: Add any new decisions, failed approaches, or constraint updates under the existing headings, or add a `## Session Update — [date]` section.
- For PROGRESS.md: Move newly completed items to the Completed list, update Current State, revise Next Steps, and add an entry to the Session Log.

## Notify the User

After generating the files, inform the user clearly:

> **Context budget exhausted — handoff files saved.**
>
> I've created/updated `TASK.md` and `PROGRESS.md` with the current state of this task.
>
> To continue, start a new conversation with:
> **"Read TASK.md and PROGRESS.md, then continue from where we left off."**

## Advisory, Not Mandatory

If the user explicitly says to continue working despite the RED zone warning:

- Comply with their request.
- Warn once that context degradation may cause hallucinations, repeated work, or forgotten context.
- Do not warn again after that — respect their decision.
