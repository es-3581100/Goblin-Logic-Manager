# OpenCode 1.18.30 runtime compatibility

Goblin's current stable target is OpenCode 1.18.30.

## Stable paths

- Global agent: `~/.config/opencode/agents/<name>.md`
- Project agent: `.opencode/agents/<name>.md`
- Global skill: `~/.config/opencode/skills/<id>/SKILL.md`
- Project skill: `.opencode/skills/<id>/SKILL.md`

## Stable 1.18.x compaction configuration

```jsonc
{
  "compaction": {
    "auto": true,
    "prune": false,
    "reserved": 10000
  }
}
```

OpenCode V2 documentation uses a different compaction schema (`keep.tokens` and
`buffer`) and a different permissions schema. Do not mix those V2 fields into a
1.18.x configuration.

## Goblin closeout behavior

`goblin-chunk-compact` prepares durable state for compaction. It does not fake
or emulate the TUI `/compact` command.

Use OpenCode automatic compaction for normal context pressure. For a deliberate
manual boundary, run `/goblin-close`, inspect `COMPACT_READY`, then invoke
`/compact` in the TUI.

This separation is intentional because compaction is lossy and current 1.18.x
reports include edge cases involving oversized compaction prompts and reasoning-
only summaries on GLM-family routes.

## Bounded waits

Use `scripts/bounded-wait.sh` for long-running foreground verification that
would otherwise tempt the agent into repeated polling.

Example:

```bash
./scripts/bounded-wait.sh 300 10 -- ./gradlew test
```

The child receives a 300-second hard timeout. The shell waits on its PID with a
310-second outer guard and returns immediately if the child finishes early.

**WAIT IN THE RUNTIME, NOT IN THE MODEL.**


## Skill routing

Goblin's routing registry is model-neutral and may be exposed through the recommended repo symlink at:

```text
~/.config/opencode/goblin-logic-manager/skill-registry.json
```

The registry is not an OpenCode skill registry replacement. It selects a canonical installed skill ID; OpenCode remains responsible for loading the skill itself. Goblin defaults to no skill, permits one primary plus one supporting skill, and returns to the core agent between skill handoffs.

Run `python3 scripts/skill-preflight.py` for read-only installed-skill discovery.


## rc3 smoke hardening

The live smoke treats HTTP status as evidence: `curl --fail-with-body` rejects 4xx/5xx responses, `/global/health` must return `healthy: true`, and `/session/:id/summarize` must return JSON `true`.

The live agent turn runs inside a temporary project with a deny-by-default OpenCode permission policy. Only narrow project reads, Git inspection, `goblin-chunk-compact`, and creation of `.goblin-smoke/chunk-return.md` are allowed. External-directory access and unrelated skills/actions are denied.

Post-compaction re-grounding is verified from durable session messages; the harness does not count prompt text echoed in raw CLI JSON as proof.

## v0.1.1 field result: continuity survives native summarize failure

A live field smoke on OpenCode 1.18.30 using `tokenrouter/z-ai/glm-5.3-free` produced this split result:

```text
Goblin closeout                  PASS
durable chunk return            PASS
COMPACT_READY response          PASS
native /session/:id/summarize  WARN — HTTP 500
fresh independent session       PASS
RE_GROUNDED                     PASS
checkpoint hash invariant       PASS
unauthorized writes             0
```

Therefore native summarize is retained as a compatibility probe only. The release continuity gate is the cold-session recovery test. A native compaction failure must not trigger retry loops or invalidate a durable Goblin closeout.

**Goblin owns continuity. OpenCode compaction is an optimization.**
