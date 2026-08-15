# Module 12 - memory-consolidation-lite

A file-based equivalent of dreaming on the stack already in use (bash + Claude
Code), with no cloud and no paid jobs. It periodically distills raw material
(session snapshots + the memory index + .ai/ + usage) into structured insights,
so memory does not just accumulate as raw sediment. It closes the main gap of
file-based memory: it piles up and never gets revisited.

## Origin

Added by the kit - this module has no donor. Verified by dogfooding: the
collection script runs against this repository's own session history, and the
safety rules below (never clobber hand-written memory, raw material outside
the git tree) were earned in that use, not derived in theory.

## The flow (cheap, reviewable)

1. **Collection (bash, zero cost):** `consolidate.sh` gathers the scattered
   sources into one `material-<date>.md` file in the project's PRIVATE zone,
   outside the git tree, following the pattern of the memory directory. One
   placement rule for every project and platform (Linux/macOS/Windows):
   `<claude-config>/projects/<enc>/consolidation/`, with the same base as Claude
   Code itself (`CLAUDE_CONFIG_DIR`, otherwise `~/.claude`). It does no
   distillation of its own.
2. **Distillation (inside the current session):** `/consolidate-memory` reads
   the material and, following `DISTILL_RUBRIC.md`, writes a PROPOSED diff,
   `DRAFT-<date>.md`, into the same private directory (Add / Update /
   Conflicts). It is not a separate paid run - it works inside a session that is
   already going.
3. **Acceptance (by hand):** the owner reads the DRAFT and merges what they
   accept into MEMORY.md and .ai/ themselves. Nothing is ever written to the
   live files automatically.

## Safety (never clobber what was written by hand)

- Output goes only to the private zone
  `<claude-config>/projects/<enc>/consolidation/`, so the raw material
  (snapshots, prompts; in health projects, PHI) physically cannot reach the git
  tree. The `.gitignore` entry for `docs/consolidation/` remains as insurance
  against a `CONSOLIDATE_OUT_DIR` override pointing back inside. `--with-prompts`
  is an explicit opt-in, and the resulting file gets a PHI warning in its header.
- The live MEMORY.md, memory files and .ai/ are never rewritten automatically.
- Conflicts with hand-written records go into their own section for the owner to
  decide, rather than being "fixed".
- Relative dates are converted to absolute ones.

## Running it

```
bash modules/12-memory-consolidation/consolidate.sh [--days N] [--with-prompts]
```

Then, in a session: `/consolidate-memory`.

Env: `MEMORY_DIR` (the project's memory directory, derived from the repo path by
default), `CONSOLIDATE_OUT_DIR` (where to write the raw material; the project's
private zone by default), `CONSOLIDATE_DAYS` (the window, 7 by default).

## Moving between machines and platforms

The raw material and the DRAFT are REPRODUCIBLE artifacts: material is
regathered from the transcripts with one command, and an unaccepted DRAFT does
not have to survive a move. The only durable thing is the accepted distillate
(MEMORY.md / .ai/), and that lives in the project itself and travels with the
repository. So changing platform or project path (which changes `<enc>`) loses
nothing of value - just run consolidate.sh again on the new machine.

## Cadence (without a paid cron)

Two triggers:

- calling `/consolidate-memory` by hand at the end of a large block, or when
  the snapshots and MEMORY.md have grown;
- a reminder at the end of `/session-wrap` ("time to consolidate?") - just text.

## Contents

| File | What it is |
|---|---|
| consolidate.sh | Deterministic collection of raw material -> <claude-config>/projects/<enc>/consolidation/material-<date>.md |
| DISTILL_RUBRIC.md | The distillation rules: atomicity, dedup, categories, never clobber hand-written records |
| checklist.md | Verification |

The `/consolidate-memory` command lives in `modules/09-prompt-library/commands/`,
because commands have one home.

Transcripts are read through the shared `lib-transcripts.sh` (module 09), the
same as evals and the digest.
