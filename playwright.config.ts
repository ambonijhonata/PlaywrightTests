import { defineConfig } from '@playwright/test';
import { defineBddConfig } from 'playwright-bdd';

const testDir = defineBddConfig({
  features: 'api-tests/**/*.feature',
  steps: ['src/steps/**/*.ts', 'src/fixtures/test.ts'],
  outputDir: 'api-tests/.features-gen'
});
const configuredWorkers = process.env.PLAYWRIGHT_WORKERS;
let workers: number | undefined;
if (configuredWorkers) workers = Number(configuredWorkers);
else if (process.env.CI) workers = 2;

export default defineConfig({
  testDir,
  timeout: 30_000,
  fullyParallel: true,
  workers,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: { baseURL: process.env.API_BASE_URL ?? 'http://localhost:8080' }
});
