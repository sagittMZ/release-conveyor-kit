---
id: codebase-overview
phase: discover
category: understand
roles: []
needs: []
module: null
---

## Prompt

```
give me an overview of this codebase: architecture, key directories and how the
parts connect
```

## Why it works

You describe what you want to learn, not which files to read. The agent walks
the project itself and returns the whole picture (pattern 1: outcome, not
steps).

## How to escalate it

Run `/init` so the result settles into CLAUDE.md and every new session starts
with that context.
