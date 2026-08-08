---
id: spec-interview
phase: design
category: plan
roles: [pm]
needs: []
module: null
---

## Prompt

```
I want to build {feature}. interview me about implementation, UX, edge cases and
trade-offs until everything is covered, then write the spec to SPEC.md
```

Slot: `feature` = per-workspace request limits.

## Why it works

You ask to be interviewed instead of writing the spec yourself. The agent asks
structured questions until the requirements are complete and records the result
in a file - the spec comes out of a conversation rather than a blank page.

## How to escalate it

Save your interview questions as a /spec skill, so every spec starts the same
way.
