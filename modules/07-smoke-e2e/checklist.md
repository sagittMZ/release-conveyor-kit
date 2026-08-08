# Verification checklist - module 07 smoke-e2e

Locally:

- [ ] No TODO(kit) markers are left in the templates.
- [ ] `npx playwright test` locally: setup is green (.auth/user.json created)
      and every smoke scenario passes.
- [ ] Test data is prefixed with E2E and disappears after the run or cleanup.
- [ ] tests/e2e/.gitignore covers .auth, the reports and .env.test.

In CI:

- [ ] The QA_* secrets exist; the E2E Smoke workflow (workflow_dispatch) is
      green.
- [ ] The prepare job ran (a 2xx cleanup status in the log).
- [ ] The playwright-report artifact downloads and opens.
- [ ] A repeat run hits the browser cache.
