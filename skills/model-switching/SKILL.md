---
name: Model Switching
description: This skill should be used when selecting a model for a task, when asking "which model should I use", "is this a Haiku or Sonnet task", "use haiku", or when delegating work to subagents and choosing a model tier.
version: 2.1.0
user-invocable: false
---

# Model Switching Guide

Match task complexity to the right model. Opus is now affordable enough for most work (~5x Haiku, not 25x like older pricing), so the main reasons to drop to Haiku or Sonnet are **speed and context conservation**, not raw cost. Using Haiku for architecture decisions wastes time; using Opus for a trivial grep wastes a little money and some latency.

## Model-Task Matrix

### Haiku (Fast, Cheap)
Best for tasks that are simple, repetitive, or involve searching:
- **File search & grep** - Finding files, searching for patterns
- **Simple code edits** - Renaming variables, fixing typos, adding imports
- **Quick lookups** - Checking a function signature, reading a config value
- **Boilerplate generation** - Test scaffolding, interface stubs, CRUD operations
- **Status checks** - Git status, running simple commands
- **Data extraction** - Pulling specific values from files or outputs

**Use via:** Investigator agent, or `model: "haiku"` in command frontmatter.

### Sonnet (Balanced)
Best for tasks that require understanding and multi-step reasoning:
- **Code review** - Reading and evaluating code quality, patterns, bugs
- **Refactoring** - Restructuring code while preserving behavior
- **Multi-file changes** - Coordinated edits across several files
- **Bug investigation** - Following call chains, understanding data flow
- **Feature implementation** - Standard features with clear requirements
- **Test writing** - Understanding code to write meaningful tests

**Use via:** Reviewer agent, or `model: "sonnet"` in command frontmatter.

### Opus (Powerful, Expensive)
Reserve for tasks that require deep reasoning or creativity:
- **Architecture decisions** - System design, technology choices, trade-offs
- **Complex debugging** - Race conditions, memory leaks, subtle logic errors
- **Security review** - Vulnerability analysis, threat modeling
- **Performance optimization** - Algorithmic improvements, profiling analysis
- **Novel problem solving** - Unusual requirements, creative solutions
- **Cross-system integration** - Understanding how multiple systems interact

**Use via:** Default model in most configurations, or explicit `model: "opus"`.

## Cost Ratios (current pricing, per 1M tokens)

| Model | Input / Output | Relative cost | Speed |
|-------|----------------|---------------|-------|
| Haiku 4.5  | $1 / $5   | 1x  | Fastest |
| Sonnet 4.6 | $3 / $15  | ~3x | Medium  |
| Opus 4.8   | $5 / $25  | ~5x | Slowest |

Opus is ~5x Haiku today (it was 25x under older Opus pricing), so switching models down is a **weaker cost lever** than it used to be. The dominant way to cut token cost now is **prompt caching** - cache reads cost ~0.1x the input rate, so a cache-friendly workflow can save far more than any model downgrade. See the prompt-caching skill.

## Decision Heuristic

Apply this decision heuristic:
1. **Is this a search or lookup?** → Haiku
2. **Does this require reading and understanding code?** → Sonnet
3. **Does this require creative reasoning or weighing trade-offs?** → Opus
4. **Unsure?** → Start with Sonnet, escalate to Opus if stuck

## Subagent Delegation

When delegating to subagents via the Task tool:
- Set `model: "haiku"` for investigation and search tasks
- Set `model: "sonnet"` for review and implementation tasks
- Leave model unset (inherits parent) for tasks that need full capability
