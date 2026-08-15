---
description: Distill collected memory raw material into a reviewable DRAFT
---
The project's consolidation directory (one rule across all projects and
platforms): `<claude-config>/projects/<enc>/consolidation/`, where the base is
`$CLAUDE_CONFIG_DIR` or `~/.claude`, and `<enc>` is the absolute path of the
repo root with `/` replaced by `-` (the same scheme memory uses; compute it
with:
`echo "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/$(git rev-parse --show-toplevel | sed 's#/#-#g')/consolidation"`).
Raw material and DRAFTs live there, OUTSIDE the git tree: they contain private
snapshots and prompts.

Read the most recent material-<date>.md from that directory (if there is none,
say to run modules/12-memory-consolidation/consolidate.sh, which collects the
raw material). Distill it into structured insights strictly per
modules/12-memory-consolidation/DISTILL_RUBRIC.md.

Present the result as a PROPOSED diff in DRAFT-<date>.md in the same directory,
with sections "Add", "Update" and "Conflicts": what to write into memory or
.ai/, what to merge with what is already there, and where it disagrees with
existing records. Convert relative dates to absolute ones, deduplicate against
what already exists, cite the source. State the path of the created DRAFT
explicitly in your answer.

Do not change MEMORY.md, the memory files or .ai/ directly - only the DRAFT.
I will read the DRAFT and accept or merge it by hand.
