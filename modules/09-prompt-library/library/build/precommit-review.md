---
id: precommit-review
phase: build
category: review
roles: []
needs: []
module: null
---

## Prompt

```
review my uncommitted changes and flag anything risky before I commit
```

## Why it works

Problems are caught while they are cheap. The agent reads the changed files in
full rather than only the diff lines, so it sees what a quick self-review
misses.

## How to escalate it

`/code-review` runs the same check in one command; on the CI side the same role
is played by module 01 (lint + typecheck + tests on every PR).
