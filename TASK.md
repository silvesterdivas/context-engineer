# Task: Polish and finalize context-engineer plugin

## Goal
Finalize the context-engineer Claude Code plugin for public release. Landing page, scorecard, documentation, and all plugin components should be production-ready.

## Context
- **Branch:** main
- **Date:** 2026-02-09
- **Previous sessions:** Multiple sessions building the plugin from scratch through v1.1.0
- **Live site:** https://silvesterdivas.github.io/context-engineer/
- **Repo:** https://github.com/silvesterdivas/context-engineer

## Constraints
- Plugin uses bash scripts + Unix tools (jq, grep, sed, awk) — macOS/Linux/WSL only
- Landing page split into 4 files (index.html, guide.html, styles.css, script.js) — all must stay under 500 lines
- Scorecard output must be compact (12 lines) to fit Claude Code's collapsed view
- Version is v1.1.2 across plugin.json, skills, landing page, and README

## Key Files
- `index.html` — Landing page
- `guide.html` — How-to guide page
- `styles.css` — Shared styles for both pages
- `script.js` — Shared JS for both pages
- `README.md` — GitHub readme with full documentation
- `scripts/scorecard.sh` — CLI health scorecard (ANSI terminal art)
- `commands/diagnose.md` — Diagnose command (embeds scorecard logic)
- `hooks/scripts/` — Token-saving filter hooks (test, build, lint)
- `skills/` — Background and user-invocable skills
- `.claude-plugin/plugin.json` — Plugin manifest

## Key Decisions Made
- **Compact scorecard (12 lines):** Collapsed from 24 lines so full output is visible in Claude Code without ctrl+o expand
  - *Reasoning:* Claude Code collapses long Bash output; users couldn't see the full scorecard
  - *Rejected alternatives:* Keeping the progress bar art (too many lines), making it even shorter (lost readability)
- **Platform support — bash required (macOS, Linux, WSL, Git Bash):** Native Windows CMD/PowerShell not supported
  - *Reasoning:* Plugin relies on bash scripts, jq, and Unix tools. Claude Code itself requires Git Bash on Windows, so bash is guaranteed.
  - *Rejected alternatives:* Node.js rewrite (unnecessary — bash is available on all Claude Code platforms), PowerShell equivalents (high maintenance), POSIX sh rewrite (still no native Windows support)
- **Landing page 4-file split:** index.html, guide.html, styles.css, script.js
  - *Reasoning:* Single index.html exceeded 500-line scorecard threshold
  - *Rejected alternatives:* Inlining CSS/JS (too large), further splitting HTML (unnecessary)
- **Removed Claude from contributors:** Stripped Co-Authored-By lines, toggled repo private/public to force GitHub contributor graph refresh
  - *Reasoning:* User wanted sole attribution

## Approaches Tried & Failed
- **None in this session** — all changes landed cleanly

## Session Update — 2026-02-11

### New Decisions
- **Cache glob for plugin root discovery:** Added `ls -d .../cache/.../*/ | sort -rV | head -1` to find the installed plugin in the marketplace cache directory
  - *Reasoning:* Hardcoded paths missed the actual install path (`cache/context-engineer-marketplace/context-engineer/<version>/`)
  - *Rejected alternatives:* `find` (slower, overkill), hardcoding the version (breaks on updates)
- **Windows support via Git Bash:** Confirmed Claude Code requires Git Bash on Windows, so all bash scripts work without changes
  - *Reasoning:* Investigated official docs — Git Bash is a hard requirement for Claude Code on Windows
  - *Rejected alternatives:* Node.js rewrite, PowerShell ports, POSIX sh rewrite — all unnecessary

## Session Update — 2026-02-14

### New Decisions
- **Cap all signal percentages at 100:** FILE_SIZE_PCT was uncapped while MSG_COUNT_PCT and TOOL_DENSITY_PCT were capped, causing composite scores >100
  - *Reasoning:* Consistency across all signals; uncapped values distorted the weighted average
  - *Rejected alternatives:* Removing all caps (would make zone thresholds meaningless at high values)
- **Narrow compression detection pattern:** Changed from broad `compressed|summarized|truncated` to context-aware patterns requiring words like "messages", "context", or "conversation" nearby
  - *Reasoning:* Users discussing data compression topics triggered false 25-point score inflation
  - *Rejected alternatives:* Disabling compression signal entirely (still useful for real compression), checking JSON structure (too fragile across transcript formats)
- **Atomic sentinel file creation:** Use `mktemp` + `mv -n` instead of direct write
  - *Reasoning:* Concurrent PostToolUse hook invocations could race on the sentinel check-then-write
  - *Rejected alternatives:* File locking with `flock` (not available on all macOS versions), accepting the race (could cause duplicate RED zone messages)
- **Use real token data instead of file-size heuristic:** Rewrote budget warning hook to read `input_tokens + cache_read_input_tokens + cache_creation_input_tokens` from the last assistant message in the transcript
  - *Reasoning:* The old `bytes / 4` heuristic was wildly inaccurate — reported 207% RED while actual usage was 72% YELLOW (3x overestimate). The transcript contains the exact same token data that `/context` uses.
  - *Rejected alternatives:* Improving the heuristic weights (fundamental flaw: transcript file grows forever while context window is managed with caching/compression), using only message count (doesn't account for system prompts or tool definitions)

### Approaches Tried & Failed
- **File size / 4 as token estimate:** The transcript file size bears no relation to actual context window usage because the file grows monotonically while the context window is managed with caching and auto-compression. A 1.6MB transcript had only 72% real usage, not 207%.
