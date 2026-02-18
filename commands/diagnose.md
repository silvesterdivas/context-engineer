---
description: Run a context engineering health scorecard for this project
allowed-tools: Read, Glob, Grep, Bash
---

# Context Engineering Diagnosis

Run the visual health scorecard and provide actionable recommendations.

## Instructions

### Step 1: Run the inline scorecard

Run this self-contained scorecard script. Replace `<project-root>` with the user's current working directory:

```bash
bash -c '
PROJECT_ROOT="${1:-.}"

PASS=0; WARN=0; FAIL=0; TOTAL=4

# ── Find plugin root (search common locations) ──
PLUGIN_ROOT=""
CACHE_LATEST=$(ls -d "$HOME/.claude/plugins/cache/context-engineer-marketplace/context-engineer"/*/ 2>/dev/null | sort -rV | head -1)
for candidate in \
  "${CLAUDE_PLUGIN_ROOT:-}" \
  "$HOME/.claude/plugins/context-engineer" \
  "$HOME/.claude/plugins/context-engineer-marketplace/context-engineer" \
  "$CACHE_LATEST" \
  "$PROJECT_ROOT"; do
  [[ -n "$candidate" && -f "$candidate/hooks/scripts/filter-test-output.sh" ]] && PLUGIN_ROOT="$candidate" && break
done

# ── Version ──
VER="?.?.?"
for pj in "$PLUGIN_ROOT/.claude-plugin/plugin.json" "$PROJECT_ROOT/.claude-plugin/plugin.json"; do
  if [[ -f "$pj" ]]; then
    VER=$(grep -o "\"version\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$pj" | grep -o "[0-9][0-9.]*" || echo "?.?.?")
    break
  fi
done

# ── Helpers ──
divider() { echo "  ──────────────────────────────────────────────────"; }
check_row() {
  local status="$1" label="$2" detail="$3" icon=""
  case "$status" in
    pass) icon="[PASS]" ;; warn) icon="[WARN]" ;;
    fail) icon="[FAIL]" ;; info) icon="[INFO]" ;;
  esac
  printf "  %-6s %-20s %s\n" "$icon" "$label" "$detail"
}

# ── 1. CLAUDE.md ──
CLAUDE_MD=""
for dir in "$PROJECT_ROOT" "$PROJECT_ROOT/.."; do
  [[ -f "$dir/CLAUDE.md" ]] && CLAUDE_MD="$dir/CLAUDE.md" && break
done

c1_status="fail"
c1_detail="No CLAUDE.md found -- run /context-engineer:setup"

if [[ -n "$CLAUDE_MD" ]]; then
  hb=$(grep -c "Budget Zones" "$CLAUDE_MD" 2>/dev/null || true)
  hf=$(grep -c "Fresh Context" "$CLAUDE_MD" 2>/dev/null || true)
  ht=$(grep -c "Tool Efficiency" "$CLAUDE_MD" 2>/dev/null || true)
  cb="x"; [[ ${hb:-0} -gt 0 ]] && cb="ok"
  cf="x"; [[ ${hf:-0} -gt 0 ]] && cf="ok"
  ct="x"; [[ ${ht:-0} -gt 0 ]] && ct="ok"
  if [[ ${hb:-0} -gt 0 && ${hf:-0} -gt 0 && ${ht:-0} -gt 0 ]]; then
    c1_status="pass"; c1_detail="Budget=$cb  FreshContext=$cf  Tools=$ct"; PASS=$((PASS + 1))
  else
    c1_status="warn"; c1_detail="Budget=$cb  FreshContext=$cf  Tools=$ct"; WARN=$((WARN + 1))
  fi
else
  FAIL=$((FAIL + 1))
fi

# ── 2. Token-Saving Hooks ──
h_test=0; h_build=0; h_lint=0
if [[ -n "$PLUGIN_ROOT" ]]; then
  [[ -f "$PLUGIN_ROOT/hooks/scripts/filter-test-output.sh" ]] && h_test=1
  [[ -f "$PLUGIN_ROOT/hooks/scripts/filter-build-output.sh" ]] && h_build=1
  [[ -f "$PLUGIN_ROOT/hooks/scripts/filter-lint-output.sh" ]] && h_lint=1
fi
h_count=$((h_test + h_build + h_lint))

ht="x"; [[ $h_test -eq 1 ]] && ht="ok"
hb="x"; [[ $h_build -eq 1 ]] && hb="ok"
hl="x"; [[ $h_lint -eq 1 ]] && hl="ok"

if [[ $h_count -eq 3 ]]; then
  c2_status="pass"; c2_detail="test=$ht  build=$hb  lint=$hl"; PASS=$((PASS + 1))
elif [[ $h_count -gt 0 ]]; then
  c2_status="warn"; c2_detail="test=$ht  build=$hb  lint=$hl"; WARN=$((WARN + 1))
else
  c2_status="fail"; c2_detail="No filter hooks found"; FAIL=$((FAIL + 1))
fi

# ── 3. Fresh Context Files (informational) ──
f_task=0; [[ -f "$PROJECT_ROOT/TASK.md" ]] && f_task=1
f_prog=0; [[ -f "$PROJECT_ROOT/PROGRESS.md" ]] && f_prog=1

if [[ $f_task -eq 1 && $f_prog -eq 1 ]]; then
  c3_status="pass"; c3_detail="TASK.md=ok  PROGRESS.md=ok"
elif [[ $f_task -eq 1 || $f_prog -eq 1 ]]; then
  td="x"; [[ $f_task -eq 1 ]] && td="ok"
  pd="x"; [[ $f_prog -eq 1 ]] && pd="ok"
  c3_status="warn"; c3_detail="TASK.md=$td  PROGRESS.md=$pd"
else
  c3_status="info"; c3_detail="No active handoff files"
fi

# ── 4. Git Hygiene ──
c4_status="warn"; c4_detail="Not a git repository"

if git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree &>/dev/null; then
  if git -C "$PROJECT_ROOT" rev-parse HEAD &>/dev/null; then
    diff_stat=$(git -C "$PROJECT_ROOT" diff --stat HEAD 2>/dev/null | tail -1 || true)
  else
    diff_stat=""
  fi
  untracked=$(git -C "$PROJECT_ROOT" status --short 2>/dev/null | wc -l | tr -d " " || echo 0)

  if [[ -z "$diff_stat" && "${untracked:-0}" -le 2 ]]; then
    c4_status="pass"; c4_detail="Clean working tree"; PASS=$((PASS + 1))
  else
    ins=$(echo "$diff_stat" | grep -o "[0-9]* insertion" | grep -o "[0-9]*" || true)
    del=$(echo "$diff_stat" | grep -o "[0-9]* deletion" | grep -o "[0-9]*" || true)
    total_changes=$(( ${ins:-0} + ${del:-0} ))
    if [[ $total_changes -lt 500 ]]; then
      c4_status="pass"; c4_detail="${total_changes} lines changed, ${untracked} untracked"; PASS=$((PASS + 1))
    elif [[ $total_changes -lt 2000 ]]; then
      c4_status="warn"; c4_detail="${total_changes} lines -- consider committing"; WARN=$((WARN + 1))
    else
      c4_status="fail"; c4_detail="${total_changes} lines uncommitted -- context risk"; FAIL=$((FAIL + 1))
    fi
  fi
else
  WARN=$((WARN + 1))
fi

# ── 5. Project Structure ──
c5_status="pass"; c5_detail="All files < 500 lines"

largest_line=$(find "$PROJECT_ROOT" -type f \
  \( -name "*.sh" -o -name "*.md" -o -name "*.json" -o -name "*.js" -o -name "*.ts" \
     -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" -o -name "*.tsx" \
     -o -name "*.jsx" -o -name "*.html" -o -name "*.css" -o -name "*.rb" -o -name "*.swift" \) \
  ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/vendor/*" \
  ! -path "*/dist/*" ! -path "*/build/*" ! -path "*/.next/*" \
  -exec wc -l {} + 2>/dev/null | sort -rn | head -1 || echo "0 total")

if echo "$largest_line" | grep -q "total$"; then
  largest_line=$(find "$PROJECT_ROOT" -type f \
    \( -name "*.sh" -o -name "*.md" -o -name "*.json" -o -name "*.js" -o -name "*.ts" \
       -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" -o -name "*.tsx" \
       -o -name "*.jsx" -o -name "*.html" -o -name "*.css" -o -name "*.rb" -o -name "*.swift" \) \
    ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/vendor/*" \
    ! -path "*/dist/*" ! -path "*/build/*" ! -path "*/.next/*" \
    -exec wc -l {} + 2>/dev/null | sort -rn | head -2 | tail -1 || echo "0 unknown")
fi

lc=$(echo "$largest_line" | awk "{print \$1}" || echo 0)
lf=$(echo "$largest_line" | awk "{print \$2}" | xargs basename 2>/dev/null || echo "?")
lc=${lc:-0}

big_count=0
if [[ -d "$PROJECT_ROOT" ]]; then
  big_count=$(find "$PROJECT_ROOT" -type f \
    \( -name "*.sh" -o -name "*.md" -o -name "*.json" -o -name "*.js" -o -name "*.ts" \
       -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" \) \
    ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/vendor/*" \
    -exec wc -l {} + 2>/dev/null | awk "\$1 > 1000 && !/total$/" | wc -l | tr -d " " || echo 0)
fi

if [[ ${big_count:-0} -gt 3 ]]; then
  c5_status="fail"; c5_detail="${big_count} files > 1000 lines"; FAIL=$((FAIL + 1))
elif [[ ${lc:-0} -gt 500 ]]; then
  c5_status="warn"; c5_detail="Largest: ${lf} (${lc} lines)"; WARN=$((WARN + 1))
else
  c5_status="pass"; c5_detail="All files < 500 lines"; PASS=$((PASS + 1))
fi

echo ""
divider
echo "  context-engineer v${VER} -- Health Scorecard"
divider
check_row "$c1_status" "CLAUDE.md" "$c1_detail"
check_row "$c2_status" "Token-Saving Hooks" "$c2_detail"
check_row "$c3_status" "Fresh Context" "$c3_detail"
check_row "$c4_status" "Git Hygiene" "$c4_detail"
check_row "$c5_status" "Project Structure" "$c5_detail"

if [[ $FAIL -gt 0 ]]; then ST="Needs attention."
elif [[ $WARN -gt 0 ]]; then ST="Almost there."
else ST="Your context is engineered."
fi

divider
echo "  Score: ${PASS}/${TOTAL} passing -- ${ST}"
divider
echo "  Tokens saved: test ~80%  build ~90%  lint ~70%"
echo ""

if [[ $FAIL -gt 0 ]]; then exit 2
elif [[ $WARN -gt 0 ]]; then exit 1
else exit 0
fi
' -- <project-root>
```

### Step 2: MCP Server Hygiene (manual check)

The scorecard doesn't check MCP servers — that requires inspecting the system context. Check manually:
- Count the number of MCP servers active in this session (visible in the system prompt)
- Count the total MCP tools available
- **PASS:** All servers are relevant, total tools < 20
- **WARN:** 1-2 potentially unused servers
- **FAIL:** 3+ unused servers or > 20 total tools

Report MCP status as a line after the scorecard output:
```
MCP Hygiene: X servers, Y tools — [assessment]
```

### Step 3: Recommendations

If any checks show WARN or FAIL, list specific fix actions ordered by impact:
- CLAUDE.md missing → Run `/context-engineer:setup`
- Hooks missing → Reinstall the plugin
- Large files → Suggest splitting specific files
- Git hygiene → Suggest committing or stashing
- MCP bloat → Run `/context-engineer:audit-mcp`

If all checks pass, just say the project is fully configured — no further action needed.
