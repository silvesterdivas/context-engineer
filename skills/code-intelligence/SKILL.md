---
name: Code Intelligence
description: This skill provides guidance on using LSP-aware tools and code navigation efficiently, preferring structured code intelligence over brute-force text search when navigating codebases.
version: 1.1.0
user-invocable: false
---

# Code Intelligence & Navigation

Use the most efficient tool for each code navigation task. Structured code intelligence saves tokens compared to brute-force search.

## Tool Selection Guide

### Finding a Symbol Definition
**Best:** `Grep` with a precise pattern like `^(export )?(function|class|const|type|interface) SymbolName`
**Also good:** `Glob` to find likely files, then targeted `Read` with line ranges
**Avoid:** Reading entire files hoping to stumble on the definition

### Finding All Usages of a Symbol
**Best:** `Grep` with the symbol name, filtered by file type (e.g., `glob: "*.ts"`)
**Avoid:** Reading every file in the project

### Understanding a File's Exports
**Best:** `Grep` for `^export` in the specific file
**Avoid:** Reading the entire file when you only need the API surface

### Navigating Imports
**Best:** `Grep` for `from ['"].*moduleName` to find who imports a module
**Also good:** `Grep` for `import.*SymbolName` to find where a symbol is imported

### Finding Related Files
**Best:** `Glob` with patterns like `**/auth*.ts` or `**/*Controller*`
**Avoid:** `ls -R` or recursive directory reads

### Understanding Type Hierarchies
**Best:** `Grep` for `extends ClassName` or `implements InterfaceName`
**Also good:** `Grep` for the type name in `.d.ts` files

## Token Cost Comparison

| Action | Approximate Token Cost |
|--------|----------------------|
| `Grep` single pattern | 50-200 tokens |
| `Glob` file search | 50-150 tokens |
| `Read` specific lines | 100-500 tokens |
| `Read` full file (small) | 500-2000 tokens |
| `Read` full file (large) | 2000-10000 tokens |
| Investigator agent search | 500-1500 tokens (but uses Haiku) |

## Principles

1. **Pattern before content.** Find the right location with Grep/Glob, then Read only what you need.
2. **File type filters save tokens.** Always use `glob` or `type` parameters in Grep to narrow scope.
3. **Line ranges are free wins.** `Read` with `offset` and `limit` is dramatically cheaper than full file reads.
4. **Delegate broad searches.** If you need to search across many files, use the investigator agent — it's cheap (Haiku) and keeps the results out of your context.
