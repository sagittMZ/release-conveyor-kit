---
description: Error states, empty states and edge cases for a feature
argument-hint: <the feature or flow>
---
For: $ARGUMENTS

List the error states, empty states and edge cases a happy-path implementation
usually misses. Group them by: input and validation, network and loading,
permissions and access, empty and boundary data, races and retries.
Do not write code - this is a checklist for design and tests.

If the project has .ai/QA_ENGINEER.md, check against it and honor its
requirements for test coverage and edge cases.

If the feature is not given, ask what to build the list for.
