# Master prompt: apply the Release Conveyor Kit

Use together with AGENTS.md (rules). Input: path to the kit checkout and the
target project root. Work in a feature branch `conveyor-kit`.

## Phase 0 - Interview (owner answers, agent records)

Ask only what cannot be detected from the repo; write all answers into
`conveyor.config.json` (created from the kit's conveyor.config.example.json):

1. App display name, production URL (if deployed), Vercel project exists?
2. Mobile: Android needed? iOS needed? Existing store accounts
   (Google Play / Apple Developer / Codemagic)?
3. Supabase: project-ref of prod; is there a staging project (variant A) or
   free tier only (variant B)?
4. Monitoring: Sentry account exists? Telegram bot for alerts wanted?
5. The app's main user-facing entity (for smoke CRUD) and main authenticated
   route.
6. Permission to add data-testid attributes if smoke selectors need them.

## Phase 1 - Detect

Inspect the repo and record findings in the config + a short stack report:

- package.json: vite? react? typescript? capacitor deps? vitest? eslint?
  scripts lint/build/test present?
- Dirs: android/, ios/, supabase/, tests/, .github/workflows/ (list existing
  workflows - they matter for idempotent merge).
- vercel.json / vite.config / capacitor.config presence and app id.
- import.meta.env.* usage -> the env variable inventory.

Out-of-scope marker (see AGENTS.md scope guard): next.config.*, app router,
flutter/, react-native deps, .gitlab-ci.yml as the only CI.

## Phase 2 - Apply modules

Order and gating per AGENTS.md. For each module:

1. Read `modules/<NN>/README.md` section "Применение".
2. Copy/merge templates, replace every `# conveyor:` marker and TODO(kit)
   using conveyor.config.json values and Phase 1 findings.
3. Run the local part of `checklist.md`.
4. Commit `kit: apply module <NN-name>` (one commit per module).
5. Append the module outcome to the report draft.

Module 09 (prompt-library) has no templates to merge. Copy:
`PATTERNS.md` + `library/` -> target `docs/prompts/library/` (copy-paste menu;
if `docs/prompts/` already exists, do NOT overwrite it - the menu goes into the
separate `library/` subdir, merge only), and `commands/*.md` -> target
`.claude/commands/` (invocable slash commands). Add a pointer section to the
target AI_WORKFLOW.md listing docs/prompts/library/ and the command names (fall
back to CLAUDE.md if AI_WORKFLOW.md is missing). See
modules/09-prompt-library/ROLLOUT.md for the ready intro prompt. Then run its
checklist.md as usual.

## Phase 3 - Verify pipeline end-to-end

1. Local: lint, unit (if tests exist), build, playwright smoke.
2. Push the branch, open a PR; wait for GitHub Actions: CI green, Secret Scan
   green, e2e via workflow_dispatch green.
3. Mobile: android-build.yml via workflow_dispatch (needs owner secrets) -
   if secrets are missing, mark "blocked: owner must add secrets" and go on.
4. Sentry test error (module 05 checklist) if DSN provided.
5. Codemagic / stores: not verifiable by the agent - emit owner step lists
   (modules 02/03).

## Phase 4 - Report

Fill `templates/REPORT.template.md` -> `CONVEYOR-REPORT.md` in the target
repo. Sections: applied+verified / applied+unverified / owner manual steps /
skipped / secrets the owner still has to create. Honest reporting rule applies.

## Phase 5 - Handover

Tell the owner: where the report is, which PR to review, the exact ordered
list of their manual steps (secrets first - everything blocked unblocks after).
