# Not verified

The kit never presents an unrun template as proven. As of this release the
following are *added by the kit* and not verified, or verified only in part,
and their READMEs say so:

- **Module 14, session respawn - proven in part.** What has run for real: the
  warm path, and a cold start after a power loss that brought every window,
  binding and session back from the manifest. What went wrong on the way: the
  first reboot with the unit enabled failed on a hard dependency on the bridge
  (fixed), and after the cold start the bridge treated more than half of the
  windows as dead until it was restarted by hand. The script now does that
  restart itself and checks the result. That last change has passed a harness
  over the real state files and has not run in a real cold start, so the
  module is not called verified until one ends clean with nobody at the
  keyboard.
  A known limitation is documented in the module: a warm run for a window
  whose topic binding is missing lets the bridge create a fresh topic instead
  of rebinding the one from the manifest.
- **iOS TestFlight publishing.** The Codemagic bootstrap (generate the iOS
  project, compile unsigned) is from the donor and proven. Signing and
  publishing to TestFlight are a scaffold marked TODO (module 02); the App
  Store playbook beyond the first wave is written, not run (module 03).
- **Staging as a second Supabase project.** The donor ran QA accounts on one
  project; that variant is proven. The second-project variant is instructions
  that were never run against a live project (module 04).
- **Parts of monitoring and secrets.** Sourcemap upload, the release version
  define and the health-check cron in module 05, and the gitleaks workflow in
  module 06, were added after an audit found the gaps in the donor. The
  gitleaks workflow runs in the kit's own CI; the health-check cron has not
  run anywhere yet (the kit has no production URL to check).
- **Store playbook additions.** Data Safety notes and the Play API upload job
  in module 03.

Everything marked proven in a module README was extracted from the donor's
production pipeline as it ran there.
