#!/usr/bin/env bash
set -uo pipefail
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fail=0
pass() { printf 'PASS  %s\n' "$1"; }
failmsg() { printf 'FAIL  %s\n' "$1"; fail=1; }

[ -f "$root/.opencode/agents/goblin-logic-manager.md" ] && pass "generated agent exists" || failmsg "generated agent missing"
[ -f "$root/.opencode/skills/goblin-chunk-compact/SKILL.md" ] && pass "chunk compact skill exists" || failmsg "chunk compact skill missing"
[ -f "$root/.opencode/commands/goblin-close.md" ] && pass "closeout command exists" || failmsg "closeout command missing"
grep -q '^name: goblin-chunk-compact$' "$root/.opencode/skills/goblin-chunk-compact/SKILL.md" && pass "skill ID/frontmatter aligned" || failmsg "skill frontmatter mismatch"
grep -q 'model: tokenrouter/z-ai/glm-5.3-free' "$root/.opencode/agents/goblin-logic-manager.md" && pass "known working GLM route bound" || failmsg "GLM route not updated"
[ -f "$root/skill-registry.json" ] && pass "skill routing registry exists" || failmsg "skill routing registry missing"
[ -f "$root/docs/SKILL-ROUTING.md" ] && pass "skill routing guide exists" || failmsg "skill routing guide missing"
[ -x "$root/scripts/skill-preflight.py" ] && pass "skill preflight is executable" || failmsg "skill preflight missing/not executable"
grep -q 'NO SKILL SOUP' "$root/docs/SKILL-ROUTING.md" && pass "no-skill-soup invariant documented" || failmsg "skill routing invariant missing"
grep -q 'update-ledger-compact' "$root/.opencode/commands/goblin-close.md" && pass "closeout prefers ledger-aware compact path" || failmsg "closeout skill precedence missing"

if "$root/scripts/smoke-install-layout.sh"; then
  pass "recommended install/rollback layout is isolated and reversible"
else
  failmsg "recommended install/rollback layout smoke"
fi

start=$(date +%s)
"$root/scripts/bounded-wait.sh" 5 2 -- bash -c 'sleep 1; printf early-finish' >/tmp/goblin-early.out 2>/tmp/goblin-early.err
rc=$?
elapsed=$(( $(date +%s) - start ))
if [ "$rc" -eq 0 ] && grep -q 'GOBLIN_WAIT_STATUS=COMPLETE' /tmp/goblin-early.err && grep -q 'early-finish' /tmp/goblin-early.out && [ "$elapsed" -lt 5 ]; then
  pass "bounded wait returns before inner timeout when child finishes"
else
  failmsg "bounded early-finish behavior"
fi

"$root/scripts/bounded-wait.sh" 1 2 -- bash -c 'sleep 5' >/tmp/goblin-timeout.out 2>/tmp/goblin-timeout.err
rc=$?
if [ "$rc" -eq 124 ] && grep -q 'GOBLIN_WAIT_STATUS=TIMED_OUT' /tmp/goblin-timeout.err; then
  pass "bounded wait classifies inner timeout"
else
  failmsg "bounded timeout classification rc=$rc"
fi

if command -v opencode >/dev/null 2>&1; then
  version=$(opencode --version 2>/dev/null || true)
  printf 'INFO  opencode=%s\n' "$version"
  opencode agent list 2>/dev/null | grep -q 'goblin-logic-manager' && pass "OpenCode discovers Goblin agent" || failmsg "OpenCode did not list Goblin agent"
  opencode models 2>/dev/null | grep -q '^tokenrouter/z-ai/glm-5.3-free$' && pass "OpenCode model catalog contains GLM route" || printf 'WARN  tokenrouter/z-ai/glm-5.3-free not visible in current model catalog\n'
else
  printf 'SKIP  OpenCode binary not installed in this smoke environment\n'
fi

rm -f /tmp/goblin-early.out /tmp/goblin-early.err /tmp/goblin-timeout.out /tmp/goblin-timeout.err
exit "$fail"
