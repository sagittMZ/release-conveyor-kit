// Release Conveyor Kit - module 05-monitoring
// Sentry initialization for React + Vite. Origin: proven the donor project
// src/shared/lib/sentry.ts. Place in src/shared/lib/sentry.ts (or your lib dir)
// and call initSentry() first thing in src/main.tsx.
//
// npm i @sentry/react

import * as Sentry from '@sentry/react';

export function initSentry() {
  const dsn = import.meta.env.VITE_SENTRY_DSN;
  if (!dsn) return;

  Sentry.init({
    dsn,
    environment: import.meta.env.MODE, // 'production' | 'development'
    // Requires the define() block in vite.config.ts (see module README) -
    // without it the release tag is undefined and issues are not grouped
    // per release.
    release: import.meta.env.VITE_APP_VERSION,
    enabled: import.meta.env.PROD,
    // Only sample performance traces in prod (0.1 = 10%)
    tracesSampleRate: 0.1,
    beforeSend(event) {
      // Strip Supabase anon key from breadcrumb URLs
      const crumbs = event.breadcrumbs;
      if (Array.isArray(crumbs)) {
        event.breadcrumbs = crumbs.map((b) => {
          if (b.data?.url && typeof b.data.url === 'string') {
            b.data.url = b.data.url.replace(/apikey=[^&]+/, 'apikey=REDACTED');
          }
          return b;
        });
      }
      return event;
    },
  });
}

export { Sentry };
