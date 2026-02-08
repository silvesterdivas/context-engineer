---
description: Audit MCP servers — list active servers, flag unused ones wasting context tokens
allowed-tools: Read, Bash, Glob, Grep
---

# MCP Server Audit

Audit the currently configured MCP servers and identify any that may be wasting context window tokens.

## Instructions

1. **Find MCP configuration** by checking these locations:
   - `.claude/settings.json` in the project root
   - `~/.claude/settings.json` (global)
   - `.mcp.json` in the project root
   - Look for `mcpServers` keys in any settings files

2. **List all configured MCP servers** with:
   - Server name
   - Number of tools provided (each tool definition consumes ~200-500 tokens of context)
   - Whether the server appears to be running/healthy

3. **Flag potential waste:**
   - Servers providing tools that overlap with built-in Claude Code tools (Read, Write, Grep, Glob, Bash)
   - Servers with many tools (>10) where most aren't being used for this project
   - Servers that appear to be for a different project or tech stack

4. **Calculate estimated token impact:**
   - Each MCP tool definition: ~200-500 tokens
   - Each MCP server system prompt: ~100-300 tokens
   - Total overhead = sum of all tool definitions + server prompts

5. **Provide recommendations:**
   - Which servers to keep (relevant to current project)
   - Which servers to consider disabling (not relevant or redundant)
   - Estimated token savings from cleanup

6. **Output a summary table:**

```
| Server | Tools | Est. Tokens | Recommendation |
|--------|-------|-------------|----------------|
| ...    | ...   | ...         | Keep/Remove    |
```
