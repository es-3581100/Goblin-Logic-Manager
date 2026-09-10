# Adding a Model Family

Do not begin by copying `models/glm-5.3.md`.

A new adapter should be justified by observed behavior.

## 1. Reserve the family

Add a `reserved` registry entry if one does not already exist.

Do not set an OpenCode model ID yet unless you know the exact provider route you intend to support.

## 2. Establish a baseline

Run the model against representative Goblin work:

- focused repo inspection
- small code repair
- dependency decision
- Gradle/Android failure diagnosis
- browser/extension task
- Linux/Xubuntu integration
- UI implementation from an existing theme
- final verification report

Capture actual failures, not vibes.

## 3. Classify model-sensitive problems

Ask whether the failure belongs in:

- the stable Goblin core;
- the model overlay;
- provider configuration;
- the task/project itself.

Do not put provider-specific hacks into the core.

## 4. Write the smallest overlay

Good overlay rules are narrow and observable.

Examples:

- avoid a prompt construct the model systematically mishandles;
- simplify a delegation convention;
- require explicit parsing of tool errors before retry;
- change instruction ordering when evidence shows it matters.

Avoid duplicating the entire core.

## 5. Compare behavior

Use before/after runs.

The overlay should improve the target failure without degrading basic execution.

## 6. Promote carefully

Suggested states:

- `experimental` — usable for active testing;
- `ready` — repeatedly verified for intended workloads.

Keep model/provider IDs explicit.

## 7. Preserve expendability

A model adapter should be removable without changing:

- the development core;
- UI governance;
- Git safety;
- verification semantics;
- completion status meanings.

That is the architectural test.
