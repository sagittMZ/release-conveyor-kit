# Module 06 - secrets

Secret hygiene: the .env pattern, the .gitignore set, leak scanning in CI.

## Origin

- **From the working donor (proven):** the structure of .env.example (Required /
  Optional with comments on where the values live), and the secrets-related
  subset of .gitignore.
- **Added by the kit (the donor had none):** the gitleaks workflow and
  .gitleaks.toml.

## Files

| File | Where |
|---|---|
| templates/.env.example | .env.example (extend with the project's variables) |
| templates/gitignore.snippet | merge into .gitignore (without duplicates) |
| templates/gitleaks.yml | .github/workflows/gitleaks.yml |
| templates/.gitleaks.toml | .gitleaks.toml (root) |

## The conveyor's secret map (all modules, in one place)

| Secret | Storage | Module |
|---|---|---|
| VITE_SUPABASE_URL / ANON_KEY | GH secrets + Vercel + Codemagic | 1,2,4,5 |
| `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | GH secrets (+ the keystore in a password manager) | 2 |
| GOOGLE_SERVICES_JSON | GH secrets (with Firebase) | 2 |
| FIREBASE_APP_ID / FIREBASE_SERVICE_ACCOUNT | GH secrets (with App Distribution) | 2 |
| PLAY_SERVICE_ACCOUNT_JSON | GH secrets (with automatic Play upload) | 3 |
| APNs .p8, App Store Connect API key | password manager + the Codemagic integration | 3 |
| QA_TEST_EMAIL / QA_TEST_PASSWORD (and extra roles) | GH secrets | 4,7 |
| VITE_SENTRY_DSN | Vercel + GH + Codemagic | 5 |
| SENTRY_AUTH_TOKEN | GH secrets (no VITE_ prefix) | 5 |
| TELEGRAM_BOT_TOKEN_REPORTS / TELEGRAM_CHAT_ID_REPORTS | GH secrets (optional) | 5,7 |

Rules:

- The VITE_prefix means the value ends up in the client bundle. Tokens with
  write access (SENTRY_AUTH_TOKEN, service accounts) are NEVER prefixed with
  VITE_.
- The Supabase anon key is public by design (RLS is the protection), but it
  still does not get committed - no point teaching bad habits.
- The service role key is not used in CI or in the frontend at all (see module
  04 - cleanup runs through an RPC under the user's own JWT).

## Application (for the agent)

1. Merge gitignore.snippet; check that already-committed secret files are not
   still tracked (`git ls-files | grep -E '\.env$|\.jks'`) - if they are, tell
   the owner (that needs rotation, not just deletion).
2. Create or extend .env.example from the project's actual variables
   (`grep -rh "import.meta.env" src/ | sort -u`).
3. Install gitleaks.yml and .gitleaks.toml, and run gitleaks locally if it is
   installed: `gitleaks detect --source . -v`.
4. If the scan finds a leak in history, do NOT rewrite history automatically:
   report to the owner and rotate the key.

## Verification checklist

See [checklist.md](checklist.md).
