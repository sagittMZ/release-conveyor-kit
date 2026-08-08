# Module 07 - smoke-e2e

A minimal Playwright smoke suite: 7 scenarios (startup, session, navigation,
create/edit/delete of the main entity, logout) shipped as a template with TODO
markers.

## Origin

- **From the working donor (proven):** playwright.config (timeouts,
  storageState, webServer, blob and html reporters), auth.setup through the
  Supabase REST API (no UI - faster and more stable), the spec patterns, browser
  caching keyed by the Playwright version, and the disabled auto-trigger that
  saves Actions minutes.
- **Changed by the kit:** the suite is cut from about 22 specs down to a smoke
  core; one shard instead of two (the donor's blob-merge machinery is not
  needed); the CRUD scenarios are generic scaffolds with TODO(kit) markers whose
  selectors the applying agent MUST adapt.

## Files (everything goes to the target project's tests/e2e/)

| File | Where |
|---|---|
| templates/playwright.config.ts | tests/e2e/playwright.config.ts |
| templates/tests/auth.setup.ts | tests/e2e/tests/auth.setup.ts |
| templates/tests/smoke.spec.ts | tests/e2e/tests/smoke.spec.ts |
| templates/package.json | tests/e2e/package.json |
| templates/.env.test.example | tests/e2e/.env.test.example |
| templates/e2e.yml | .github/workflows/e2e.yml |

Plus tests/e2e/.gitignore: `.auth/`, `playwright-report/`, `test-results/`,
`.env.test`, `node_modules/`.

## Dependencies on other modules

- Module 04 (staging): the QA account and the cleanup_e2e_data RPC (the prepare
  job in e2e.yml calls it; if module 04 was not applied, remove the prepare job
  and its `needs`).
- Secrets: QA_TEST_EMAIL, QA_TEST_PASSWORD, VITE_SUPABASE_URL,
  VITE_SUPABASE_ANON_KEY.

## Application (for the agent)

1. Create tests/e2e/ as a standalone package, run `npm i` inside it and
   `npx playwright install chromium` (Playwright 1.5x also needs
   chromium-headless-shell - the same call installs it, in CI via --with-deps).
2. You MUST exclude tests/e2e from vitest, otherwise the CI unit job fails on
   the playwright specs (a lesson from the kit's own self-test): in
   vite.config.ts use `import { defineConfig } from 'vitest/config'` and
   `test: { exclude: ['node_modules', 'dist', 'tests/e2e/**/*'] }` (the donor's
   pattern).
3. Work through EVERY TODO(kit) in auth.setup.ts and smoke.spec.ts: the main
   authenticated route, a public landing element, 2-4 navigation routes, and the
   CRUD selectors of the main entity. Detection: routes from the react-router
   config, the entity from the main user-facing table.
4. If the UI has no data-testid attributes, add them narrowly (create/delete
   buttons, the title input) - that is an infrastructure edit, allowed with the
   owner's agreement.
5. Mobile-first app: switch the project to Pixel 5 (the commented block in the
   config - the donor's pattern).
6. Local run: `cd tests/e2e && npx playwright test` (the dev server starts
   itself through webServer).

## Verification checklist

See [checklist.md](checklist.md).
