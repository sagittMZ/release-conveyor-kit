// Release Conveyor Kit - module 07-smoke-e2e
// Minimal smoke suite: launch, login/session, navigation, core CRUD, logout.
// Pattern origin: donor e2e suite (auth.spec.ts, navigation.spec.ts,
// tasks.spec.ts), trimmed to the kit's 5-8 scenario core.
//
// Every TODO(kit) marks a place the applying agent MUST adapt to the target
// app (routes, selectors, entity names). Prefer data-testid selectors; ask
// the owner to add them if missing (small, infra-level change).
//
// Test data convention: everything created here starts with "E2E" - the
// cleanup RPC from module 04-staging wipes it by this prefix.

import { test, expect } from '@playwright/test';

const E2E_PREFIX = 'E2E smoke';

// SMOKE-01 - unauthenticated app loads
test.describe('SMOKE-01 - app loads', () => {
  // Run without the saved session
  test.use({ storageState: { cookies: [], origins: [] } });

  test('landing/login page renders for guests', async ({ page }) => {
    await page.goto('/');
    // TODO(kit): assert a stable element of the public page
    await expect(page.getByRole('button', { name: /sign in/i })).toBeVisible({ timeout: 15_000 });
  });
});

// SMOKE-02 - session from auth.setup gives access to the app
test.describe('SMOKE-02 - login/session', () => {
  test('main authenticated screen is accessible', async ({ page }) => {
    // TODO(kit): main authenticated route
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/dashboard/, { timeout: 10_000 });
  });
});

// SMOKE-03 - primary navigation works
test.describe('SMOKE-03 - navigation', () => {
  // TODO(kit): list 2-4 primary routes of the app
  const routes = [
    { label: 'Tasks', expectedUrl: 'tasks' },
    { label: 'Settings', expectedUrl: 'settings' },
  ];

  for (const { label, expectedUrl } of routes) {
    test(`link "${label}" navigates correctly`, async ({ page }) => {
      await page.goto('/dashboard');
      // domcontentloaded: networkidle never settles with Supabase Realtime open
      await page.waitForLoadState('domcontentloaded');
      await page.getByRole('link', { name: new RegExp(label, 'i') }).first().click();
      await expect(page).toHaveURL(new RegExp(expectedUrl), { timeout: 8_000 });
    });
  }
});

// SMOKE-04..06 - core CRUD on the app's main entity
test.describe('SMOKE-04/05/06 - core CRUD', () => {
  const itemTitle = `${E2E_PREFIX} item ${Date.now()}`;

  test('create main entity', async ({ page }) => {
    // TODO(kit): route + selectors of the create flow
    await page.goto('/tasks');
    await page.getByTestId('create-item-btn').click();
    await page.getByTestId('item-title-input').fill(itemTitle);
    await page.getByRole('button', { name: /save|create/i }).click();
    await expect(page.getByText(itemTitle)).toBeVisible({ timeout: 10_000 });
  });

  test('edit main entity', async ({ page }) => {
    await page.goto('/tasks');
    await page.getByText(itemTitle).click();
    // TODO(kit): selectors of the edit flow
    await page.getByTestId('item-title-input').fill(`${itemTitle} edited`);
    await page.getByRole('button', { name: /save/i }).click();
    await expect(page.getByText(`${itemTitle} edited`)).toBeVisible({ timeout: 10_000 });
  });

  test('delete main entity', async ({ page }) => {
    await page.goto('/tasks');
    await page.getByText(`${itemTitle} edited`).click();
    // TODO(kit): delete control (+ confirm dialog if any)
    await page.getByTestId('delete-item-btn').click();
    await page.getByRole('button', { name: /confirm|delete/i }).click();
    await expect(page.getByText(`${itemTitle} edited`)).not.toBeVisible({ timeout: 10_000 });
  });
});

// SMOKE-07 - logout
test.describe('SMOKE-07 - logout', () => {
  test('sign out redirects to public page', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForURL(/dashboard/);
    // TODO(kit): sign-out control (open menu/drawer first if needed)
    await page.getByRole('button', { name: /sign out/i }).click();
    await page.waitForURL('/', { timeout: 10_000 });
    await expect(page).not.toHaveURL(/dashboard/);
  });
});
