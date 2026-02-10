---
name: Thinking Control
description: This skill provides guidance on how to calibrate thinking depth for different task types, avoiding over-thinking simple tasks and under-thinking complex ones.
version: 1.1.0
user-invocable: false
---

# Thinking Depth Control

Calibrate your reasoning effort to the task at hand. Deep thinking is powerful but expensive — both in tokens and latency.

## Thinking Levels

### Minimal Thinking
**When:** Routine, mechanical tasks with clear instructions.
- Running a command the user specified
- Making a simple edit the user described exactly
- Reading a file the user pointed to
- Formatting or reorganizing existing content

**Approach:** Act immediately. Don't deliberate on obvious actions.

### Light Thinking
**When:** Standard development tasks with clear patterns.
- Writing a function with clear inputs/outputs
- Fixing a straightforward bug
- Adding a test for existing behavior
- Implementing a well-defined feature

**Approach:** Brief consideration of approach, then execute. One pass is usually sufficient.

### Moderate Thinking
**When:** Tasks requiring analysis or multi-step planning.
- Refactoring code for better structure
- Debugging an issue with multiple possible causes
- Implementing a feature that touches several files
- Writing code that must handle edge cases

**Approach:** Consider 2-3 approaches before choosing. Read relevant code first. Plan your steps.

### Deep Thinking
**When:** Complex tasks requiring careful reasoning.
- Architecture decisions with long-term implications
- Security-sensitive code (auth, crypto, input validation)
- Performance-critical algorithms
- Resolving conflicting requirements
- Understanding unfamiliar or complex codebases

**Approach:** Thoroughly explore the problem space. Consider trade-offs. Read all relevant code. Plan in detail before writing. Review your own output.

## Anti-Patterns

### Over-Thinking
- Writing a paragraph of analysis before making a one-line fix
- Considering edge cases that can't happen given the constraints
- Planning three approaches for a task with one obvious solution
- Adding extensive error handling to internal utilities

### Under-Thinking
- Jumping into a multi-file refactor without reading the existing code
- Making architecture decisions without understanding the current system
- Writing security-sensitive code without considering attack vectors
- Implementing a feature without checking if it already exists

## Context Budget Impact

Thinking consumes context window space:
- **Minimal:** ~50 tokens of reasoning overhead
- **Light:** ~200 tokens
- **Moderate:** ~500-1000 tokens
- **Deep:** ~2000-5000 tokens

In YELLOW/ORANGE budget zones, bias toward lighter thinking. In RED zone, use minimal thinking — focus on saving state and wrapping up.
