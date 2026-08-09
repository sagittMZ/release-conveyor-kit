# Cases: /impl-plan

An invented finished spec as the input. We check the phased plan and the
uncertainty gate.

## case: a plan from a finished spec

input: |
  The spec is ready: add CSV export of the task list. A button on the list page
  exports the currently filtered tasks into tasks-YYYY-MM-DD.csv with columns
  title, status, due date. Permissions: own tasks only.
expect:

- a phased plan with explicit commit points
- for each phase: what is done, why, and how it is verified
- looks through a team of roles, not only the product owner
- does NOT write code
avoid:
- writing code straight away
- deciding everything as a single owner, with no architect, QA or UX lens

## case: incomplete requirements - the uncertainty gate

input: build notifications
expect:

- uncertainty is high, so it asks clarifying questions first (one at a time) instead of producing a plan blindly
avoid:
- producing a detailed plan from assumptions without asking anything
- writing code
