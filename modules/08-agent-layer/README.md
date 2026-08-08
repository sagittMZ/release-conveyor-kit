# Module 08 - agent-layer (the main one)

The layer through which the project owner's AI agent applies the kit. Whoever
provides the kit never gets access to somebody else's code: the owner gives
their own agent this module plus a readable copy of the kit.

## Contents

| File | What it is |
|---|---|
| AGENTS.md | The invariant rules for the agent (scope guard, secrets, idempotency, verification gates, honest reporting). Loaded as the session's CLAUDE.md/AGENTS.md |
| prompts/apply-kit.md | The master scenario: interview -> detection -> application in order -> end-to-end verification -> report -> handover to the owner |
| templates/REPORT.template.md | The skeleton of the final report (applied+verified / applied+unverified / manual steps / skipped / secrets) |

## How the owner starts the application

1. Get the kit (git clone, or a copy of the folder).
2. Open an agent session IN YOUR OWN project (for example `claude` in its root)
   and give it the kit as a readable directory.
3. The session prompt:

```
Apply the Release Conveyor Kit from <path-to-kit>.
Rules: <path-to-kit>/modules/08-agent-layer/AGENTS.md
Scenario: <path-to-kit>/modules/08-agent-layer/prompts/apply-kit.md
Work in branch conveyor-kit. Start with Phase 0 (interview).
```

4. Answer the interview questions; after that the agent works on its own, and
   the manual steps (secrets, store consoles) arrive as a list at the end.

## Module application order (baked into AGENTS.md)

ci-core -> secrets -> staging -> smoke-e2e -> monitoring -> mobile-build ->
store-deploy. CI and secret hygiene first, because everything else rides on
them; mobile and stores last, because they have the longest owner-side loops.

## Origin

This module was ADDED by the kit in full (the donor has no equivalent, though
the "rules + scenario + report" pattern is close in spirit to the donor's .ai/
agents). It is verified by applying the kit to a clean skeleton.

## Verification checklist

See [checklist.md](checklist.md).
