---
id: product-flow
phase: discover
category: understand
roles: [pm]
needs: []
module: null
---

## Prompt

```
I am a {role}. walk me through what happens when a user {action} - from the UI
to the result
```

Slots: `role` = product manager; `action` = clicks "Export to PDF".

## Why it works

Naming the role sets the altitude of the answer: the agent explains what the
product actually does, straight from the sources - without you going to an
engineer and without you reading the code.

## How to escalate it

If you always want answers at that altitude, set an output style so every
session replies there by default.
