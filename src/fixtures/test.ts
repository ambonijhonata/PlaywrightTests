import { test as base } from 'playwright-bdd';
import { ApiClient } from '../http/api-client.js';
import { ScenarioContext } from '../context/scenario-context.js';

export const test = base.extend<{ api: ApiClient; scenario: ScenarioContext }>({
  scenario: async ({}, use) => use(new ScenarioContext()),
  api: async ({ request }, use) => use(new ApiClient(request))
});
export { expect } from '@playwright/test';
