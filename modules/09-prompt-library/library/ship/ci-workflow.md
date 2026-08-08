---
id: ci-workflow
phase: ship
category: release
roles: [ops]
needs: []
module: 01-ci-core
---

## Prompt

```
write a GitHub Actions workflow that {steps} on every push to {branch}
```

Slots: `steps` = runs the tests and deploys to staging; `branch` = main.

## Why it works

You describe when it runs and what it does - the YAML is generated for your
project's build and test commands rather than from an abstract template.

In conveyor projects, look at `.github/workflows/` first: the base CI is already
installed by module 01, and this prompt is for ADDITIONAL workflows. Remind the
agent about idempotency: extend what exists, do not duplicate it.

## How to escalate it

A rule in CLAUDE.md: new workflows do not duplicate existing jobs, they reuse
them through workflow_call.
