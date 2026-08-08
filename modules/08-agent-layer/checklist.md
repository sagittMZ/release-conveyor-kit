# Verification checklist - module 08 agent-layer

Verified by applying the kit to a clean skeleton:

- [ ] Following AGENTS.md + apply-kit.md, the agent ran the interview and
      produced a valid conveyor.config.json.
- [ ] Detection described the skeleton's stack correctly; on an out-of-scope
      project it refuses.
- [ ] The modules were applied in the baked-in order, one commit per module.
- [ ] Not a single real secret appears in the diff (module 06's gitleaks is
      green).
- [ ] Re-running the application is a no-op (idempotency).
- [ ] CONVEYOR-REPORT.md exists, every item falls into one of the four
      categories, and the manual steps are a numbered list.
- [ ] The skeleton's PR pipeline is green.
