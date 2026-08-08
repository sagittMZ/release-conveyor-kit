// Release Conveyor Kit - module 07-smoke-e2e
// Origin: proven donor tests/e2e/playwright.config.ts, simplified for a
// 5-8 scenario smoke suite (1 worker, no sharding).
// Lives in tests/e2e/ as a standalone package (own package.json).

import { defineConfig, devices } from '@playwright/test';
import dotenv from 'dotenv';
import path from 'path';

// Load .env.test for local runs; CI uses environment variables directly
dotenv.config({ path: path.resolve(__dirname, '.env.test') });

export default defineConfig({
  testDir: './tests',
  /* Global safety net: no single test can hang longer than this */
  timeout: process.env.CI ? 60_000 : 30_000,
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: process.env.CI
    ? [['html', { open: 'never' }], ['github']]
    : [['html', { open: 'on-failure' }]],
  use: {
    baseURL: process.env.BASE_URL ?? 'http://localhost:5173', // conveyor: ci.e2e.baseUrl
    /* Prevent any single click/fill/goto from hanging forever */
    actionTimeout: 15_000,
    navigationTimeout: 30_000,
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'off',
  },

  projects: [
    {
      name: 'setup',
      testMatch: /auth\.setup\.ts/,
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        storageState: '.auth/user.json',
      },
      dependencies: ['setup'],
    },
    // Mobile-first project? Swap Desktop Chrome for Pixel 5 (donor pattern):
    // {
    //   name: 'mobile-android',
    //   use: { ...devices['Pixel 5'], storageState: '.auth/user.json' },
    //   dependencies: ['setup'],
    // },
  ],

  webServer: {
    command: 'npm run dev -- --port 5173',
    url: 'http://localhost:5173',
    reuseExistingServer: !process.env.CI,
    timeout: 120 * 1000,
    cwd: '../../',
  },
});
