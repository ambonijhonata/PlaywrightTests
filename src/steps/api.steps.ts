import type { APIResponse } from '@playwright/test';
import { randomUUID } from 'node:crypto';
import { createBdd } from 'playwright-bdd';
import { env } from '../env.js';
import { test, expect } from '../fixtures/test.js';
import {
  parseJson,
  readJsonPath,
  readOptionalJsonPath
} from '../support/json.js';

const { Given, When, Then } = createBdd(test);
const tableValue = (
  table: { hashes: () => Record<string, string>[] } | undefined,
  key: string
) => table?.hashes()[0]?.[key];
const accessToken = (scenario: { get: (name: string) => unknown }) => {
  try {
    return scenario.get('accessToken');
  } catch {
    return undefined;
  }
};
const conditionalMethods = new Set(['DELETE', 'POST', 'PUT']);

async function saveResponse(
  scenario: { lastResponse?: APIResponse; lastBody: unknown },
  response: APIResponse
) {
  scenario.lastResponse = response;
  const text = await response.text();
  scenario.lastBody = text ? JSON.parse(text) : undefined;
}

Given('I log in as user', async ({ api, scenario }, table) => {
  const credential =
    tableValue(table, 'USER') ?? tableValue(table, 'CREDENTIAL');
  if (!credential)
    throw new Error('The login table must contain USER or CREDENTIAL.');
  const prefix = credential.toUpperCase();
  const idTokenVariable = `${prefix}_ID_TOKEN`;
  const idToken = process.env[idTokenVariable];
  if (!idToken)
    throw new Error(
      `The local credential ${idTokenVariable} is not configured.`
    );

  scenario.lastResponse = await api.send('POST', env.loginEndpoint, {
    idToken
  });
  scenario.lastBody = await scenario.lastResponse.json();
  if (!scenario.lastResponse.ok()) {
    const errorCode = readOptionalJsonPath(scenario.lastBody, '$.code');
    throw new Error(
      `Login failed with HTTP ${scenario.lastResponse.status()}${
        errorCode ? ` (${String(errorCode)})` : ''
      }`
    );
  }
  const token = readJsonPath(scenario.lastBody, env.loginTokenJsonPath);
  scenario.set('accessToken', token);
});
Given(
  'I generate a unique value with prefix {string} and store it in variable {string}',
  async ({ scenario }, prefix, variable) =>
    scenario.set(variable, `${prefix}-${randomUUID()}`)
);

When(
  'I send a {word} request to endpoint {string}',
  async ({ api, scenario }, method, endpoint) => {
    const response = await api.send(
      method,
      scenario.replace(endpoint),
      undefined,
      accessToken(scenario)
    );
    await saveResponse(scenario, response);
  }
);
When(
  'I send a {word} request to endpoint {string} with body',
  async ({ api, scenario }, method, endpoint, table) => {
    const body = tableValue(table, 'BODY');
    const response = await api.send(
      method,
      scenario.replace(endpoint),
      body ? parseJson(body, scenario) : undefined,
      accessToken(scenario)
    );
    await saveResponse(scenario, response);
  }
);
When(
  'I send a {word} request to endpoint {string} without a body',
  async ({ api, scenario }, method, endpoint) => {
    const response = await api.send(
      method,
      scenario.replace(endpoint),
      undefined,
      accessToken(scenario)
    );
    await saveResponse(scenario, response);
  }
);
When(
  'I send a {word} request to endpoint {string} with raw body',
  async ({ api, scenario }, method, endpoint, table) => {
    const body = tableValue(table, 'BODY');
    if (body === undefined)
      throw new Error('The raw request body table must contain BODY.');
    const response = await api.sendRaw(
      method,
      scenario.replace(endpoint),
      scenario.replace(body),
      accessToken(scenario)
    );
    await saveResponse(scenario, response);
  }
);
When(
  'I send a {word} request to endpoint {string} without authentication',
  async ({ api, scenario }, method, endpoint) => {
    const response = await api.send(method, scenario.replace(endpoint));
    await saveResponse(scenario, response);
  }
);
When(
  'I send a {word} request to endpoint {string} with an invalid access token',
  async ({ api, scenario }, method, endpoint) => {
    const response = await api.send(
      method,
      scenario.replace(endpoint),
      undefined,
      'invalid-access-token'
    );
    await saveResponse(scenario, response);
  }
);
When(
  'I send a {word} request to endpoint {string} if variable {string} exists',
  async ({ api, scenario }, method, endpoint, variable, table) => {
    const normalizedMethod = method.toUpperCase();
    if (!conditionalMethods.has(normalizedMethod))
      throw new Error('Conditional requests only accept DELETE, POST, or PUT.');
    if (!scenario.hasValue(variable)) return;

    const body = tableValue(table, 'BODY');
    const response = await api.send(
      normalizedMethod,
      scenario.replace(endpoint),
      body ? parseJson(body, scenario) : undefined,
      accessToken(scenario)
    );
    await saveResponse(scenario, response);
  }
);
Then(
  'The response status code should be {string}',
  async ({ scenario }, status) =>
    expect(scenario.lastResponse?.status()).toBe(Number(status))
);
Then(
  'I store response field {string} in variable {string}',
  async ({ scenario }, path, variable) =>
    scenario.set(variable, readJsonPath(scenario.lastBody, path))
);
Then(
  'I store response field {string} in variable {string} if it exists',
  async ({ scenario }, path, variable) => {
    const value = readOptionalJsonPath(scenario.lastBody, path);
    if (value !== undefined) scenario.set(variable, value);
  }
);
Then(
  'The response field {string} should contain {string}',
  async ({ scenario }, path, value) =>
    expect(String(readJsonPath(scenario.lastBody, path))).toContain(
      scenario.replace(value)
    )
);
Then(
  'The response field {string} should equal {string}',
  async ({ scenario }, path, value) =>
    expect(String(readJsonPath(scenario.lastBody, path))).toBe(
      scenario.replace(value)
    )
);
Then('The response body should be empty', async ({ scenario }) =>
  expect(scenario.lastBody).toBeUndefined()
);
