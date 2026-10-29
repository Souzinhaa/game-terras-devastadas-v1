import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './tests/ui', workers: 1, fullyParallel: false,
  use: { baseURL: 'http://127.0.0.1:5174', browserName: 'chromium', headless: true, screenshot: 'only-on-failure' },
  webServer: { command: 'npm run dev -- --port 5174 --strictPort', url: 'http://127.0.0.1:5174', reuseExistingServer: !process.env.CI },
});
