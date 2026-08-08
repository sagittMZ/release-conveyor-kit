# Verification checklist - module 05 monitoring

- [ ] `npm run build` passes after the vite.config / main.tsx edits.
- [ ] In a production build (`vite preview --mode production` with
      VITE_SENTRY_DSN set), trigger a test error - for example a temporary
      button with `throw new Error('sentry-test')` - and the event shows up in
      Sentry within a minute.
- [ ] The event carries a release (the version from package.json) and an
      environment.
- [ ] In dev mode no events are sent (enabled: PROD only).
- [ ] (With sourcemaps) the stack trace in Sentry shows the sources, not
      minified code.
- [ ] Health Check workflow: a manual run is green; pointing it at a
      non-existent URL turns it red (plus a Telegram message, if configured).
- [ ] The alert rule exists in Sentry (a manual owner step).
