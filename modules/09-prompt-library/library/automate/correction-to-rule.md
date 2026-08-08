---
id: correction-to-rule
phase: automate
category: automate
roles: []
needs: []
module: null
---

## Prompt

```
you are {mistake} again. add a rule to CLAUDE.md so this stops
```

Slot: `mistake` = using default exports when the project has settled on named
exports.

## Why it works

A correction in chat dies with the session. A rule in CLAUDE.md is read by every
new session and reaches everyone working on the project through git. This is
rung 2 of the escalation ladder (PATTERNS.md).

## How to escalate it

This is the escalation. Every few weeks, open /memory and throw out the rules
that went stale.
