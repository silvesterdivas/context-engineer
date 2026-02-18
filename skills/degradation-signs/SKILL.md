---
name: Degradation Signs
description: This skill should be used when forgetting earlier context, looping on errors, producing inconsistent code, or when the user says "you already did that", "that's wrong", "you're hallucinating", or "context is degrading".
version: 1.1.2
user-invocable: true
---

# Context Degradation Self-Diagnosis

Context performance degrades in predictable ways as the window fills. Monitor for these signs and take corrective action.

## Degradation Stages

### Stage 1: Mild (60% context)
**Signs:**
- Occasionally forgetting a detail from early in the conversation
- Asking the user to re-confirm something already discussed
- Slight inconsistencies in variable names or API shapes

**Action:**
- Re-read the most critical file before making changes
- Summarize the current plan before proceeding
- Switch to more targeted tool use (Grep over Read)

### Stage 2: Moderate (75% context)
**Signs:**
- Forgetting which files you've already modified
- Proposing changes that contradict earlier decisions
- Missing imports or references that were established earlier
- Generating code that doesn't match the project's patterns

**Action:**
- Stop and create a brief status summary for yourself
- Re-read only the files you're actively modifying
- Delegate research tasks to the investigator agent
- Consider creating TASK.md + PROGRESS.md

### Stage 3: Severe (85% context)
**Signs:**
- Hallucinating function signatures or file contents
- Looping: trying the same fix repeatedly without progress
- Producing code that won't compile/run due to misremembered APIs
- Losing track of the overall goal

**Action:**
- **Stop coding immediately.**
- Create TASK.md and PROGRESS.md with current state
- Tell the user: "I'm experiencing context degradation. Let me save our progress so we can continue in a fresh conversation."
- Commit any working changes before wrapping up

### Stage 4: Critical (90%+ context)
**Signs:**
- Unable to maintain coherent multi-step reasoning
- Contradicting yourself within a single response
- Generating nonsensical or completely wrong code

**Action:**
- **Do not attempt any more code changes.**
- Save state immediately (TASK.md + PROGRESS.md)
- End the conversation gracefully

## Self-Check Protocol

When you suspect degradation, run this mental checklist:

1. **Can I recall the project's main goal?** If fuzzy → Stage 1+
2. **Can I list the files I've modified?** If unsure → Stage 2+
3. **Can I describe the function I'm currently editing without re-reading it?** If no → Stage 2+
4. **Am I repeating a step I already tried?** If yes → Stage 3
5. **Does my code reference real APIs/functions?** If unsure → Stage 3

## Prevention

- Use budget zones proactively (don't wait for degradation)
- Delegate to subagents for any research that isn't immediately needed
- Commit working changes frequently — smaller commits = safer state
- Create fresh context files preemptively for complex tasks
