# Verification checklist - module 01 ci-core

Locally, before pushing:

- [ ] The YAML is valid: `npx --yes yaml-lint .github/workflows/ci.yml`, or
      `actionlint` if it is installed.
- [ ] `npm run lint` passes locally.
- [ ] `npx vitest run` passes locally (or the unit job is disabled with a TODO).
- [ ] `npm run build` passes locally.

In CI, after pushing the branch or opening the PR:

- [ ] The "CI" workflow ran on the PR.
- [ ] All three jobs (Lint, Unit tests, Build) are green.
- [ ] The run summary shows the "N/N tests passed" report.
- [ ] A repeat run uses the npm cache (the setup-node step says "Cache
      restored").
- [ ] (Optional) In Settings -> Branches, add required status checks: Lint,
      Unit tests (Vitest), Build.
