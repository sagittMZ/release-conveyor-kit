---
description: Kickoff prompt for a new session - handing over context
argument-hint: <what to take next, optional>
---
Assemble an executable kickoff prompt for a FRESH agent session that will
continue this work from a clean context. Include: what is already done (briefly,
with commits), what is deferred and why, which block to take next
($ARGUMENTS if a priority is given), links to the docs and roles that matter
(.ai/, docs/). The
prompt must be self-sufficient - a new agent gets into context without reading
the whole history.

Output the prompt here in chat; if the project has docs/NEW_SESSION_PROMPT.md,
offer to update it with this prompt.

This is not a state snapshot (that is /session-wrap) and not a feature plan
(that is /impl-plan) - it is handing work across a session boundary.
