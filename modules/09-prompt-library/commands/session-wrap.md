---
description: Session summary + CLAUDE.md suggestions + snapshot update
---
Summarize what we did this session. Then:

1. Suggest what of it belongs in CLAUDE.md (rules, commands, project
   conventions) so the next session does not start from zero.
2. If the project has docs/.session-current.md, update it with a snapshot
   (15 lines max: what was done, current state, next step, blockers).
3. If snapshots or MEMORY.md have grown noticeably, suggest running memory
   consolidation (/consolidate-memory), but do not run it yourself.
4. If the session changed the project's STRUCTURE (new or removed modules,
   scripts, workflows, major components - not ordinary edits inside files) and
   the project has docs/arch/arch-data.json, suggest refreshing the
   architecture visualization (/arch-viz), but do not run it yourself.
5. If the session settled a DECISION about the product itself (how it is built,
   what it guarantees, what it deliberately refuses to do), name it and offer to
   append it to the project's decision record - ARCHITECTURE.md or docs/adr/ -
   as a new numbered entry with context, alternatives and consequences, written
   in the repository's canonical language. Records are append-only: a decision
   that stops being true gets superseded by a new entry that says so, never
   rewritten. Decisions about process, one machine or one person's other
   projects do not belong there. Do not write the entry without my word.
