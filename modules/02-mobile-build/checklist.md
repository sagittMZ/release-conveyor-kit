# Verification checklist - module 02 mobile-build

Locally / statically:

- [ ] The YAML of both templates is valid.
- [ ] android/app/build.gradle carries the appVersionCode/appVersionName
      pattern.
- [ ] .gitignore covers google-services.json and the keystore (see module 06).
- [ ] Every secret from the README exists in GitHub (Settings -> Secrets).

In CI:

- [ ] A workflow_dispatch run of Android Build is green, and the .aab and .apk
      artifacts appear in the run.
- [ ] The versionCode in the built AAB equals run_number (visible in the gradle
      log).
- [ ] (If Firebase is enabled) the build reached the tester group.

Codemagic (a manual step, not available locally without a Mac):

- [ ] ios-bootstrap has run, ios-project.zip is downloaded and ios/ is
      committed.
- [ ] The unsigned compile check is green.
- [ ] ios-testflight is NOT verifiable until module 03 (signing) is done.
