// Release Conveyor Kit - module 07-smoke-e2e
// Origin: proven the donor project auth.setup.ts, generalized.
// Sign in via Supabase REST API instead of UI:
//  - fails immediately with a clear error if credentials are wrong
//  - does not depend on UI selectors or page load timing
//  - runs in <1s vs 15s UI timeout

import { test as setup } from '@playwright/test';
import path from 'path';
import fs from 'fs';

// Supabase persists the session under sb-<project-ref>-auth-token
function getStorageKey(supabaseUrl: string): string {
  const match = supabaseUrl.match(/https:\/\/([a-z0-9]+)\.supabase\.co/);
  if (!match) throw new Error(`Cannot parse project ref from URL: ${supabaseUrl}`);
  return `sb-${match[1]}-auth-token`;
}

// Ping Supabase before attempting auth - fail fast with a clear error
// instead of a 90s goto timeout.
async function waitForSupabase(apiUrl: string, apiKey: string, timeoutMs = 20000): Promise<void> {
  const deadline = Date.now() + timeoutMs;
  let lastError: unknown;
  while (Date.now() < deadline) {
    try {
      const res = await fetch(`${apiUrl}/rest/v1/`, {
        headers: { apikey: apiKey },
        signal: AbortSignal.timeout(5000),
      });
      if (res.status > 0) return; // any HTTP response means Supabase is reachable
    } catch (e) {
      lastError = e;
    }
    await new Promise(r => setTimeout(r, 1000));
  }
  throw new Error(`Supabase not reachable after ${timeoutMs}ms: ${lastError}`);
}

setup('authenticate as qa user', async ({ page }) => {
  const authDir = path.join(__dirname, '../.auth');
  const AUTH_FILE = path.join(authDir, 'user.json');
  const email    = process.env.TEST_EMAIL!;
  const password = process.env.TEST_PASSWORD!;
  const apiUrl   = process.env.VITE_SUPABASE_URL!;
  const apiKey   = process.env.VITE_SUPABASE_ANON_KEY!;

  if (!email || !password) throw new Error('TEST_EMAIL and TEST_PASSWORD must be set');
  if (!apiUrl || !apiKey)  throw new Error('VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY must be set');

  await waitForSupabase(apiUrl, apiKey);

  const res = await fetch(`${apiUrl}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', apikey: apiKey },
    body: JSON.stringify({ email, password }),
  });

  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(
      `Supabase auth failed (${res.status}): ${body.error_description ?? body.msg ?? body.error ?? JSON.stringify(body)}`
    );
  }

  const session = await res.json();

  const storageKey = getStorageKey(apiUrl);
  const storageValue = JSON.stringify({
    access_token:  session.access_token,
    token_type:    session.token_type ?? 'bearer',
    expires_in:    session.expires_in,
    expires_at:    session.expires_at,
    refresh_token: session.refresh_token,
    user:          session.user,
  });

  // Inject state before the app boots - avoids "Execution context was
  // destroyed" races if the app redirects on load.
  await page.addInitScript(
    ({ key, value }) => {
      window.localStorage.setItem(key, value);
      // TODO(kit): add app-specific keys that must be pre-seeded so smoke
      // tests skip onboarding/tours, e.g.:
      // window.localStorage.setItem('<app>_onboarding', JSON.stringify({ state: { completed: true }, version: 0 }));
      // window.localStorage.setItem('language', 'en'); // stable text selectors
    },
    { key: storageKey, value: storageValue }
  );

  // TODO(kit): replace /dashboard with the app's main authenticated route
  await page.goto('/dashboard', { waitUntil: 'domcontentloaded', timeout: 90_000 });
  await page.waitForURL(/dashboard/, { timeout: 30_000 });

  if (!fs.existsSync(authDir)) fs.mkdirSync(authDir, { recursive: true });
  await page.context().storageState({ path: AUTH_FILE });
});
