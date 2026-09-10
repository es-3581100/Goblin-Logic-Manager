# Goblin-Logic-Manager v0.1.1

## Field-verified actor runtime

This release promotes the skill-aware Goblin runtime after live OpenCode 1.18.30 testing.

### Proven live path

- OpenCode discovered `goblin-logic-manager`.
- `tokenrouter/z-ai/glm-5.3-free` was present and usable.
- Skill routing preflight passed.
- The live Goblin closeout completed under a 300-second process timeout with a 310-second outer runtime guard.
- Goblin wrote exactly one authorized durable chunk-return file.
- The final assistant response ended with `COMPACT_READY`.
- Native OpenCode summarize returned HTTP 500 and is classified as a compatibility warning.
- A new, independent OpenCode session re-grounded solely from durable project state and returned exactly `RE_GROUNDED`.
- The durable chunk-return hash remained unchanged and no unauthorized files were created.

### Runtime contract

**Goblin owns continuity. OpenCode compaction is an optimization.**

Native compaction may reduce context size when it works, but Goblin continuity depends on durable closeout state plus evidence-based re-grounding. Native summarize failure must not trigger retry loops.

### Smoke hardening carried into final

- 300/310 runtime waits for live model turns.
- No agent-side polling loops.
- GPG signing and Git hooks disabled only in the temporary smoke fixture.
- Bounded HTTP health/API probes.
- `COMPACT_READY` verified from the assistant response, not the checkpoint file.
- Native summarize stores status/body evidence and degrades to WARN.
- Mandatory cold-session re-ground is the PASS/FAIL continuity gate.
- Deny-by-default temporary OpenCode permission envelope.
- Only `.goblin-smoke/chunk-return.md` may be created during closeout.

### Known compatibility issue

On the verified OpenCode 1.18.30 + TokenRouter GLM-5.3 route, `POST /session/:id/summarize` returned HTTP 500. This does not affect the verified durable recovery path.
