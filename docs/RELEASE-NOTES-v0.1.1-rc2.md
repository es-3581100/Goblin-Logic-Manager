# Goblin-Logic-Manager v0.1.1-rc2

## Skill-aware actor runtime candidate

This candidate adds a model-neutral routing layer for the user's current OpenCode skill collection while preserving GLM-5.3 as the pioneer model profile.

### Added

- `skill-registry.json` with canonical routing metadata for current skills.
- `docs/SKILL-ROUTING.md` covering when, where, and how Goblin should load each skill.
- `scripts/skill-preflight.py`, a read-only checker for global installed skills/frontmatter.
- one-primary + one-support maximum to avoid context-heavy skill soup.
- explicit-only protection for `i-have-adhd` and `mr-meeseeks`.
- legacy demotion of `make-build-ledger` behind `dynamic-build-ledger`.
- compatibility gating for supplied `research-module` and `zero-review-graph` versions that declare OpenCode V2/specialized requirements.
- closeout precedence that selects `update-ledger-compact` for initialized authorized DBL projects and `goblin-chunk-compact` as the fallback.

### Skill families routed

Planning/research, project governance, shared memory, compaction/continuity, active project review, public release finalization, Builder Testimony, deterministic workspace snapshots, graph-first Go/Rust review, local AI runtime optimization, prompt formalization, OpenCode skill/plugin creation, and local repo bootstrap.

### Non-routable pack contents

Installer kits, aggregate ZIPs, Skill Tree indexes/embedding data, and Builder#2 state/test/reference artifacts remain reference/distribution material rather than callable skill IDs.

### Authority invariant

A skill can change *how* Goblin performs an already-authorized task. It cannot create additional edit, network, Git, credential, publication, destructive, or scope authority.
