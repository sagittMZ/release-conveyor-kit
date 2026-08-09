# Cases: /spec

Invented examples. `/spec` runs an interview and only then writes SPEC.md, so we
score the command's FIRST answer, the start of the interview, not the final
spec.

## case: dark theme

input: add a dark theme to the app settings
expect:

- the command STARTS an interview: it asks clarifying questions
- questions come one at a time (not a dump of fifteen at once)
- implementation, UX, edge cases and trade-offs get covered as it goes
avoid:
- writing code immediately
- producing a finished SPEC.md without asking anything

## case: no argument

input:
expect:

- asks what to specify and starts the interview
avoid:
- silently doing nothing, or writing code
