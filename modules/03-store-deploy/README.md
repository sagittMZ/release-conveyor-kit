# Module 03 - store-deploy

Shipping to the stores. This is the most fragile module in the kit - store
requirements change - so its core is step-by-step INSTRUCTIONS for the
"agent + owner" pair rather than hardcoded automation. Automation only where the
API is stable.

## Contents

| File | What it is | Status |
|---|---|---|
| google-play.md | The full path: upload key -> secrets -> console -> assetlinks -> listing -> Data Safety -> reviewer access -> Internal Testing -> Production | Proven by the donor (Google Play was shipped), except the Data Safety notes and the API upload option, which were added by the kit |
| app-store.md | TestFlight and App Store through Codemagic without a Mac (waves A-C) | Wave A is proven; B and C come from the donor's playbook and are NOT verified end to end |
| templates/play-upload-step.yml | Optional job that uploads the AAB to a track through the Google Play Developer API | Added by the kit, NOT verified |
| templates/vercel.json | Hosting config for deep links: the Content-Type of both .well-known files plus an SPA rewrite that does not swallow them; copied or merged into the target project root | The pattern is proven by the donor (headers + rewrite exception); the file itself was assembled by the kit |

## Degrading to instructions

Everything that cannot be automated - registrations, payments, signing, the
Submit button, review - is written as short steps for a human, explicitly
labelled "Owner". The agent produces the files, texts and checks, and tells the
human which button to press.

## Required secrets (beyond module 02)

| Secret | When it is needed |
|---|---|
| PLAY_SERVICE_ACCOUNT_JSON | only when the automatic Play upload is enabled |

Plus manual valuables that live outside CI: the upload keystore, the APNs .p8,
the App Store Connect API key. They live in a password manager and reach CI only
through secrets and integrations - never the repository.

## Verification checklist

See [checklist.md](checklist.md).
