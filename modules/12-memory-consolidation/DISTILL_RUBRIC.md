# DISTILL_RUBRIC - what a good memory distillate looks like

The rules by which `/consolidate-memory` turns raw material
(`material-<date>.md`) into a proposed diff (`DRAFT-<date>.md`). The owner reads
the DRAFT and merges it by hand.

## What to do

1. **Atomicity.** One insight is one fact. Do not glue unrelated things into a
   paragraph.
2. **Dedup.** If a fact is already in MEMORY.md or the memory files, do not
   duplicate it - propose an UPDATE to the existing record instead of a new one.
3. **Currency.** Convert relative dates ("yesterday", "last week") to absolute
   ones. Mark what went stale as stale; never delete it silently.
4. **Category.** Give every insight a type: user / feedback / project /
   reference. For feedback and project entries add "Why" and "How to apply".
5. **Links.** Put `[[name-of-another-record]]` links between related insights.
6. **Source.** For every insight, where it came from (a snapshot, a commit, a
   prompt), so the owner can verify it.

## What NOT to do

- **Do not clobber hand-written records.** Entries the owner wrote by hand are
  never rewritten. A conflict with one goes into its own "Conflicts" item rather
  than being "corrected".
- **Do not write to the live files.** The result goes only into
  DRAFT-<date>.md. Merging into MEMORY.md and .ai/ is manual, with the owner's
  knowledge.
- **Do not inflate.** Raw, one-off or already irrelevant things do not go into
  memory. Memory is for what outlives a session and cannot be derived from the
  code or git.
- **Do not invent.** No support in the raw material means it is not an insight.
  Guessing is not the job.

## The format of DRAFT-<date>.md

Three sections:
- **Add** - new insights (with category, source and links).
- **Update** - which existing records change, and how.
- **Conflicts** - where the distillate disagrees with current memory (for the
  owner to decide).
