---
id: delete-impact
phase: discover
category: understand
roles: []
needs: []
module: null
---

## Prompt

```
what breaks if I delete {target}?
```

Slot: `target` = the retryWithBackoff helper.

## Why it works

Ask BEFORE deleting. The list of call sites and consequences immediately shows
what you are dealing with: a one-line cleanup, or a change that needs
coordinating.

## How to escalate it

Not needed - a one-off question asked in place.
