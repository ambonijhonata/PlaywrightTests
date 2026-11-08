import assert from 'node:assert/strict';
import test from 'node:test';
import {
  coverageReportDirectory,
  mavenCommand,
  npmCommand,
  parseCoverageMinimum,
  parseLocalApiUrl
} from './api-coverage.mjs';

test('uses the documented default coverage threshold and rejects unsafe values', () => {
  assert.equal(parseCoverageMinimum(), 0.7);
  assert.equal(parseCoverageMinimum('0.85'), 0.85);
  for (const value of ['0', '-0.1', '1.01', 'not-a-number']) {
    assert.throws(() => parseCoverageMinimum(value));
  }
});

test('derives platform-specific Maven commands and a workspace-local report path', () => {
  assert.equal(mavenCommand('win32'), 'mvn.cmd');
  assert.equal(mavenCommand('linux'), 'mvn');
  assert.equal(npmCommand('win32'), 'npm.cmd');
  assert.equal(npmCommand('linux'), 'npm');
  assert.match(
    coverageReportDirectory('C:/workspace/API'),
    /jacoco-playwright$/u
  );
});

test('accepts only an explicit loopback HTTP endpoint for the API it owns', () => {
  assert.equal(parseLocalApiUrl('http://localhost:8081').port, '8081');
  assert.throws(() => parseLocalApiUrl('https://localhost:8081'));
  assert.throws(() => parseLocalApiUrl('http://example.com:8081'));
  assert.throws(() => parseLocalApiUrl('http://localhost'));
});
