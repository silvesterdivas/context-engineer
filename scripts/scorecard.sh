#!/usr/bin/env bash
# scorecard.sh — Screenshot-worthy health scorecard for context-engineer
# Usage: bash scorecard.sh [project-root]

PROJECT_ROOT="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Colors ──
G='\033[0;32m'    # green
Y='\033[0;33m'    # yellow/amber
R='\033[0;31m'    # red
C='\033[0;36m'    # cyan
D='\033[0;90m'    # dim
B='\033[1m'       # bold
BG='\033[1;32m'   # bold green
BY='\033[1;33m'   # bold yellow
BR='\033[1;31m'   # bold red
N='\033[0m'       # reset

# ── Box width ──
W=60

# ── Counters ──
PASS=0
WARN=0
FAIL=0
TOTAL=4  # Fresh Context is informational, not scored

# ── Version ──
VER="?.?.?"
if [[ -f "$PLUGIN_ROOT/.claude-plugin/plugin.json" ]]; then
  VER=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$PLUGIN_ROOT/.claude-plugin/plugin.json" | grep -o '[0-9][0-9.]*' || echo "?.?.?")
fi

# ── Helpers ──
box_top()    { echo -e "  ${C}┌$(printf '─%.0s' $(seq 1 $W))┐${N}"; }
box_bottom() { echo -e "  ${C}└$(printf '─%.0s' $(seq 1 $W))┘${N}"; }
box_line()   {
  local text="$1"
  local plain
  plain=$(echo -e "$text" | sed $'s/\033\[[0-9;]*m//g')
  local len=${#plain}
  local pad=$((W - len - 2))
  [[ $pad -lt 1 ]] && pad=1
  echo -e "  ${C}│${N} ${text}$(printf ' %.0s' $(seq 1 $pad))${C}│${N}"
}


check_row() {
  local status="$1" label="$2" detail="$3" dot=""
  case "$status" in
    pass) dot="${G}●${N}" ;;
    warn) dot="${Y}●${N}" ;;
    fail) dot="${R}●${N}" ;;
    info) dot="${D}○${N}" ;;
  esac
  local label_len=${#label}
  local pad=$((22 - label_len))
  [[ $pad -lt 1 ]] && pad=1
  local padding
  padding=$(printf ' %.0s' $(seq 1 $pad))
  echo -e "  ${dot} ${B}${label}${N}${padding} ${detail}"
}



# ══════════════════════════════════════════════════════════
# CHECKS
# ══════════════════════════════════════════════════════════

# ── 1. CLAUDE.md ──
CLAUDE_MD=""
for dir in "$PROJECT_ROOT" "$PROJECT_ROOT/.."; do
  [[ -f "$dir/CLAUDE.md" ]] && CLAUDE_MD="$dir/CLAUDE.md" && break
done

c1_status="fail"
c1_detail="No CLAUDE.md found — run ${B}/context-engineer:setup${N}"

if [[ -n "$CLAUDE_MD" ]]; then
  hb=$(grep -c "Budget Zones" "$CLAUDE_MD" 2>/dev/null || true)
  hf=$(grep -c "Fresh Context" "$CLAUDE_MD" 2>/dev/null || true)
  ht=$(grep -c "Tool Efficiency" "$CLAUDE_MD" 2>/dev/null || true)

  cb="${R}✗${N}"; [[ ${hb:-0} -gt 0 ]] && cb="${G}✓${N}"
  cf="${R}✗${N}"; [[ ${hf:-0} -gt 0 ]] && cf="${G}✓${N}"
  ct="${R}✗${N}"; [[ ${ht:-0} -gt 0 ]] && ct="${G}✓${N}"

  if [[ ${hb:-0} -gt 0 && ${hf:-0} -gt 0 && ${ht:-0} -gt 0 ]]; then
    c1_status="pass"
    c1_detail="Budget ${cb}  Fresh context ${cf}  Tools ${ct}"
    PASS=$((PASS + 1))
  else
    c1_status="warn"
    c1_detail="Budget ${cb}  Fresh context ${cf}  Tools ${ct}"
    WARN=$((WARN + 1))
  fi
