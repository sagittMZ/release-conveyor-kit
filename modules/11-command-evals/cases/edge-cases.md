# Cases: /edge-cases

Invented examples, so they are safe to publish. Each case gives the input
(`$ARGUMENTS`) plus the properties a good answer must have (expect) and the
anti-properties it must not have (avoid).

## case: export a report to PDF

input: exporting a user's monthly report to PDF from a button
expect:

- the answer is grouped by category (input and validation, network and loading, permissions, empty or boundary data, races and retries)
- an empty state is covered (no data for the period)
- a permissions case is covered (requesting somebody else's report)
- a network or timeout case is covered for the file generation
avoid:
- writing code or a concrete implementation
- drifting into the happy path with no errors and no empty states

## case: avatar upload

input: uploading a profile avatar with cropping
expect:

- boundary data (file too large, unsupported format)
- network and loading (upload interrupted, retry)
- an empty or default state (no avatar)
avoid:
- code

## case: no feature given

input:
expect:

- asks what feature the list should be built for
avoid:
- producing a generic list that would fit any feature at all
- picking a feature of its own and building the list for that
