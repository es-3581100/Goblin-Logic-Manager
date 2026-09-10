#!/usr/bin/env bash
set -uo pipefail

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
need() { command -v "$1" >/dev/null 2>&1 || { echo "FAIL  missing $1" >&2; exit 2; }; }
need mktemp
need readlink
need ln
need rm

sandbox=$(mktemp -d -t goblin-install-smoke.XXXXXX)
cleanup() { rm -rf -- "$sandbox"; }
trap cleanup EXIT INT TERM

fake_home="$sandbox/home"
cfg="$fake_home/.config/opencode"
mkdir -p "$cfg/agents" "$cfg/skills" "$cfg/commands"

repo_link="$cfg/goblin-logic-manager"
agent_link="$cfg/agents/goblin-logic-manager.md"
skill_link="$cfg/skills/goblin-chunk-compact"
command_link="$cfg/commands/goblin-close.md"

ln -s "$root" "$repo_link"
ln -s "$root/.opencode/agents/goblin-logic-manager.md" "$agent_link"
ln -s "$root/.opencode/skills/goblin-chunk-compact" "$skill_link"
ln -s "$root/.opencode/commands/goblin-close.md" "$command_link"

expect_target() {
  link=$1
  target=$2
  got=$(readlink -f "$link") || {
    echo "FAIL  unreadable symlink: $link" >&2
    exit 1
  }
  want=$(readlink -f "$target") || {
    echo "FAIL  unreadable source target: $target" >&2
    exit 1
  }
  [ "$got" = "$want" ] || {
    echo "FAIL  symlink target mismatch: $link -> $got (wanted $want)" >&2
    exit 1
  }
}

expect_target "$repo_link" "$root"
expect_target "$agent_link" "$root/.opencode/agents/goblin-logic-manager.md"
expect_target "$skill_link" "$root/.opencode/skills/goblin-chunk-compact"
expect_target "$command_link" "$root/.opencode/commands/goblin-close.md"

[ -f "$agent_link" ] || { echo "FAIL  agent link not readable" >&2; exit 1; }
[ -f "$skill_link/SKILL.md" ] || { echo "FAIL  skill link not readable" >&2; exit 1; }
[ -f "$command_link" ] || { echo "FAIL  command link not readable" >&2; exit 1; }

echo "PASS  isolated full-runtime symlink layout resolves exactly"

rm "$command_link" "$skill_link" "$agent_link" "$repo_link"

[ -e "$repo_link" ] && { echo "FAIL  repo link survived rollback" >&2; exit 1; }
[ -e "$agent_link" ] && { echo "FAIL  agent link survived rollback" >&2; exit 1; }
[ -e "$skill_link" ] && { echo "FAIL  skill link survived rollback" >&2; exit 1; }
[ -e "$command_link" ] && { echo "FAIL  command link survived rollback" >&2; exit 1; }

[ -f "$root/README.md" ] || { echo "FAIL  rollback damaged source repository" >&2; exit 1; }

echo "PASS  isolated rollback removes links without touching source"
