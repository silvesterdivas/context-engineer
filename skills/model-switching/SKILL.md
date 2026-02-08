---
name: Model Switching
description: This skill provides guidance on which model to use for different task types, optimizing for cost and capability by matching task complexity to the appropriate model tier.
version: 1.0.0
user-invocable: false
---

# Model Switching Guide

Match task complexity to the right model. Using Opus for simple searches wastes money; using Haiku for architecture decisions wastes time.

## Model-Task Matrix

### Haiku (Fast, Cheap)
Best for tasks that are simple, repetitive, or involve searching:
- **File search & grep** — Finding files, searching for patterns
- **Simple code edits** — Renaming variables, fixing typos, adding imports
- **Quick lookups** — Checking a function signature, reading a config value
- **Boilerplate generation** — Test scaffolding, interface stubs, CRUD operations
- **Status checks** — Git status, running simple commands
- **Data extraction** — Pulling specific values from files or outputs

**Use via:** Investigator agent, or `model: "haiku"` in command frontmatter.

### Sonnet (Balanced)
Best for tasks that require understanding and multi-step reasoning:
- **Code review** — Reading and evaluating code quality, patterns, bugs
- **Refactoring** — Restructuring code while preserving behavior
- **Multi-file changes** — Coordinated edits across several files
- **Bug investigation** — Following call chains, understanding data flow
- **Feature implementation** — Standard features with clear requirements
- **Test writing** — Understanding code to write meaningful tests

**Use via:** Reviewer agent, or `model: "sonnet"` in command frontmatter.

### Opus (Powerful, Expensive)
Reserve for tasks that require deep reasoning or creativity:
- **Architecture decisions** — System design, technology choices, trade-offs
- **Complex debugging** — Race conditions, memory leaks, subtle logic errors
- **Security review** — Vulnerability analysis, threat modeling
- **Performance optimization** — Algorithmic improvements, profiling analysis
- **Novel problem solving** — Unusual requirements, creative solutions
- **Cross-system integration** — Understanding how multiple systems interact

**Use via:** Default model in most configurations, or explicit `model: "opus"`.

## Cost Ratios (Approximate)

| Model | Relative Cost | Speed |
|-------|--------------|-------|
| Haiku | 1x | Fastest |
| Sonnet | 5x | Medium |
| Opus | 25x | Slowest |

## Decision Heuristic

Ask yourself:
1. **Is this a search or lookup?** → Haiku
2. **Does this require reading and understanding code?** → Sonnet
3. **Does this require creative reasoning or weighing trade-offs?** → Opus
4. **Am I unsure?** → Start with Sonnet, escalate to Opus if stuck

## Subagent Delegation

When delegating to subagents via the Task tool:
- Set `model: "haiku"` for investigation and search tasks
- Set `model: "sonnet"` for review and implementation tasks
- Leave model unset (inherits parent) for tasks that need full capability
