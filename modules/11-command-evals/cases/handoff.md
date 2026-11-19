# Cases: /handoff

Handing work across a session boundary. Every case is given as text: what makes
a handoff good is whether a fresh agent could act on it, and that is visible in
the prompt itself. The neighbouring commands are the trap - a handoff that turns
into a state snapshot is `/session-wrap`, and one that turns into a feature plan
is `/impl-plan`.

## case: the next block is named

input: |
  Work so far, in an invented project: block A (the import pipeline) is done and
  merged in commits 4f21a9c and 8ce0102; block B (deduplication) is written but
  not reviewed; block C (the reporting screen) has not been started, and it is
  waiting on a decision about which chart library to use. Two things are
  deferred: the migration off the legacy parser, until block B is reviewed, and
  the load test, until there is staging.

  Take block B next.
expect:

- the result is a kickoff prompt addressed to a fresh session, self-sufficient without the history behind it
- what is done is stated with its commits, what is deferred is stated with the condition that would unblock it
- the named priority, block B, is what the next session is told to take
- it points at where the relevant material lives, so the new agent knows what to read
avoid:
- producing a state snapshot of the current session instead of a handover
- planning the implementation of block B in phases

## case: no priority given

input: |
  The same history as above, with no instruction about what to take next.
expect:

- a priority is derived from the history and stated as the agent's own choice rather than as the owner's instruction, or the question is asked outright
- the rest of the handoff still holds - done, deferred, where to read
avoid:
- handing over a prompt that leaves the next step unnamed
- picking a priority and presenting it as though it had been decided

## case: reviews cross the boundary

input: |
  The same history as in the first case, plus two reviews. Block B was sent to
  the neighbouring session for review an hour ago and no answer has come yet.
  An earlier review of block A came back with two findings: one is fixed in
  commit 8ce0102, the other (a missing test for empty input) is not done.

  Take block B next.
expect:

- the handoff lists the review of block B as sent and still waiting, with who it was sent to
- the unfixed finding from the review of block A is carried over as open work, the fixed one is not
- the rest of the handoff still holds - done, deferred, the named priority
avoid:
- dropping the open finding because block A counts as done
- leaving out the review that has not answered yet
