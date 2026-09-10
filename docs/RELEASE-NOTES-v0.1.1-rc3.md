# Goblin-Logic-Manager v0.1.1-rc3

## Pre-install audit candidate

rc3 is a smoke-harness hardening release. It does not broaden Goblin's runtime authority.

### Audit fixes

- Reject HTTP 4xx/5xx in the live OpenCode smoke with `curl --fail-with-body`.
- Require `/global/health` to return `healthy: true`.
- Require `/session/:id/summarize` to return JSON `true`.
- Remove brittle `set -e` failure paths that could bypass recovery reporting.
- Verify `RE_GROUNDED` from the durable assistant message rather than grepping raw CLI events.
- Hash the durable chunk return before/after re-grounding and require it to remain unchanged.
- Run the live model smoke under a temporary deny-by-default permission policy.
- Deny external-directory access during the live smoke.
- Restrict the smoke to one authorized output file.
- Add `smoke-install-layout.sh` to prove the four-symlink install and rollback in a temporary fake OpenCode config tree.
- Add `timeout --kill-after=5s` escalation to bounded waits.
- Make documented rollback remove only verified symlinks, never a same-named real file/directory.

### Current OpenCode contract checked

OpenCode v1.18.30 remains the latest release at audit time. Stable V1-style docs support the global agent, skill, and command paths used by Goblin, `opencode run --attach ... --command ...`, `GET /global/health`, `POST /session/:id/summarize`, and `compaction: { auto, prune, reserved }`.

### Scope

This candidate is safe to install by symlink after the offline pre-install gate passes. The provider-backed compaction/re-ground smoke still requires the user's real OpenCode installation and configured GLM route, so it is run after linking.
