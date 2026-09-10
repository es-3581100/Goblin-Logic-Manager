#!/usr/bin/env python3
"""Consistency checks for Goblin-Logic-Manager."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import tempfile

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "model-registry.json"
CORE = ROOT / "core" / "developer-core.md"
DIST = ROOT / ".opencode" / "agents" / "goblin-logic-manager.md"
RENDER = ROOT / "scripts" / "render_agent.py"
SKILL_REGISTRY = ROOT / "skill-registry.json"
SKILL_ROUTING = ROOT / "docs" / "SKILL-ROUTING.md"
SKILL_PREFLIGHT = ROOT / "scripts" / "skill-preflight.py"
INSTALL_SMOKE = ROOT / "scripts" / "smoke-install-layout.sh"
LIVE_SMOKE = ROOT / "scripts" / "smoke-opencode-live.sh"


def fail(msg: str) -> None:
    raise SystemExit(f"FAIL: {msg}")


def main() -> int:
    if not CORE.is_file():
        fail("missing core/developer-core.md")

    registry = json.loads(REGISTRY.read_text(encoding="utf-8"))
    if registry.get("schema") != "goblin-logic-manager/model-registry/v1":
        fail("unexpected registry schema")

    profiles = registry.get("profiles", {})
    default = registry.get("default_profile")
    if default not in profiles:
        fail("default profile is missing")

    for name, profile in profiles.items():
        status = profile.get("status")
        if status in {"pioneer-ready", "ready", "experimental"}:
            if not profile.get("opencode_model"):
                fail(f"{name}: renderable profile missing opencode_model")
            overlay = profile.get("overlay")
            if not overlay:
                fail(f"{name}: renderable profile missing overlay")
            if not (ROOT / overlay).is_file():
                fail(f"{name}: overlay does not exist: {overlay}")
        elif status == "reserved":
            # Reserved profiles must not accidentally look production-ready.
            if profile.get("overlay") is not None:
                fail(f"{name}: reserved profile unexpectedly has overlay")
        else:
            fail(f"{name}: unknown status {status!r}")

    spec = importlib.util.spec_from_file_location("goblin_render", RENDER)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)

    if not SKILL_REGISTRY.is_file():
        fail("missing skill-registry.json")
    skill_registry = json.loads(SKILL_REGISTRY.read_text(encoding="utf-8"))
    if skill_registry.get("schema") != "goblin-logic-manager/skill-registry/v1":
        fail("unexpected skill registry schema")
    skills = skill_registry.get("skills", [])
    ids = [s.get("id") for s in skills]
    if not ids or any(not x for x in ids):
        fail("skill registry contains missing IDs")
    if len(ids) != len(set(ids)):
        fail("skill registry contains duplicate IDs")
    by_id = {s["id"]: s for s in skills}
    required = {
        "dynamic-build-ledger", "go-wiki-memory", "update-ledger-compact",
        "project-review-suggestions", "public-release-finalizer",
        "build-tt-handoff", "build-tt-adhd", "build-tt-rake",
        "workspace-snapshot", "local-ai-runtime-optimizer",
        "make-an-opencode-skill", "make-an-opencode-plugin",
        "goblin-chunk-compact",
    }
    missing = sorted(required - set(ids))
    if missing:
        fail(f"skill registry missing required routes: {missing}")
    if by_id.get("make-build-ledger", {}).get("status") != "legacy":
        fail("make-build-ledger must remain legacy")
    for explicit_id in ("i-have-adhd", "mr-meeseeks"):
        row = by_id.get(explicit_id)
        if not row or row.get("status") != "explicit-only" or row.get("auto_invoke") is not False:
            fail(f"{explicit_id} must remain explicit-only with auto_invoke=false")
    for conditional_id in ("research-module", "zero-review-graph"):
        if by_id.get(conditional_id, {}).get("status") != "conditional":
            fail(f"{conditional_id} must remain compatibility-gated")
    if not SKILL_ROUTING.is_file() or "NO SKILL SOUP" not in SKILL_ROUTING.read_text(encoding="utf-8"):
        fail("skill routing documentation missing core routing invariant")
    if not SKILL_PREFLIGHT.is_file():
        fail("missing scripts/skill-preflight.py")
    if not INSTALL_SMOKE.is_file():
        fail("missing scripts/smoke-install-layout.sh")
    if not LIVE_SMOKE.is_file():
        fail("missing scripts/smoke-opencode-live.sh")
    live_text = LIVE_SMOKE.read_text(encoding="utf-8")
    if "--fail-with-body" not in live_text:
        fail("live smoke must reject HTTP error responses")
    if '"external_directory": "deny"' not in live_text:
        fail("live smoke must deny external-directory access")
    if "COLD_SESSION_REGROUND=PASS" not in live_text:
        fail("live smoke must require cold-session continuity recovery")
    if "END_TO_END_GOBLIN_CONTINUITY_SMOKE" not in live_text:
        fail("live smoke must expose the final continuity gate")
    if '"$root/scripts/bounded-wait.sh" 300 10 --' not in live_text:
        fail("live smoke must use the field-proven 300/310 bounded wait")
    if "NATIVE_COMPACTION_COMPATIBILITY=KNOWN_FAILURE" not in live_text:
        fail("live smoke must keep native compaction failure non-authoritative")
    if "text.endswith('COMPACT_READY')" not in live_text:
        fail("live smoke must verify COMPACT_READY from assistant message")

    rendered = module.render(default)
    if not DIST.is_file():
        fail("generated OpenCode agent is missing")
    actual = DIST.read_text(encoding="utf-8")
    if actual != rendered:
        fail("generated OpenCode agent is stale; run scripts/render_agent.py")
    if "# Skill and Actor Routing" not in actual:
        fail("generated agent is missing skill-routing core")

    print(
        f"PASS: models={len(profiles)} default={default}; "
        f"skills={len(skills)} routed; generated agent is current"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
