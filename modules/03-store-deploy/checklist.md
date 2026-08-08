# Verification checklist - module 03 store-deploy

By the agent (statically):

- [ ] google-play.md / app-store.md are copied into the target project's docs/,
      with the placeholders replaced by values from conveyor.config.json.
- [ ] assetlinks.json / apple-app-site-association exist (if there are deep
      links); vercel.json exists in the project root (from the kit's
      templates/vercel.json, or merged in) and serves them with Content-Type
      application/json, with the SPA rewrite not swallowing them.
- [ ] The repository holds no reviewer credentials and no real fingerprints
      until the owner provides them.
- [ ] (If automatic upload is on) play-upload-step.yml is merged into
      android-build.yml and the YAML is valid.

By the owner (manual steps; the agent only reminds):

- [ ] Google Play: the app is created and an AAB passed Internal Testing.
- [ ] The Data Safety form is filled in.
- [ ] (iOS) Apple Developer is active, ios-testflight is finished, and a build
      is in TestFlight.

Not verifiable locally or in Actions: anything inside Play Console, App Store
Connect or Codemagic - mark those in the application report as "manual step".
