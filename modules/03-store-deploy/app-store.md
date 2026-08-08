# App Store / TestFlight - step-by-step playbook

Source: the donor's process (waves A-C). Honest status: wave A is proven in the
donor; waves B and C were STILL IN PROGRESS there when the kit was extracted, so
this scenario is assembled from the donor's playbook plus the Codemagic
documentation and is marked "not verified".

The constraint the whole process is built around: no Mac is needed at all - the
build and the signing happen in the Codemagic cloud.

## Wave A - preparing the code (Agent, no Apple Developer account) - PROVEN in the donor

- [ ] An `ios` block in capacitor.config.ts (contentInset: 'never',
      backgroundColor for the splash - the donor's pattern).
- [ ] Platform-specific calls (StatusBar and friends) only behind an Android
      guard.
- [ ] `public/.well-known/apple-app-site-association` plus the Content-Type
      header in vercel.json - copy the kit's template
      `modules/03-store-deploy/templates/vercel.json` into the project root (or
      merge its headers/rewrites sections into the existing file). The AASA
      contents (for universal links):

```json
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "<TEAM_ID>.<mobile.ios.bundleId>",
      "paths": ["*"]
    }]
  }
}
```

- [ ] .gitignore: GoogleService-Info.plist (module 06).
- [ ] codemagic.yaml from module 02 in the repo root.

## Wave B - Apple Developer + Codemagic (Owner) - NOT verified in the donor

### Apple Developer Portal ($99/year)

1. Enroll in the Apple Developer Program.
2. Identifiers -> App ID = the bundleId from the config; capabilities (Push and
   so on).
3. With push: the APNs Auth Key (.p8) - downloadable ONCE, straight into a
   password manager.

### Codemagic

1. Connect the repository and create the "ios" env group (variables from module
   02).
2. Teams -> Integrations -> Developer Portal: connect the App Store Connect API
   key (Issuer ID, Key ID, .p8) - that is the `app_store_connect` integration.
3. Run the `ios-bootstrap` workflow: download ios-project.zip, commit ios/.
4. Finish ios/ (agent): Info.plist usage descriptions (camera, mic, location -
   whatever the app uses), URL schemes, capabilities.
5. Replace the TODO steps in `ios-testflight` with the standard Codemagic CLI
   commands:

```yaml
      - name: Set up code signing
        script: |
          keychain initialize
          app-store-connect fetch-signing-files "$BUNDLE_ID" \
            --type IOS_APP_STORE --create
          keychain add-certificates
          xcode-project use-profiles
      - name: Build IPA
        script: |
          xcode-project build-ipa \
            --project "$XCODE_PROJECT" \
            --scheme "$XCODE_SCHEME"
```

6. Uncomment the `integrations` and `publishing` blocks (submit_to_testflight).

## Wave C - App Store Connect (Owner) - NOT verified in the donor

1. The app record (name, bundleId, SKU).
2. Privacy Policy URL + Support URL.
3. Privacy Nutrition Labels (the equivalent of Data Safety - see google-play.md
   step 7; the data set is the same).
4. Screenshots (6.7" is mandatory; one shared set is acceptable).
5. App Review notes plus a demo account for the reviewer (NOT in the repo).
6. Export compliance: for HTTPS-only apps this is usually "No".
7. TestFlight: internal group -> install by invite -> closed beta.
8. Submit for Review.

## What the agent does not do

Payments, creating accounts, downloading .p8 or .plist files, pressing Submit -
those are the human's. The agent prepares the files, the copy and the configs,
and checks them.
