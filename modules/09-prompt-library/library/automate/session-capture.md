---
id: session-capture
phase: automate
category: automate
roles: [pm, docs]
needs: []
module: null
---

## Prompt

```
summarize what we did this session, and suggest what of it belongs in CLAUDE.md
```

## Why it works

You ask while it is still fresh. The agent knows what it had to figure out
along the way and proposes the notes that let the next session start from
somewhere other than zero.

## How to escalate it

Make it the closing ritual of every working session (in the owner's projects
that role is played by the docs/.session-current.md snapshot - this prompt
complements it with suggestions aimed specifically at CLAUDE.md).
