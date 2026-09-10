# Design

Goblin-Logic-Manager uses a deliberately narrow model-adapter design.

## Stable layer

`core/developer-core.md` owns behavior that should remain useful across model families:

- inspect before editing
- evidence over confidence
- small vertical slices
- dependency restraint
- Git/workspace safety
- Android verification discipline
- Chrome/browser boundary awareness
- Xubuntu/XDG-friendly Linux behavior
- anti-generic-UI rules
- accessibility
- factual completion reports

Changing model families should not require rewriting these principles.

## Model layer

`models/<family>.md` owns only prompt behavior that demonstrably differs by model family.

Examples:

- ceremony tolerance
- preferred instruction structure
- known tool-call formatting failure modes
- delegation sensitivity
- context-packing quirks
- retry behavior

The overlay must stay thin.

## Registry layer

`model-registry.json` declares whether a model family is:

- `pioneer-ready`
- `ready`
- `experimental`
- `reserved`

Only renderable statuses may point to an OpenCode model ID and overlay.

A `reserved` entry is architectural intent, not support.

## Why this boundary matters

The point is to make the **model expendable without making the development philosophy disposable**.

If another model becomes cheaper, smarter, locally runnable, or better for a task, Goblin should be able to adopt it by replacing a small tuning layer rather than cloning and drifting the whole agent.
