# Changelog

## 0.1.1 — 2026-09-10

- Promoted the skill-aware actor runtime after live OpenCode 1.18.30 field verification.
- Made native OpenCode summarize a non-authoritative compatibility probe.
- Added mandatory independent cold-session re-ground as the continuity release gate.
- Raised live model waits to the field-proven 300s inner / 310s outer runtime boundary.
- Verified `COMPACT_READY` from the assistant response rather than the durable file.
- Prevented known-denied global-registry/external-directory probes in the smoke task.
- Preserved native summarize HTTP status/body as diagnostic evidence.
- Field result: native summarize HTTP 500 WARN; cold-session `RE_GROUNDED` PASS; checkpoint hash unchanged; zero unauthorized writes.

## 0.1.1-rc3 — 2026-09-10

- Hardened live OpenCode smoke against HTTP false positives.
- Added deny-by-default permissions for the live smoke's temporary project.
- Added durable-message verification for post-compaction `RE_GROUNDED`.
- Added isolated four-symlink install/rollback smoke.
- Added kill escalation to long bounded waits.

## 0.1.1-rc2 — 2026-09-10

- Added model-neutral skill/actor routing with a one-primary + one-support maximum.
- Added `skill-registry.json` and `docs/SKILL-ROUTING.md` from the supplied current skill pack.
- Added read-only `scripts/skill-preflight.py` for canonical installed-skill discovery/frontmatter checks.
- Added routing for planning, research, DBL/Go-Wiki, compaction, review/release, Builder Testimony, snapshots, local-AI optimization, prompt formalization, OpenCode skill/plugin creation, and repo bootstrap.
- Marked `i-have-adhd` and `mr-meeseeks` explicit-only; marked `make-build-ledger` legacy behind `dynamic-build-ledger`.
- Marked V2/specialized `research-module` and `zero-review-graph` routes conditional on runtime/tool compatibility.
- Updated Goblin closeout precedence: `update-ledger-compact` for initialized authorized DBL; `goblin-chunk-compact` otherwise.

## 0.1.1-rc1 — 2026-09-10

- Added `goblin-chunk-compact` closeout skill.
- Added `/goblin-close` command for deliberate chunk boundaries.
- Added model-neutral externalize-before-compacting behavior.
- Added runtime-side bounded waits for long-running commands.
- Added OpenCode 1.18.30 compatibility notes and config example.
- Added structural and live end-to-end smoke scripts.
- Corrected GLM pioneer binding to `tokenrouter/z-ai/glm-5.3-free`.

## 0.1.0 — 2026-09-09

- Created Goblin-Logic-Manager.
- Extracted stable model-neutral development behavior into `core/developer-core.md`.
- Added GLM-5.3 as the pioneer model overlay.
- Added a model registry with future Qwen, DeepSeek, and Kimi slots.
- Added reproducible OpenCode-agent rendering.
- Added consistency verification.
- Preserved Android, Chrome/browser, Xubuntu/Linux, small-app, UI-governance, Git-safety, and evidence-first verification rules.
