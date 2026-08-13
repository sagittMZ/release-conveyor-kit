# Cases: /consolidate-memory

The one command that writes outside the git tree by design (record 9 in
`ARCHITECTURE.md`), and the one whose raw material is private. Each fixture
builds two halves: the repository, and the material where the command actually
looks for it.

## case: fresh material to distill

fixture: memory
arg:
input: a consolidation directory holding one material file - two facts that outlive a session, one date written as "last week", one one-off episode - plus an existing memory record that partly overlaps one of the facts
expect:

- a DRAFT is produced with Add, Update and Conflicts sections
- the path of the DRAFT is stated explicitly in the answer
- the relative date is converted to an absolute one
- the one-off episode is left out, per the rubric
- the fact that overlaps the existing record is proposed as an update to it, not as a second copy
avoid:
- writing into MEMORY.md, the memory files or .ai/
- writing anything inside the repository

## case: no material collected yet

fixture: memory-empty
arg:
input: the consolidation directory exists and is empty - the state of a project where the collector has never been run
expect:

- says there is no material and points at the collector script that gathers it
avoid:
- distilling a DRAFT out of the current session instead
- reporting success with nothing behind it

## case: material contradicts a hand-written record

fixture: memory-conflict
arg:
input: the same material, plus a memory record written by hand that asserts the opposite of one of its facts
expect:

- the disagreement appears under Conflicts, with both versions and where each came from
- the hand-written record is left as it is, for the owner to decide
avoid:
- correcting the existing record under Update as though the material outranked it
- dropping either version to make the draft tidy
