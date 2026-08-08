# Google Play - step-by-step release playbook

Source: the donor's proven process (Google Play was shipped). Every value is a
placeholder - substitute from conveyor.config.json (mobile.android.appId and so
on).

Roles: "Owner" is the human (accounts, payments, buttons in consoles); "Agent"
is the AI agent (files in the repo, secret instructions, checks).

## Step 1 - Upload key (Owner, one-off)

The upload key is not the signing key: with Play App Signing enabled Google
re-signs the AAB with its own key, and the upload key is only needed to upload.

```bash
keytool -genkey -v \
  -keystore <app>-upload-key.jks \
  -alias <app>-upload \
  -keyalg RSA -keysize 2048 \
  -validity 10000
```

- All passwords random, straight into a password manager (with the keystore file
  as an attachment).
- Make sure `*.jks` is in .gitignore (module 06).
- Once it is in the secrets, delete the file from your machine.

## Step 2 - GitHub Actions secrets (Owner)

Settings -> Secrets and variables -> Actions:

| Secret | Where it comes from |
|---|---|
| ANDROID_KEYSTORE_BASE64 | `base64 -w0 <app>-upload-key.jks` |
| ANDROID_KEYSTORE_PASSWORD | store password |
| ANDROID_KEY_ALIAS | alias |
| ANDROID_KEY_PASSWORD | key password |

## Step 3 - Play Console: create the app (Owner)

1. [play.google.com/console](https://play.google.com/console) -> Create app
   (name, language, type App, Free; the developer account costs $25 once).
2. Setup -> App integrity -> App signing: Play App Signing is on by default -
   leave it.
3. Copy the SHA-256 fingerprint from "App signing key certificate" and give it
   to the agent.

## Step 4 - assetlinks.json for App Links (Agent)

If the app has deep links: `public/.well-known/assetlinks.json`:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "<mobile.android.appId>",
    "sha256_cert_fingerprints": [
      "<SHA256_OF_UPLOAD_KEY>",
      "<SHA256_FROM_PLAY_CONSOLE>"
    ]
  }
}]
```

The Content-Type header and the SPA rewrite with a /.well-known/ exception are
in the kit's template `modules/03-store-deploy/templates/vercel.json`: copy it
into the project root as `vercel.json` (if the file already exists, merge the
headers/rewrites sections without clobbering your own). Proven on the donor.
Check after deploying: `curl -I https://<domain>/.well-known/assetlinks.json`
(expect Content-Type: application/json, not the HTML SPA fallback).

## Step 5 - Store listing (Owner, with the agent helping on copy)

| Asset | Requirements |
|---|---|
| App icon | 512x512 PNG, NO transparency |
| Feature graphic | 1024x500 PNG/JPG |
| Screenshots | at least 2 (4-8 is better), 16:9 or 9:16, 320-3840 px |
| Title | up to 30 characters |
| Short description | up to 80 characters |
| Full description | up to 4000 characters |

## Step 6 - Privacy policy (Owner + Agent)

Mandatory. Generate one (for example with
app-privacy-policy-generator.nisrulz.com), host it statically on your own domain
(`/privacy`), and put the URL into the console.

## Step 7 - Data Safety form (Owner, the agent prepares the answers)

ADDED BY THE KIT (in the donor's checklist this step was completed in the
console without being written down): Play Console -> App content -> Data safety.
Typical answers for the kit's stack:

- Collected: email + name (Account info), user content (tasks / app data),
  device IDs if push is used (the FCM token).
- Shared: usually "No" (Supabase and Sentry are service providers, not "sharing"
  in Google's terms, as long as the data is not sold).
- Encrypted in transit: Yes (HTTPS). Deletion mechanism: mandatory - you need an
  account deletion page or flow.
- With Sentry: declare the collection of crash logs / diagnostics.

## Step 8 - A test account for the reviewer (Owner)

Create a dedicated account in the production database with demo data. In Play
Console -> App access -> "All or some functionality is restricted" -> attach the
instructions:

```
This app uses email/password login. No Google account required.
1. Open the app
2. Tap "Sign In"
3. Email: <reviewer email>
4. Password: <reviewer password>
```

Reviewer credentials do NOT go into the repository - only into the console and a
password manager.

## Step 9 - First build and Internal Testing

1. Actions -> Android Build & Distribute -> Run workflow (module 02).
2. Download the app-release-signed.aab artifact.
3. Play Console -> Testing -> Internal testing -> Create new release -> upload
   the AAB, add testers by email.
4. Walk the main flow plus deep links and push on a real device.

## Step 10 - Production

Internal -> Closed -> (Open) -> Production; each promotion needs release notes.
Google's review usually takes 1-3 days. Every release needs a higher versionCode
(in the kit that is github.run_number, which grows by itself).

## Option: uploading the AAB to Play Console from CI

The template is templates/play-upload-step.yml (Google Play Developer API).
ADDED BY THE KIT; the donor did NOT use it (there the upload was manual, with
Firebase App Distribution for QA). It requires:

1. A service account in Google Cloud plus a JSON key.
2. Play Console -> Users and permissions -> invite the service account with the
   "Release to testing tracks" permission.
3. The PLAY_SERVICE_ACCOUNT_JSON secret.
4. At least one release uploaded BY HAND before the API starts working - a
   Google restriction.

## Things worth knowing

- Losing the upload key is not a catastrophe (Play App Signing issues a new
  one); losing the Google account is - 2FA plus backup codes are mandatory.
- versionName comes from package.json, versionCode from run_number (module 02).
