# Module 01 - ci-core

The PR pipeline: lint + unit tests + build on every push and PR to the main
branches. npm caching, concurrency cancellation of stale runs, a test summary.

## Origin

- **From the working donor (proven):** the `unit` job - the exact logic of the
  donor's unit-tests.yml (vitest with the JSON reporter, the summary script, the
  artifact, the continue-on-error plus explicit fail pattern).
- **Added by the kit (the donor had no CI for this):** the `lint` and `build`
  jobs. Typecheck is not a separate step: `npm run build` is `tsc -b && vite
  build`, so the build is the type check (the donor's pattern).

## Files

| File | Where it goes in the target project |
|---|---|
| templates/ci.yml | .github/workflows/ci.yml |

## Parameterization (conveyor.config.json)

The `# conveyor: <key>` markers in the template show what to change:

- `ci.mainBranch`, `ci.developBranch` - the trigger branches (main, develop by
  default; if there is no develop, remove it).
- `project.nodeVersion` - the Node version (24 by default).
- `ci.lintCommand`, `ci.buildCommand` - the commands, if they differ from
  npm run lint / npm run build.
- the path filters in `on.push.paths` - adjust to the project's structure (or
  delete the block entirely to always run).

## Required secrets (GitHub -> Settings -> Secrets and variables -> Actions)

| Secret | Required | Why |
|---|---|---|
| VITE_SUPABASE_URL | no* | if the unit tests or the build read env |
| VITE_SUPABASE_ANON_KEY | no* | same |

*A Vite build succeeds with empty values; the secrets are needed when the tests
actually talk to Supabase. The anon key is public by Supabase's design, but it
still never gets committed to the repository.

## Application (for the agent)

1. If `.github/workflows/` already has CI with lint/test/build, do NOT
   duplicate it: compare the coverage and add the missing jobs to the existing
   file (idempotency).
2. Copy the template and replace the values at the `# conveyor:` markers.
3. Check that the package.json scripts exist - `lint`, `build` - and that vitest
   is installed. If there are no unit tests at all, comment out the `unit` job
   and record a TODO in the application report (do not fail on an empty
   project).

## Verification checklist

See [checklist.md](checklist.md). Nothing is pushed to main without a green run.
