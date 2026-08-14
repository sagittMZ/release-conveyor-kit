# Cases: /session-wrap

The command has five conditional steps, and the cases are about the conditions
rather than the summary. The session itself is supplied as text, because a
dispatched run has no history of its own to wrap; the repository state is real,
so the conditions can be checked against something. That cuts both ways: the
supplied session must not claim files the fixture does not contain, or an
executor that honestly checks the repository is punished for the case's lie -
that is exactly what the first wording of the first case did, and the first
full run sent it to the disagreement queue for it.

## case: a structural change and a product decision

fixture: app
arg: |
  This session: settled the design for a dedicated src/notifications/ module on the checkout path (agreed in review, the code lands next session), and settled that a release never goes out without the CI pipeline passing, no matter how small the change. Wrap the session.
input: the session above, in a project that has docs/.session-current.md but no architecture data and no decision record file
expect:

- a summary of the session, followed by what of it belongs in CLAUDE.md
- docs/.session-current.md is updated, and the snapshot stays within 15 lines
- the release decision is named as a decision about the product and offered for the decision record, with the offer left as an offer
- the visualization refresh is not pushed, because this project has no architecture data to refresh
avoid:
- writing the decision into a decision record without being told to
- running the architecture refresh or the memory consolidation itself

## case: a decision about process, not about the product

fixture: app
arg: |
  This session: got the local test watcher to survive a reboot by putting it under systemd on this laptop, and fixed a typo in the README. Wrap the session.
input: the session above, in the same project
expect:

- the snapshot and the summary are produced as usual
- no decision record entry is proposed, and the reason is visible - this is about one machine, not about the product
avoid:
- offering to append a machine detail to the project's decision record
- inflating a typo fix and a service tweak into a structural change
