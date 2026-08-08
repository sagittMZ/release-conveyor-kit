# Module 02 - mobile-build

Mobile builds: Android (a signed AAB and APK in GitHub Actions, triggered by a
`v*` tag) and iOS (Codemagic, Capacitor 8 on SPM - no CocoaPods).

## Origin

- **From the working donor (proven):** android-build.yml in full (including
  signing through injected gradle parameters and the optional upload to Firebase
  App Distribution); the codemagic `ios-bootstrap` workflow (generating ios/ +
  an unsigned compile check); the build.gradle versioning snippet.
- **Scaffold the donor never finished (NOT verified):** codemagic
  `ios-testflight` - signing and publishing are marked TODO; finish it following
  module 03.

## Files

| File | Where it goes |
|---|---|
| templates/android-build.yml | .github/workflows/android-build.yml |
| templates/codemagic.yaml | codemagic.yaml (project root) |
| templates/build.gradle.snippet | merged by hand into android/app/build.gradle |

## Key patterns (why it is done this way)

- **versionCode = github.run_number** through `-PVERSION_CODE`: monotonic, with
  no bump commits; local builds fall back to 1.
- **versionName from package.json** - one version for web and Android.
- **Signing through -Pandroid.injected.signing.\*** - the keystore never sits in
  the repo and no signingConfig is needed in build.gradle.
- **Capacitor 8 iOS is SPM:** build App.xcodeproj, do NOT look for
  App.xcworkspace.
- **ios/ is committed to the repo** (like android/): generate it through
  ios-bootstrap, download the ios-project.zip artifact and commit it.

## Preconditions in the target project

1. `npx cap add android` has been run and android/ is committed.
2. build.gradle reads VERSION_CODE (the snippet is provided).
3. An upload keystore has been generated:
   `keytool -genkeypair -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias <alias>`
   and encoded: `base64 -w0 release.jks` -> into the secret.
4. For iOS: a Codemagic account, the app connected to the repo, an env group
   named "ios".

## Required secrets

GitHub Actions (Android):

| Secret | What it is |
|---|---|
| VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY | env for the web build inside the AAB |
| ANDROID_KEYSTORE_BASE64 | base64 of release.jks |
| ANDROID_KEYSTORE_PASSWORD | the keystore password |
| ANDROID_KEY_ALIAS | the key alias |
| ANDROID_KEY_PASSWORD | the key password |
| GOOGLE_SERVICES_JSON | base64 google-services.json (only with Firebase) |
| FIREBASE_APP_ID, FIREBASE_SERVICE_ACCOUNT | only when Firebase App Distribution is enabled |

Codemagic env group "ios": VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY and any
other VITE_* the build needs.

## Application (for the agent)

1. Check that android/ and Capacitor are present; if the platform is missing,
   run `npx cap add android` first. A local debug build is impossible without
   the SDK - in that case mark it "verified in CI only".
2. Merge the versioning snippet into android/app/build.gradle (idempotently: if
   appVersionCode is already read from a property, leave it alone).
3. Copy both templates and replace the values at the `# conveyor:` markers.
4. Delete the Firebase steps (google-services.json, App Distribution) if the
   project does not use Firebase.
5. iOS: if mobile.ios.enabled is false in the config, do not install
   codemagic.yaml.

## Verification checklist

See [checklist.md](checklist.md).
