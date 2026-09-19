# Module 05 - monitoring

Sentry (errors + release tags + sourcemaps) and a periodic production health
check.

This is the only module allowed to touch application code, and strictly to a
template: the import plus the `initSentry()` call in main.tsx (the one
documented exception to "do not touch application code").

## Origin

- **From the working donor (proven):** templates/sentry.ts - init with
  enabled-in-PROD-only, tracesSampleRate 0.1, and apikey redaction in
  breadcrumbs; the chat alert pattern (Telegram Bot API).
- **Added by the kit (NOT verified in the donor - gaps found during the audit):**
  - the VITE_APP_VERSION define in vite.config (the donor's release tag was
    empty);
  - sourcemap upload through @sentry/vite-plugin;
  - templates/health-check.yml (a cron ping of the web app and the Supabase
    REST endpoint).

## Files

| File | Where |
|---|---|
| templates/sentry.ts | src/shared/lib/sentry.ts (adjust the path to the project) |
| templates/vite-sentry.snippet.ts | merge into vite.config.ts (2 blocks, the second is optional) |
| templates/health-check.yml | .github/workflows/health-check.yml |

## Application (for the agent)

1. `npm i @sentry/react` (plus `npm i -D @sentry/vite-plugin` for sourcemaps).
2. Add sentry.ts; in src/main.tsx add two lines STRICTLY as in the template:
   `import { initSentry } from '<path>/sentry'` and `initSentry();` before the
   render. Idempotency: if a Sentry.init already exists somewhere, do not
   duplicate it - only check the pattern (enabled, release, beforeSend).
3. Merge the define block into vite.config.ts.
4. ErrorBoundary: if the app has none, offer Sentry.ErrorBoundary around the
   root (optional, record it in the report).
5. Add VITE_SENTRY_DSN to .env.example (module 06) and to the env of production
   builds (Vercel env, the Android workflow secrets, the Codemagic group).

## Sentry setup (Owner, in the UI - the agent cannot do this)

1. sentry.io -> create a project (react). Put the DSN into env/secrets.
2. Alerts: Alerts -> Create Alert -> "Issues": a new issue in production ->
   email or a chat integration. Recommended minimum: an alert on new errors
   and one on a spike (>10 events per hour).
3. For sourcemaps: Settings -> Auth Tokens -> a token with the project:releases
   scope -> the SENTRY_AUTH_TOKEN secret (in CI, NOT prefixed with VITE_).

## Required secrets and env

| Name | Where |
|---|---|
| VITE_SENTRY_DSN | Vercel env + GH secrets + Codemagic group |
| SENTRY_AUTH_TOKEN | GH secrets (only with sourcemaps) |
| TELEGRAM_BOT_TOKEN_REPORTS, TELEGRAM_CHAT_ID_REPORTS | optional, health check alert (Telegram backend, proven) |
| NOTIFY_WEBHOOK_URL_REPORTS | optional, health check alert (webhook backend, not verified) |

## Verification checklist

See [checklist.md](checklist.md). The key check: Sentry catches a test error.
