---
id: copy-sweep
phase: build
category: implement
roles: [design, docs, marketing]
needs: []
module: null
---

## Prompt

```
find every place where we say "{copy}" or something close to it, show me each
one in context, then update them all to "{new}". leave tests and the changelog
alone
```

Slots: `copy` = Sign up for free; `new` = Start your trial.

## Why it works

You ask for variants and say what to skip. The agent finds phrasings a literal
search would miss and leaves test fixtures and history untouched - so you only
review the copy users actually see.

## How to escalate it

Not needed - a one-off operation; if the replacements become regular, turn it
into a skill.