else
  FAIL=$((FAIL + 1))
fi

# ── 2. Token-Saving Hooks ──
h_test=0; [[ -f "$PLUGIN_ROOT/hooks/scripts/filter-test-output.sh" ]] && h_test=1
h_build=0; [[ -f "$PLUGIN_ROOT/hooks/scripts/filter-build-output.sh" ]] && h_build=1
h_lint=0; [[ -f "$PLUGIN_ROOT/hooks/scripts/filter-lint-output.sh" ]] && h_lint=1
h_count=$((h_test + h_build + h_lint))

ct="${R}✗${N}"; [[ $h_test -eq 1 ]] && ct="${G}✓${N}"
cb="${R}✗${N}"; [[ $h_build -eq 1 ]] && cb="${G}✓${N}"
cl="${R}✗${N}"; [[ $h_lint -eq 1 ]] && cl="${G}✓${N}"

if [[ $h_count -eq 3 ]]; then
  c2_status="pass"; c2_detail="test ${ct}  build ${cb}  lint ${cl}"; PASS=$((PASS + 1))
elif [[ $h_count -gt 0 ]]; then
  c2_status="warn"; c2_detail="test ${ct}  build ${cb}  lint ${cl}"; WARN=$((WARN + 1))
else
  c2_status="fail"; c2_detail="No filter hooks found"; FAIL=$((FAIL + 1))
fi

# ── 3. Fresh Context Files (informational — not counted) ──
f_task=0; [[ -f "$PROJECT_ROOT/TASK.md" ]] && f_task=1
f_prog=0; [[ -f "$PROJECT_ROOT/PROGRESS.md" ]] && f_prog=1

if [[ $f_task -eq 1 && $f_prog -eq 1 ]]; then
  c3_status="pass"; c3_detail="TASK.md ${G}✓${N}  PROGRESS.md ${G}✓${N}"
elif [[ $f_task -eq 1 || $f_prog -eq 1 ]]; then
  td="${R}✗${N}"; [[ $f_task -eq 1 ]] && td="${G}✓${N}"
  pd="${R}✗${N}"; [[ $f_prog -eq 1 ]] && pd="${G}✓${N}"
  c3_status="warn"; c3_detail="TASK.md ${td}  PROGRESS.md ${pd}"
else
  c3_status="info"; c3_detail="${D}No active handoff files${N}"
fi

# ── 4. Git Hygiene ──
c4_status="warn"
c4_detail="Not a git repository"

if git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree &>/dev/null; then
  # Check if there are any commits
  if git -C "$PROJECT_ROOT" rev-parse HEAD &>/dev/null; then
    diff_stat=$(git -C "$PROJECT_ROOT" diff --stat HEAD 2>/dev/null | tail -1 || true)
  else
    diff_stat=""  # No commits yet
  fi
  untracked=$(git -C "$PROJECT_ROOT" status --short 2>/dev/null | wc -l | tr -d ' ' || echo 0)

  if [[ -z "$diff_stat" && "${untracked:-0}" -le 2 ]]; then
    c4_status="pass"; c4_detail="Clean working tree"; PASS=$((PASS + 1))
  else
    ins=$(echo "$diff_stat" | grep -o '[0-9]* insertion' | grep -o '[0-9]*' || true)
    del=$(echo "$diff_stat" | grep -o '[0-9]* deletion' | grep -o '[0-9]*' || true)
    total_changes=$(( ${ins:-0} + ${del:-0} ))

    if [[ $total_changes -lt 500 ]]; then
      c4_status="pass"; c4_detail="${total_changes} lines changed, ${untracked} untracked"; PASS=$((PASS + 1))
    elif [[ $total_changes -lt 2000 ]]; then
      c4_status="warn"; c4_detail="${Y}${total_changes} lines${N} — consider committing"; WARN=$((WARN + 1))
    else
      c4_status="fail"; c4_detail="${R}${total_changes} lines${N} uncommitted — context risk"; FAIL=$((FAIL + 1))
    fi
  fi
else
  WARN=$((WARN + 1))
fi

