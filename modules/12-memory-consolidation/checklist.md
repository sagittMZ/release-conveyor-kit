# Verification checklist: 12-memory-consolidation

1. `bash modules/12-memory-consolidation/consolidate.sh --days 7` creates
   `material-<date>.md` in `<claude-config>/projects/<enc>/consolidation/` (the
   script prints the path) and exits without errors.
2. The material contains the sections: session snapshots (the current one plus
   history from git), the MEMORY.md index (when available), an inventory of
   .ai/, and a usage summary.
3. The artifacts stay out of git: the raw material lives outside the working
   tree (`git status` is clean); `docs/consolidation/` is in `.gitignore` as
   insurance against an override.
4. `/consolidate-memory` in a session reads the freshest material and writes
   ONLY `DRAFT-<date>.md` into the same private directory (sections Add /
   Update / Conflicts); MEMORY.md, the memory files and .ai/ are untouched.
5. The DRAFT follows DISTILL_RUBRIC.md: atomic insights, categories, dedup
   against what exists, relative dates converted to absolute ones, and a source
   on every item.
6. The reminder works: `/session-wrap` offers consolidation at the end (without
   running it).
