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

Output the prompt here in chat. Then, if the project has
docs/NEW_SESSION_PROMPT.md, REWRITE that file with this handoff - do not merely
offer to. That file is what the next session reads first, and a handoff that
lives only in a chat log leaves it pointing at a stale priority. Keep the file's
own structure and its standing sections (invariants, machine state, working
rules); replace what the session changed - status, the commits, the current
priority and what is deferred. If the project has no such file, offer to create
it.

This is not a state snapshot (that is /session-wrap) and not a feature plan
(that is /impl-plan) - it is handing work across a session boundary.