# ── 5. Project Structure ──
c5_status="pass"
c5_detail="All files < 500 lines"

# Find largest source file
largest_line=$(find "$PROJECT_ROOT" -type f \
  \( -name "*.sh" -o -name "*.md" -o -name "*.json" -o -name "*.js" -o -name "*.ts" \
     -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" -o -name "*.tsx" \
     -o -name "*.jsx" -o -name "*.html" -o -name "*.css" -o -name "*.rb" -o -name "*.swift" \) \
  ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/vendor/*" \
  ! -path "*/dist/*" ! -path "*/build/*" ! -path "*/.next/*" \
  -exec wc -l {} + 2>/dev/null | sort -rn | head -1 || echo "0 total")

# If the first line is "total", get the next one (single file case has no total)
if echo "$largest_line" | grep -q "total$"; then
  largest_line=$(find "$PROJECT_ROOT" -type f \
    \( -name "*.sh" -o -name "*.md" -o -name "*.json" -o -name "*.js" -o -name "*.ts" \
       -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" -o -name "*.tsx" \
       -o -name "*.jsx" -o -name "*.html" -o -name "*.css" -o -name "*.rb" -o -name "*.swift" \) \
    ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/vendor/*" \
    ! -path "*/dist/*" ! -path "*/build/*" ! -path "*/.next/*" \
    -exec wc -l {} + 2>/dev/null | sort -rn | head -2 | tail -1 || echo "0 unknown")
fi

lc=$(echo "$largest_line" | awk '{print $1}' || echo 0)
lf=$(echo "$largest_line" | awk '{print $2}' | xargs basename 2>/dev/null || echo "?")
lc=${lc:-0}

# Count files over 1000 lines
big_count=0
if [[ -d "$PROJECT_ROOT" ]]; then
  big_count=$(find "$PROJECT_ROOT" -type f \
    \( -name "*.sh" -o -name "*.md" -o -name "*.json" -o -name "*.js" -o -name "*.ts" \
       -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" \) \
    ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/vendor/*" \
    -exec wc -l {} + 2>/dev/null | awk '$1 > 1000 && !/total$/' | wc -l | tr -d ' ' || echo 0)
fi

if [[ ${big_count:-0} -gt 3 ]]; then
  c5_status="fail"; c5_detail="${R}${big_count} files${N} > 1000 lines"; FAIL=$((FAIL + 1))
elif [[ ${lc:-0} -gt 500 ]]; then
  c5_status="warn"; c5_detail="Largest: ${Y}${lf}${N} (${lc} lines)"; WARN=$((WARN + 1))
else
  c5_status="pass"; c5_detail="All files < 500 lines"; PASS=$((PASS + 1))
fi

# ══════════════════════════════════════════════════════════
# OUTPUT
# ══════════════════════════════════════════════════════════

echo ""
box_top
box_line "${B}context-engineer${N} v${VER}  ${D}·${N}  Health Scorecard"
box_bottom
check_row "$c1_status" "CLAUDE.md" "$c1_detail"
check_row "$c2_status" "Token-Saving Hooks" "$c2_detail"
check_row "$c3_status" "Fresh Context" "$c3_detail"
check_row "$c4_status" "Git Hygiene" "$c4_detail"
check_row "$c5_status" "Project Structure" "$c5_detail"

# ── Score box ──
if [[ $FAIL -gt 0 ]]; then
  SC="${BR}"; ST="Needs attention."
elif [[ $WARN -gt 0 ]]; then
  SC="${BY}"; ST="Almost there."
else
  SC="${BG}"; ST="Your context is engineered."
fi

box_top
box_line "${B}Score: ${PASS}/${TOTAL} passing${N}  ${D}·${N}  ${SC}${ST}${N}"
box_bottom
echo -e "  ${D}Tokens saved${N}  test ${G}~80%${N}  build ${G}~90%${N}  lint ${Y}~70%${N}"

# Exit code: 0=all pass, 1=warnings, 2=failures
if [[ $FAIL -gt 0 ]]; then exit 2
elif [[ $WARN -gt 0 ]]; then exit 1
else exit 0
fi
