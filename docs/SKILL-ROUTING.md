# Goblin Skill Routing

Goblin treats skills as **specialized behavior modules**, not as authority and not as a bag of prompts to load all at once.

This routing map is derived from the supplied current skill pack. Goblin does not vendor those global skills; it discovers and uses the installed canonical skill IDs when available.

## Prime rules

1. **NO SKILL SOUP.** Default to no skill. Load one primary skill only when it materially improves the current phase. At most one supporting context/continuity skill may accompany it.
2. **Task authority stays outside the skill.** A skill may constrain or refine method, but it never grants edit, delete, network, credential, publication, Git, or scope authority that the active task/project did not grant.
3. **Use canonical IDs.** Do not route to ZIP names, installer kits, builder-state dumps, or the Skill Tree index.
4. **Check availability before dependence.** Missing optional skills are reported and bypassed, not installed or hunted for broadly.
5. **Respect explicit-only skills.** `i-have-adhd`, `mr-meeseeks`, and explicit-only research flows are never activated merely because their keywords appear.
6. **Prefer current over legacy.** `dynamic-build-ledger` supersedes `make-build-ledger` for normal work.
7. **Compatibility is evidence.** Skills declaring OpenCode V2 or specialized tool requirements must be proven loadable/usable in the current OpenCode runtime before becoming a dependency.
8. **Return to the core.** After the specialized task is complete, resume Goblin's normal inspect → implement → verify loop rather than keeping the skill active indefinitely.

## Runtime location

With the recommended symlink setup, Goblin can read its routing metadata from:

```text
~/.config/opencode/goblin-logic-manager/skill-registry.json
```

Use the registry to choose a canonical skill ID, then load that skill through OpenCode's native skill-loading mechanism. The registry does not replace the skill and does not install anything.

Do not recursively scan `~/.config/opencode/skills/` on every task. Resolve the route first, then check only the selected skill unless the user explicitly asks for a skill inventory/preflight.

Do not invoke ZIPs, installer kits, Skill Tree indexes, or builder-state artifacts as skills.

## Skill receipts

For material skill runs, preserve a terse execution receipt when it improves continuity:

```text
SKILL_USED: <canonical-id>
WHY: <why this specialist was needed>
AUTHORITY_BOUNDARY: <read-only/advisory/authorized mutation scope>
RESULT: <compact result>
VERIFIED_AGAINST: <repo/tests/runtime/ledger evidence>
HANDOFF: <core or next independently justified phase>
```

This is a recall/provenance aid, not a new authority surface.

## Actor routing loop

```text
understand task
    ↓
identify current phase/problem
    ↓
can Goblin core handle it directly? ── yes ──→ use no skill
    │ no / specialist materially helps
    ↓
select exact canonical skill ID
    ↓
check availability + compatibility + authority
    ↓
load ONE primary skill
    ↓
optionally load ONE support skill
    ↓
execute bounded skill workflow
    ↓
verify output against repo/runtime evidence
    ↓
return to Goblin core
```

## Routing table

| Situation | Primary skill | Supporting skill / note |
|---|---|---|
| Explore an idea, possibilities, UI directions, light research | `planning-brainstorm-light-research` | `go-wiki-memory` only if prior context materially helps |
| Turn a selected idea into an engineering plan/feasibility case | `dev-planning-research` | DBL/Go-Wiki bounded context when present |
| Initialize/operate durable project governance | `dynamic-build-ledger` | Never substitute shared memory for authority |
| Recall shared prior project context | none or current primary | `go-wiki-memory` read-only support |
| Build a durable research corpus/module | `research-module` | Explicit/conditional; verify V2 compatibility first |
| Snapshot a ZIP/repo/tree without executing it | `workspace-snapshot` | Can support handoff/review |
| Review/debug Go/Rust/ZeroLang via graph | `zero-review-graph` | Conditional on compatibility/tools |
| Audit active project quality / find goblins | `project-review-suggestions` | Advisory; do not silently fix findings |
| Final public-release readiness | `public-release-finalizer` | Does not itself publish |
| Formal handoff to another builder/model/session | `build-tt-handoff` | Convergent testimony |
| Preserve loose architectural intuition before context loss | `build-tt-adhd` | Divergent, non-authoritative testimony |
| Capture hindsight/scars after substantial work | `build-tt-rake` | Strict read-only retrospective |
| Context/phase close with an initialized authorized DBL | `update-ledger-compact` | Preferred over Goblin fallback |
| Context/phase close without usable DBL | `goblin-chunk-compact` | Goblin-shipped fallback |
| Optimize local AI runtime performance | `local-ai-runtime-optimizer` | Observe first; mutations approval-gated |
| Formalize a loose dev prompt into a one-shot packet | `prompt-dev-formalization` | Do not use for ordinary prompt touch-ups |
| Build/repair an OpenCode skill | `make-an-opencode-skill` | `make-an-opencode-skill-kit` is packaging, not the runtime ID |
| Build/repair an OpenCode plugin/custom tool | `make-an-opencode-plugin` | Decide skill vs tool vs plugin first |
| Bootstrap/adopt a new local repo | `make-a-new-local-repo` | Only within explicit repo/network authority |
| ADHD response mode | `i-have-adhd` | **Explicit-only**; persists until user disables it |
| Mr. Meeseeks comedy/persona mode | `mr-meeseeks` | **Explicit-only** |
| Legacy build-ledger compatibility | `make-build-ledger` | Legacy only; prefer `dynamic-build-ledger` |

## Common sequences

### New project

```text
planning-brainstorm-light-research
    ↓ selected idea
dev-planning-research
    ↓ project becomes real
dynamic-build-ledger
    ↓ implementation
Goblin core
    ↓ checkpoint
update-ledger-compact
```

Not every project needs every step. Do not manufacture ceremony.

### Existing project implementation

```text
Goblin core inspection
    ↓
implementation + native toolchain verification
    ↓
project-review-suggestions (only when a review adds value)
    ↓
update-ledger-compact OR goblin-chunk-compact
```

### Release

```text
project-review-suggestions
    ↓ repairs explicitly authorized and completed
public-release-finalizer
    ↓ explicit publication authority elsewhere
publish/release action
```

### Model/session handoff

Use `build-tt-handoff` when another builder actually needs a durable transfer. Use `build-tt-adhd` only when valuable intuition would otherwise be lost. Use `build-tt-rake` after the work when hindsight itself is the artifact.

## Continuity precedence

At chunk closeout:

```text
initialized DBL + ledger mutation authorized + update-ledger-compact available
    → use update-ledger-compact
otherwise
    → use goblin-chunk-compact
```

Never run both merely to duplicate the same checkpoint.

## Skill output is not truth by itself

After any skill returns, reconcile important claims against the applicable authority chain:

```text
active task/project instructions
→ repository/config/tests/runtime evidence
→ admitted project ledger state
→ specialized skill output
→ optional shared memory / generated summaries
```

A skill can discover or structure evidence. It cannot promote speculation, retrieved memory, or generated prose into implementation truth.
