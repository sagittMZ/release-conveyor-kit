# Release Conveyor Kit - Agent Rules

You are an AI agent applying the Release Conveyor Kit to an existing
React/TS + Vite (+ Capacitor) + Supabase project. These rules override your
defaults for the whole application session.

## Scope guard

Supported stack v0: React/TS + Vite + Capacitor + Supabase + Vercel +
GitHub Actions + Codemagic. If detection (see prompts/apply-kit.md, phase 1)
shows a different stack (Next.js, Flutter, RN, other CI), STOP and report
"out of scope v0" - do not improvise a port.

## Hard rules

1. **Config-first.** Every name/id/path comes from `conveyor.config.json` in
   the target project root. No config - create it from
   `conveyor.config.example.json` during the interview, then proceed.
2. **Secrets are placeholders.** Never write a real key, password, DSN or
   keystore into the repo. Real values go only into GitHub Secrets / Codemagic
   env groups / Vercel env / the owner's password manager - and they are
   entered by the OWNER, you only name the secret and where it goes.
3. **Idempotency.** Before creating any file, check if it exists. Existing
   workflow/config with the same purpose: merge the missing pieces, do not
   duplicate and do not overwrite blindly. Re-running the kit on an already
   converted project must be a no-op.
4. **Do not touch application code.** Infra layer only: workflows, configs,
   tests/e2e, supabase migrations from the kit. The single allowed exception:
   Sentry init injection in main.tsx strictly per module 05 template.
   Adding data-testid attributes for smoke tests is allowed only with the
   owner's explicit OK.
5. **Verification gates.** A module counts as applied only when its
   checklist.md passes. Nothing is pushed to the main branch without a green
   check. Use a feature branch + PR.
6. **Degrade to instruction.** Anything you cannot do (store consoles,
   payments, signing, UI-only settings) - produce a short numbered step list
   for the owner. Never silently skip.
7. **Honest reporting.** In the final report every item is one of:
   applied+verified / applied+NOT verified (say why) / manual step for owner /
   skipped (say why). Never imitate verification.

## Module order

01-ci-core -> 06-secrets -> 04-staging -> 07-smoke-e2e -> 05-monitoring ->
02-mobile-build -> 03-store-deploy -> 09-prompt-library. Rationale: CI and
secret hygiene first (everything else rides on them), mobile/store last
(longest owner-side loops), prompt library at the end (pure copy, no gating).
Modules disabled in conveyor.config (e.g. mobile.ios.enabled=false) are skipped
with a note in the report.

Exception to the scope guard: 09-prompt-library is stack-agnostic. If the
target stack is out of scope v0, still offer to apply module 09 alone before
stopping.

## Where things are

- Module templates: `modules/<NN-name>/templates/`
- Per-module application notes: `modules/<NN-name>/README.md` (the "Application" section)
- Per-module verification: `modules/<NN-name>/checklist.md`
- Master scenario: `prompts/apply-kit.md`
- Report skeleton: `templates/REPORT.template.md`
