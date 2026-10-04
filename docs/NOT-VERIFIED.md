# Not verified

The kit never presents an unrun template as proven. As of this release the
following are *added by the kit, not verified*, and their READMEs say so:

- **Module 14, session respawn.** Syntax, shellcheck and dry runs pass in all
  three modes. The first real reboot with the unit enabled did not pass: the
  unit had a hard dependency on the bridge, so when the script stopped the
  bridge the service manager stopped the script with it. That is fixed. The
  first real cold run, after a power loss, brought every window, binding and
  session back, but the bridge treated more than half of the windows as dead
  until it was restarted by hand. The script now does that restart itself and
  checks the result; that change has not run in a real cold start, and the
  module stays *not verified* until one passes clean.
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
