# Module 04 - staging

The environment pattern for Supabase projects. Two variants; the choice is
`staging.variant` in conveyor.config.json.

## Variant A - a separate environment (paid, or a second free project)

NOT from the donor (the donor lives on the free tier with variant B) - these are
instructions:

1. **A second Supabase project** (a second free project is acceptable: two per
   account): push the migrations to the second project-ref with `supabase db
   push`, add STAGING_SUPABASE_URL/ANON_KEY to the secrets, and point Vercel's
   preview env variables at the staging project.
2. **Or Supabase Branching** (a paid plan): database branches per PR, with the
   variables injected by the Vercel x Supabase integration.

Upside: full isolation. Downside: cost and keeping migrations in sync. For pilot
vibe-coded projects the kit recommends starting with variant B.

## Variant B - QA accounts on production (free tier) - PROVEN by the donor

The idea: there is no staging, but e2e and manual QA go against the production
project under dedicated tagged accounts whose data is isolated and cleaned up.

The parts (all from the working donor):

1. **A pool of QA accounts** with one email convention: `qa-<role>@<domain>`. At
   least one (`qa-smoke@...`); the donor had four: smoke, onboarding (no data,
   for the first-login scenario), member, admin (a protected fixture pool).
   Passwords live in a password manager and in the QA_*_EMAIL / QA_*_PASSWORD
   secrets.
2. **A test data prefix:** everything the tests create starts with "E2E" -
   visible to the eye, easy to clean.
3. **The cleanup_e2e_data RPC** (templates/cleanup_e2e_data.sql) - cleans the
   calling user's data WITHOUT a service role key in CI. The kit added a guard
   on the qa-% email convention (the donor had none - noted in the file).
4. **A CI cleanup job before the run** (templates/qa-cleanup-job.yml) - wired in
   as the first job of module 07's e2e workflow.
5. **Flags that exclude CI from analytics and monitoring:** in the donor's
   pattern, VITE_CI=true during e2e runs; the app then sends no analytics events
   and tags the session. When applying: find the analytics init and wrap it in a
   guard, `if (import.meta.env.VITE_CI) return;` (same idea as Sentry - see
   module 05: enabled in PROD only).

## Files

| File | Where |
|---|---|
| templates/cleanup_e2e_data.sql | supabase/migrations/<timestamp>_e2e_cleanup_rpc.sql (adapt the tables to your schema) |
| templates/qa-cleanup-job.yml | merge the job into module 07's e2e workflow |

## Required secrets

QA_TEST_EMAIL, QA_TEST_PASSWORD (plus pairs for other roles if needed),
VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY.

## Application (for the agent)

1. Ask the owner: variant A or B (B is the default).
2. For B: create the QA accounts through the app's normal signup (the agent does
   not touch auth.users directly), adapt the SQL template to the real tables
   (detect the main user-facing table from the schema), and apply the migration
   with `supabase db push` or through MCP / the SQL editor.
3. Idempotency: CREATE OR REPLACE, plus a check for an existing migration with
   the same name.

## Verification checklist

See [checklist.md](checklist.md).
