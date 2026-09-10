---
name: goblin-chunk-compact
description: Close a coherent development chunk, externalize durable state, and prepare the session for safe OpenCode compaction without treating the summary as authority.
---

# Goblin Chunk Compact

Use this skill at the end of a meaningful implementation chunk or before an expected context reset/compaction boundary **when the richer project-ledger path is not applicable**.

If an initialized Dynamic Build Ledger exists, ledger mutation is already authorized, and `update-ledger-compact` is available, use `update-ledger-compact` instead. Do not run both closeout skills merely to duplicate the same checkpoint.

## Authority

The active task envelope, project `AGENTS.md`, project-local ledger/checkpoint, repository state, source code, and tests remain authoritative.

This skill summarizes and externalizes context. It does not create new authority.

## Closeout order

1. Finish the narrowest relevant verification.
2. Reconcile claims against repository/runtime evidence.
3. Produce the compact chunk return below.
4. Persist irreplaceable state in the project's existing ledger/checkpoint system when one exists and the active task authorizes writing it.
5. If no project ledger exists, write a small project-local checkpoint only when the task permits it; otherwise keep the return in-session.
6. End with `COMPACT_READY` only after durable state is safe enough to survive complete active-context loss.
7. Treat OpenCode native compaction as a best-effort context-size optimization. It is not the continuity authority.
8. After compaction, session replacement, or any fresh-context boundary, re-ground from authoritative project state before continuing.

Do not invent a fake `/compact` tool call. Do not claim compaction occurred unless OpenCode/runtime evidence confirms it. If native compaction fails, do not loop retries: retain the durable checkpoint and continue through a fresh-context re-ground when needed.

## Chunk return

Keep it terse and factual:

```text
STATUS:
OBJECTIVE:
COMPLETED:
FILES_CREATED:
FILES_MODIFIED:
VERIFICATION:
OBSERVED_RUNTIME_STATE:
DECISIONS:
DEVIATIONS:
SKILLS_USED:
BLOCKERS:
KNOWN_UNVERIFIED:
AUTHORITY_POINTERS:
NEXT_SAFE_ACTION:
```

Preserve exact paths, revisions, identifiers, commands, error strings, and validation outcomes when they matter to continuation.

Do not dump large logs merely to preserve context.

## Re-grounding after compaction or context loss

Use this order after native compaction, a fresh session, or any other context-loss boundary:

```text
active task envelope
→ project AGENTS.md
→ project ledger/checkpoint
→ repository status
→ relevant source/tests
→ compacted session summary
```

If the compacted summary conflicts with authoritative project evidence, authoritative project evidence wins. A cold-session recovery from durable state is stronger evidence of continuity than successful native compaction alone.

## Principles

**GOBLIN OWNS CONTINUITY. OPENCode COMPACTION IS AN OPTIMIZATION.**

**EXTERNALIZE BEFORE COMPACTING.**
