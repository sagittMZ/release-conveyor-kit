---
id: recurring-to-skill
phase: automate
category: automate
roles: []
needs: []
module: null
---

## Prompt

```
create a /{name} skill for this project that {steps}
```

Slots: `name` = ship; `steps` = runs the linter and the tests, then drafts a
commit message.

## Why it works

The steps are named once and become a command. Rung 3 of the escalation ladder:
a chain you have repeated three times should not be typed a fourth.

## How to escalate it

A skill in `.claude/skills/` is committed to the repo, so the command reaches
everyone. The next rung, a hook, is for when the action must happen always and
without being asked.
