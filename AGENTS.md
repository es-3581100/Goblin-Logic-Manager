# Project Development Instructions

This repository is developed with an evidence-first, validation-gated style.

## Core rule

**NO EXPANSION WITHOUT VALIDATION.**

Before adding pages, frameworks, dependencies, component families, services, abstractions, navigation systems, or decorative systems:

1. inspect what already exists;
2. identify authoritative project sources;
3. verify the current state;
4. determine whether expansion is actually needed;
5. repair current-scope violations before broadening the design when practical.

Validation result:

- `PASS` — current scope is coherent enough to expand.
- `HOLD` — direction is valid, but current scope needs repair first.
- `DENY` — proposed work contradicts authoritative sources, fabricates behavior/data, harms usability, or adds unjustified complexity.

## Development loop

1. Orient with the smallest relevant set of files.
2. Check repo status and preserve unrelated work.
3. Let existing code, tests, build files, design tokens, screenshots, and project conventions outrank assumptions.
4. Implement the smallest coherent vertical slice.
5. Run focused verification before broad verification.
6. Report only what the evidence supports.

Prefer direct implementation over speculative architecture.

## Architecture

- Existing architecture first.
- Local-first when remote infrastructure is unnecessary.
- Minimize dependencies and moving parts.
- Avoid framework-inside-framework designs.
- Add abstractions only for a real boundary or proven duplication.
- Keep persisted data explicit and versionable.
- Prefer reversible changes.
- Preserve compatibility unless a break is explicitly requested.

## Small apps

- Optimize for easy launch, inspection, and removal.
- Keep dependency count low.
- Keep configuration discoverable.
- Use obvious platform-appropriate storage.
- Provide useful empty/loading/error/unavailable states.
- Do not use fake live-looking telemetry.
- Avoid mandatory cloud services unless they are fundamental to the product.

## Android

- Respect the existing Gradle/Android architecture.
- Prefer Kotlin for new Android code unless the repository establishes another language.
- Do not upgrade Gradle, AGP, Kotlin, JDK, NDK, Compose, or major dependencies without a verified reason.
- Preserve application ID, namespace, SDK/ABI choices, signing expectations, and permission boundaries unless explicitly changing them.
- Keep Android permissions minimal.
- Verify compilation, relevant tests, resources/manifest, and packaging.
- If no device/emulator is available, distinguish build verification from launch verification.

## Chrome / browser

First distinguish web app, PWA, extension, locally hosted browser tool, and browser automation.

For extensions:

- prefer Manifest V3 where appropriate;
- keep permissions and host permissions narrow;
- separate background/service-worker, content, and UI responsibilities;
- respect CSP;
- do not use remote executable code or `eval`;
- validate storage and message boundaries.

For browser-dependent behavior, use a real runtime check when possible rather than claiming UI/runtime correctness from source inspection alone.

## Linux / Xubuntu

- Target standards-friendly Linux behavior compatible with Xubuntu/XFCE.
- Do not assume GNOME or KDE.
- Prefer XDG paths.
- Prefer user-local installation when system-wide installation is unnecessary.
- Do not use `sudo` casually.
- Keep privileged changes narrow and explicit.
- Do not modify global shell configuration when project/user-local configuration works.
- Use standards-compatible `.desktop` integration when needed.
- Quote shell variables and handle paths safely.

## UI governance

Existing approved themes, palette tokens, component vocabularies, screenshots, and mockups are authoritative.

Do not approximate existing colors from memory.

Avoid generic model-generated UI defaults:

- generic blue/gray dashboards
- generic purple gradients
- endless rounded cards
- pill controls everywhere
- arbitrary glow
- decorative gradients with no purpose
- identical spacing everywhere
- marketing hero layouts inside operational tools
- fake telemetry or system health
- animation merely because it is available

A tool should look usable before it looks marketable.

Whitespace must communicate hierarchy. Developer controls may be compact; primary work areas should breathe.

Interactive controls should communicate applicable hover, focus, active, selected, disabled, loading, and error states.

Use depth, grouping, typography, surface contrast, and spacing before surrounding every component with a border.

A panel/card must represent a real structural unit. A pill/chip must represent a real tag/filter/state/category job.

Never invent RAM figures, agent activity, model usage, latency, task counts, token totals, success rates, notifications, history, or health data. Show unavailable/unknown/disconnected/waiting states or omit the value.

## Accessibility

Preserve:

- practical contrast
- keyboard usability
- visible focus
- readable text
- selected/disabled-state clarity
- practical pointer/touch targets
- reduced-motion support
- semantic structure where supported

A prettier UI that is harder to operate is a regression.

## Dependencies

Before adding one, identify the concrete problem it solves and whether the existing stack already solves it.

Do not add a dependency just to avoid a few lines of straightforward code.

Do not perform broad dependency upgrades unless requested or required by a verified incompatibility.

## Git safety

Before editing, inspect branch/status and preserve unrelated user work.

Do not destructively reset, discard unrelated changes, force push, rewrite history, or delete broad trees unless explicitly authorized by the task.

Do not commit or push unless requested or clearly part of the active workflow.

## Verification

Use evidence, not confidence.

Typical ladder:

1. syntax/format
2. focused compile/type-check
3. focused unit tests
4. broader project tests
5. integration checks
6. package/build artifact
7. runtime smoke test
8. device/browser verification when relevant

Run only the stages needed to support the final claim.

When something fails, read the exact error and fix one causal layer at a time. Do not randomly upgrade dependencies.

## Completion report

Use a compact factual report:

`status:`
`summary:`
`files_touched:`
`verification:`
`limitations:`
`next:`

Statuses:

- `PASS`
- `PARTIAL`
- `BLOCKED`
- `HOLD`

Never report `PASS` for behavior that materially depends on runtime/device/browser execution when that execution was not actually verified.

## Skill routing

Use installed OpenCode skills selectively. Default to the core agent; load at most one primary skill plus one materially useful support skill. Skills refine workflow but never expand task authority.

Key routes: brainstorming → `planning-brainstorm-light-research`; engineering planning → `dev-planning-research`; project governance → `dynamic-build-ledger`; read-only shared memory → `go-wiki-memory`; active review → `project-review-suggestions`; release gate → `public-release-finalizer`; model/session handoff → `build-tt-handoff`; deterministic source snapshot → `workspace-snapshot`; local AI tuning → `local-ai-runtime-optimizer`; OpenCode skill/plugin creation → the matching maker skill.

At chunk closeout prefer `update-ledger-compact` when an initialized authorized Dynamic Build Ledger exists; otherwise use `goblin-chunk-compact`. `i-have-adhd` and `mr-meeseeks` are explicit-only. `make-build-ledger` is legacy behind `dynamic-build-ledger`. Verify compatibility before depending on supplied skills that declare OpenCode V2.

See `docs/SKILL-ROUTING.md`.

## Chunk closeout and compaction

At the end of a coherent implementation chunk, use the `goblin-chunk-compact` skill when available. Verify first, externalize durable state second, compact third, then re-ground from project authority.

Do not fake a `/compact` invocation. OpenCode's native automatic/manual compaction remains a runtime/session operation.

**EXTERNALIZE BEFORE COMPACTING.**

## Long-running command waits

For long-running commands with explicit timeouts, prefer one bounded runtime wait over repeated agent polling. Use the repository's `scripts/bounded-wait.sh` when appropriate.

Do not add an extra sleep after a foreground tool call that already waited synchronously.

**WAIT IN THE RUNTIME, NOT IN THE MODEL.**
