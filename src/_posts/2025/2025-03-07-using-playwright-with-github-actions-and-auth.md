---
layout: post
title: "Using Playwright with Github Actions and Auth"
date: 2025-03-07 12:00:00 -0000
categories: [APIs, Playwright, Github]
---

# Using Playwright with Github Actions and Auth

You've got a webapp now and want to make sure it works. You've done the right thing of requiring auth for all users and [TOTP](https://en.wikipedia.org/wiki/Time-based_one-time_password) so your bots also have to use this.

You've chosen playwright, and are wondering how to make

- The various browsers use the same cookies/session for auth
- avoid having to download all the various browsers every time

## Configuration

TOTPs can only be used, and for a limited time period (it's in the name)

Due to this, we want to authenticate once, and then re-use those cookies/etc for the various browsers for this bot user

```typescript
// e2e-tests/external-users/auth.setup.ts

import { test as setup } from "@playwright/test";
import { promises as fs } from "fs";
import path from "path";

import { login } from "../lib/login";

const authFile = path.join(import.meta.dirname, "external-users.auth.json");

setup("authenticate", async ({ page }) => {
  // login is my custom function to do all the authentication/totp goodness based on https://playwrightsolutions.com/playwright-login-test-with-2-factor-authentication-2fa-enabled/
  // login will still need to have a backoff in case multiple github actions run at the same time, and deal with retries
  await login(page, "USERNAME", "EMAIL", "PASSWORD", "TOTP_SEED");

  await fs.mkdir(path.dirname(authFile), { recursive: true }).catch(() => {});

  // Save out the cookies/etc for use by *all* browsers
  await page.context().storageState({ path: authFile });
});
```

Now for the actual playwright configuration, main useful part is `dependencies: ["setup"],` and `storageState: "e2e-tests/external-users/external-users.auth.json",` which means the auth is only done once and then re-used by the other browsers

```typescript
// playwright.config.ts
import { defineConfig, devices } from "@playwright/test";

/**
 * See https://playwright.dev/docs/test-configuration.
 */
// eslint-disable-next-line no-restricted-exports
export default defineConfig({
  testDir: "./e2e-tests",
  /* Run tests in files in parallel */
  fullyParallel: true,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,
  // 10 minutes since LLMs can be slow
  timeout: 600000,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: "html",
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('/')`. */
    // baseURL: 'http://127.0.0.1:3000',

    /* Record trace for failed tests. See https://playwright.dev/docs/trace-viewer */
    trace: "retain-on-failure",

    // Record video for failed tests
    video: "retain-on-failure",
  },

  /* Configure projects for major browsers */
  projects: [
    { name: "setup", testMatch: /.*\.setup\.ts/ },
    {
      name: "external-users-chromium",
      use: {
        ...devices["Desktop Chrome"],
        storageState: "e2e-tests/external-users/external-users.auth.json",
      },
      testMatch: /external-users\/.*\.spec\.ts/,
      dependencies: ["setup"],
    },

    {
      name: "external-users-firefox",
      use: {
        ...devices["Desktop Firefox"],
        storageState: "e2e-tests/external-users/external-users.auth.json",
      },
      testMatch: /external-users\/.*\.spec\.ts/,
      dependencies: ["setup"],
    },

    {
      name: "external-users-webkit",
      use: {
        ...devices["Desktop Safari"],
        storageState: "e2e-tests/external-users/external-users.auth.json",
      },
      testMatch: /external-users\/.*\.spec\.ts/,
      dependencies: ["setup"],
    },
  ],
});
```

## Caching and Github Actions

Here is my customised version of the initial playwright Github Action. The main change is

- Cache the browsers downloaded, based on playwright version and configuration

```yaml
name: Scheduled Playwright Tests
on:
  push:
    schedule:
      - cron: "*/30 * * * *" # Run every 30 minutes
  workflow_dispatch: {}
concurrency:
  group: playwright
jobs:
  test:
    timeout-minutes: 15
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: lts/*
          cache: "npm"
      - name: Install dependencies
        run: npm ci
      - name: Get installed Playwright version
        id: playwright-version
        run: echo "PLAYWRIGHT_VERSION=$(node -e "console.log(require('./package-lock.json').packages['node_modules/@playwright/test'].version)")" >> $GITHUB_ENV
      - name: Get hashed Playwright configuration
        run: echo "PLAYWRIGHT_CONFIG_HASH=$(node -e "console.log(require('crypto').createHash('sha256').update(require('fs').readFileSync('./playwright.config.ts', 'utf8')).digest('hex'))")" >> $GITHUB_ENV
      - name: Restore cached playwright binaries
        # From https://playwrightsolutions.com/playwright-github-action-to-cache-the-browser-binaries/
        uses: actions/cache/restore@v4
        id: playwright-read-cache
        with:
          path: |
            ~/.cache/ms-playwright
          key: ${{ runner.os }}-playwright-${{ env.PLAYWRIGHT_VERSION }}-${{ env.PLAYWRIGHT_CONFIG_HASH }}
      - name: Install Playwright Browsers
        run: npx playwright install --with-deps
      - name: Cache Playwright Browsers
        if: steps.playwright-read-cache.outputs.cache-hit != 'true'
        uses: actions/cache/save@v4
        id: playwright-write-cache
        with:
          path: |
            ~/.cache/ms-playwright
          key: ${{ runner.os }}-playwright-${{ env.PLAYWRIGHT_VERSION }}-${{ env.PLAYWRIGHT_CONFIG_HASH }}
      - name: Run Playwright tests
        run: npx playwright test
        env:
          USERNAME: ${{ secrets.USERNAME }}
          EMAIL: ${{ secrets.EMAIL }}
          PASSWORD: ${{ secrets.PASSWORD }}
          TOTP_SEED: ${{ secrets.TOTP_SEED }}
      - uses: actions/upload-artifact@v4
        if: ${{ !cancelled() }}
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 8
```
