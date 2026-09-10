---
description: Close the current Goblin work chunk and prepare it for safe compaction
agent: goblin-logic-manager
---

Close the current coherent work chunk now.

Routing: if an initialized Dynamic Build Ledger exists, ledger mutation is authorized, and `update-ledger-compact` is available, load that skill. Otherwise load `goblin-chunk-compact`. Never run both merely to duplicate the same checkpoint.

Run only the narrow verification needed to support the current claims. Preserve authoritative project state before summarizing. Use an existing project-local ledger/checkpoint if one exists and the current task permits writing it.

Return the skill's compact chunk report and end with `COMPACT_READY` only when the chunk can survive lossy context compaction.

Do not claim that OpenCode `/compact` ran. Native compaction is a runtime/session operation.

Additional task-specific closeout constraints:

$ARGUMENTS
