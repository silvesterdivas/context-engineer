---
name: Budget Zones
description: This skill should be used when the context window is filling up, when deciding whether to read a file or use grep, when planning work scope, when the user asks about "budget zones", "context budget", or "token management", or when you notice the conversation is getting long.
version: 1.1.2
user-invocable: true
---

# Context Budget Zones

Apply these budget zones to manage context consumption throughout the conversation.

## Zone Definitions

### GREEN Zone (< 60% context used)
- **Behavior:** Work normally. Full creative freedom.
- Read entire files when helpful
- Explore the codebase broadly
- Include full code blocks in responses
- Use multiple tool calls freely
- Plan ambitious multi-step operations

### YELLOW Zone (60-75% context used)
- **Behavior:** Be selective. Start economizing.
- Prefer `Grep` with targeted patterns over `Read` for large files
- Summarize file contents instead of quoting them fully
- Batch related operations together
- Avoid re-reading files already in context
- Delegate exploration to the investigator agent (Haiku) when possible

### ORANGE Zone (75-85% context used)
- **Behavior:** Conserve aggressively. Focus on completing the current task.
- Only read specific line ranges, never full files
- Use `Grep` exclusively for finding information
- Give concise responses — skip explanations unless asked
- Do NOT start new exploratory tasks
- Delegate any research to subagents
- Consider creating fresh context files (TASK.md + PROGRESS.md)

### RED Zone (> 85% context used)
- **Behavior:** Wrap up immediately. Prepare for handoff.
- Stop all exploratory work
- Complete only the immediately active task
- Create TASK.md and PROGRESS.md with current state
- Suggest the user start a new conversation
- If code changes are in progress, commit or save the current state

## How to Estimate the Zone

There is no direct token counter, but use these heuristics:
- **Message count:** 20+ back-and-forth exchanges → likely YELLOW
- **File reads:** 10+ files read → likely YELLOW; 20+ → likely ORANGE
- **Code output:** Multiple large code blocks generated → adds up fast
- **Tool calls:** 30+ tool calls → likely YELLOW; 50+ → likely ORANGE
- **System compression:** If earlier context appears compressed → the context is in ORANGE/RED

## Key Principles

1. **Front-load research.** Do exploration and reading early (GREEN zone) so context is available when needed later.
2. **Summarize throughout.** After reading a file, mentally note the key parts — avoid re-reading it.
3. **Delegate to save context.** The investigator agent (Haiku) is cheap and fast. Use it for broad searches.
4. **Fresh context is not failure.** Creating TASK.md + PROGRESS.md and starting fresh is a feature, not a workaround.
