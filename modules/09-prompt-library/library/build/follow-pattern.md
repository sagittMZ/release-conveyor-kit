---
id: follow-pattern
phase: build
category: implement
roles: []
needs: []
module: null
---

## Prompt

```
look at how {example} is implemented to learn the pattern, then build {new} the
same way
```

Slots: `example` = the GitHub webhook handler; `new` = the Stripe webhook
handler.

## Why it works

You point at code you already like (pattern 3: a reference). Without a
reference the agent writes to generic best practices; with one it writes to your
project's conventions.

## How to escalate it

Ask the agent to record the pattern it used in CLAUDE.md - future sessions will
follow it without needing the reference.
