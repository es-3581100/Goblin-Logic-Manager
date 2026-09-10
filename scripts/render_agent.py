#!/usr/bin/env python3
"""Render a Goblin-Logic-Manager OpenCode agent from core + model overlay."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "model-registry.json"
CORE = ROOT / "core" / "developer-core.md"
DEFAULT_OUTPUT = ROOT / ".opencode" / "agents" / "goblin-logic-manager.md"


def load_registry() -> dict:
    with REGISTRY.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def render(profile_name: str) -> str:
    registry = load_registry()
    profiles = registry["profiles"]
    if profile_name not in profiles:
        raise SystemExit(f"Unknown profile: {profile_name}")

    profile = profiles[profile_name]
    status = profile["status"]

    if status not in {"pioneer-ready", "ready", "experimental"}:
        raise SystemExit(
            f"Profile {profile_name!r} is {status!r}, not renderable. "
            "Add real model/provider configuration and tuning evidence first."
        )

    model_id = profile.get("opencode_model")
    overlay_rel = profile.get("overlay")
    if not model_id or not overlay_rel:
        raise SystemExit(f"Profile {profile_name!r} is missing model or overlay configuration.")

    overlay = ROOT / overlay_rel
    if not overlay.is_file():
        raise SystemExit(f"Overlay not found: {overlay}")

    core_text = CORE.read_text(encoding="utf-8").rstrip()
    overlay_text = overlay.read_text(encoding="utf-8").rstrip()

    description = (
        f"Goblin-Logic-Manager {profile['display_name']} developer agent for "
        "small apps, Android, Chrome/browser work, and Xubuntu/Linux"
    )

    return (
        "---\n"
        f"description: {description}\n"
        "mode: primary\n"
        f"model: {model_id}\n"
        "---\n\n"
        "# Goblin-Logic-Manager\n\n"
        f"Active model profile: **{profile['display_name']}** (`{profile_name}`)\n\n"
        "> Stable development behavior comes from the Goblin core. "
        "Model-specific behavior comes from a thin overlay.\n\n"
        f"{core_text}\n\n"
        "---\n\n"
        f"{overlay_text}\n"
    )


def main() -> int:
    registry = load_registry()
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--profile",
        default=registry["default_profile"],
        help="model profile from model-registry.json",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help="output OpenCode agent path",
    )
    args = parser.parse_args()

    text = render(args.profile)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(text, encoding="utf-8")
    print(f"rendered profile={args.profile} -> {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
