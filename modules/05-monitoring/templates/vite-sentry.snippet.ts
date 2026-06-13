// Release Conveyor Kit - module 05-monitoring
// Additions to vite.config.ts. KIT ADDITIONS - the donor read
// VITE_APP_VERSION but never defined it (gap found during audit), and did not
// upload sourcemaps. Verify on your project before relying on it.

// 1) Release tag = package.json version, baked in at build time:
//
//   import pkg from './package.json' with { type: 'json' };
//
//   export default defineConfig({
//     define: {
//       'import.meta.env.VITE_APP_VERSION': JSON.stringify(pkg.version),
//     },
//     ...
//   });

// 2) Sourcemaps upload to Sentry (optional but makes stack traces readable).
//    npm i -D @sentry/vite-plugin
//    Needs SENTRY_AUTH_TOKEN in the CI env of the build step (org-level token
//    with project:releases scope). Never in client env (no VITE_ prefix!).
//
//   import { sentryVitePlugin } from '@sentry/vite-plugin';
//
//   export default defineConfig({
//     build: { sourcemap: 'hidden' }, // generate maps, do not reference them publicly
//     plugins: [
//       react(),
//       process.env.SENTRY_AUTH_TOKEN
//         ? sentryVitePlugin({
//             org: 'your-sentry-org',        // conveyor: monitoring.sentry.org
//             project: 'your-sentry-project',// conveyor: monitoring.sentry.project
//             authToken: process.env.SENTRY_AUTH_TOKEN,
//             release: { name: pkg.version },
//           })
//         : undefined,
//     ].filter(Boolean),
//   });
