---
id: tests-write-run-fix
phase: build
category: test
roles: []
needs: []
module: null
---

## Prompt

```
write tests for {path}, run them and fix every failure
```

Slot: `path` = src/lib/parsers/feed.ts.

## Why it works

"Write + run + fix" in one prompt gives the agent a self-check loop (pattern 2):
it iterates until green instead of stopping for instructions after each step.

## How to escalate it

Make sure the project's test command is recorded in CLAUDE.md (in conveyor
projects that is vitest; `/init` picks it up automatically).
