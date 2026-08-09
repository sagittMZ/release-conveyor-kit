---
id: release-notes
phase: ship
category: release
roles: [pm, docs, marketing]
needs: []
module: 03-store-deploy
---

## Prompt

```
compare {from} and {to} and write release notes grouped into sections: features,
fixes, breaking changes
```

Slots: `from` = v1.2.0; `to` = v1.3.0 (tags or commits).

## Why it works

Two reference points plus the structure of the answer (patterns 4 and 6). The
agent reads the git log between them and produces a draft you only have to edit

- for a store's "What's new" (module 03) that is 90% of the work.

## How to escalate it

Save it as the /release-notes skill - it ships with the kit as one of the 14
commands.
