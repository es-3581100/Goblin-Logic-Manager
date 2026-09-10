from pathlib import Path

p = Path("README.md")
s = p.read_text(encoding="utf-8")

marker = "## Recommended OpenCode setup: symlink, do not merge"
heading = "## Field-verified runtime smoke"

section = "\n".join([
    "## Field-verified runtime smoke",
    "",
    "Goblin-Logic-Manager v0.1.1 has been field-tested against:",
    "",
    "- OpenCode: `1.18.30`",
    "- Model route: `tokenrouter/z-ai/glm-5.3-free`",
    "",
    "### Local runtime smoke",
    "",
    "Run `./scripts/smoke-goblin-runtime.sh`.",
    "",
    "Verified:",
    "",
    "- generated Goblin agent",
    "- GLM model route",
    "- 22-skill routing",
    "- NO SKILL SOUP invariant",
    "- ledger-aware closeout precedence",
    "- isolated install and rollback",
    "- bounded wait behavior",
    "- OpenCode agent discovery",
    "- OpenCode model discovery",
    "",
    "### Live continuity smoke",
    "",
    "Run `./scripts/smoke-opencode-live.sh`.",
    "",
    "The live smoke uses real model calls and may consume provider quota.",
    "",
    "Field verification proved:",
    "",
    "- live Goblin closeout: PASS",
    "- 300-second inner timeout / 310-second outer guard: PASS",
    "- durable chunk return: PASS",
    "- `COMPACT_READY`: PASS",
    "- independent cold session: PASS",
    "- cold-session `RE_GROUNDED`: PASS",
    "- durable chunk-return hash unchanged: PASS",
    "- unauthorized writes: 0",
    "",
    "### Continuity authority",
    "",
    "**Goblin owns continuity. OpenCode compaction is an optimization.**",
    "",
    "The governing runtime rules are:",
    "",
    "- **EXTERNALIZE BEFORE COMPACTING.**",
    "- **WAIT IN THE RUNTIME, NOT IN THE MODEL.**",
    "",
    "The mandatory continuity release gate is `COLD_SESSION_REGROUND=PASS`.",
    "",
    "Native OpenCode compaction is a best-effort compatibility feature and is not the authority for Goblin context continuity.",
    "",
    "### OpenCode 1.18.30 compatibility note",
    "",
    "During field verification, OpenCode's native summarize endpoint returned HTTP 500 when used with `tokenrouter/z-ai/glm-5.3-free`.",
    "",
    "Goblin classified this as `NATIVE_COMPACTION_COMPATIBILITY=KNOWN_FAILURE` and continued through its durable recovery path.",
    "",
    "A completely independent OpenCode session then recovered successfully from the durable chunk return and returned `RE_GROUNDED` without modifying the checkpoint or making unauthorized writes.",
    "",
    "Current release status: **FIELD_VERIFIED_RELEASE_PASS**.",
    "",
])

if heading in s:
    print("README already contains the field-verification section; no change made.")
elif marker in s:
    s = s.replace(marker, section + "\n" + marker, 1)
    p.write_text(s, encoding="utf-8")
    print("PASS: README.md updated")
else:
    p.write_text(s.rstrip() + "\n\n" + section, encoding="utf-8")
    print("PASS: README.md updated (section appended)")
