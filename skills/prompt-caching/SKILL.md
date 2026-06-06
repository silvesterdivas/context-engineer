---
name: Prompt Caching
description: This skill should be used when working to reduce token cost, when asked "how do I cut token costs", "why is my session expensive", "make this cache-friendly", or when ordering work within a long session so the prompt cache stays warm.
version: 1.2.0
user-invocable: false
---

# Prompt Caching & Cost Efficiency

Prompt caching is the single biggest lever for cutting token cost. Cached tokens are re-read at **~0.1x** the normal input price; the first write costs **~1.25x**. A warm session can pay a tenth of the price for everything it has already seen — far more savings than any model downgrade. The whole game is keeping the cache warm.

## The one rule everything follows from

**Caching is a prefix match. Any change anywhere in the early context invalidates everything after it.**

The cache reuses content from the start of the conversation up to the point where something changes. Edit something near the beginning and every token after it must be re-read at full price. Append something new at the end and the entire prior prefix is still served from cache.

## Cache-friendly workflow in Claude Code

- **Keep `CLAUDE.md` and early context stable.** It sits at the front of the prefix — editing it mid-session re-reads everything below it at full price. Get it right early, then leave it alone.
- **Don't re-read or re-edit files you touched at the start of the session.** Reading file X early, then editing X again 30 turns later, churns the prefix. Do the work on X while it's still recent, or batch all edits to X together.
- **Batch related edits.** Several edits to one file in one turn cache better than the same edits spread across many turns interleaved with other work.
- **Don't thrash the tool or file set early.** A stable, predictable sequence of operations keeps the prefix reusable.
- **Delegate broad searches to the investigator subagent.** Large, volatile search output stays out of the main conversation's cached prefix — the subagent absorbs it and returns only the conclusion.
- **Append, don't insert.** New context added at the end is free to the cache; context inserted earlier is not.

## Verifying it works

The context-budget hook reports a `% cached` figure in its zone warnings, and `/context-engineer:diagnose` shows the session's cache-hit rate and estimated cost. A healthy long session should show a **high** cache-hit percentage. If it stays low, something is invalidating the prefix early — usually a `CLAUDE.md` edit or repeated edits to the same early file.

## Related

- **Model Switching** — cheaper than model downgrade in most cases; combine the two but reach for caching first.
- **Budget Zones** — the zone warnings carry the live `% cached` signal.
