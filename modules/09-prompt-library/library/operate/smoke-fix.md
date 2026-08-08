---
id: smoke-fix
phase: operate
category: debug
roles: []
needs: []
module: 07-smoke-e2e
---

## Prompt

```
the smoke test {test} is failing - find out why and fix it. if the test itself is
broken, fix the test; if it caught a real bug, fix the code and tell me so
explicitly
```

Slot: `test` = auth.spec.ts "login with valid credentials".

## Why it works

You describe the symptom without knowing which file is broken. The agent runs
the test, sees the failure with its own eyes and follows the trace into the
sources. The "test or code" fork is named up front - otherwise the agent
quietly bends the test to fit the broken behavior.

The smoke suite is installed by module 07 (Playwright, 5-8 scenarios).

## How to escalate it

A rule in CLAUDE.md: a failing smoke test is never fixed by weakening an
assertion without explicit agreement.
