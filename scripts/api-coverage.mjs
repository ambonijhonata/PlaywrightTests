import { spawn } from 'node:child_process';
import { access, rm } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const moduleDirectory = dirname(fileURLToPath(import.meta.url));
const workspaceRoot = resolve(moduleDirectory, '..', '..');
const apiDirectory = resolve(workspaceRoot, 'API');
const testDirectory = resolve(workspaceRoot, 'PlaywrightTests');
const HEALTH_PATH = '/healthz';

export function parseCoverageMinimum(value) {
  const parsed = Number(value ?? '0.70');
  if (!Number.isFinite(parsed) || parsed <= 0 || parsed > 1) {
    throw new Error(
      'API_JACOCO_MIN_LINE_COVERAGE must be a number greater than 0 and at most 1.'
    );
  }
  return parsed;
}

export function mavenCommand(platform = process.platform) {
  return platform === 'win32' ? 'mvn.cmd' : 'mvn';
}

export function npmCommand(platform = process.platform) {
  return platform === 'win32' ? 'npm.cmd' : 'npm';
}

export function coverageReportDirectory(apiRoot = apiDirectory) {
  return resolve(apiRoot, 'target', 'site', 'jacoco-playwright');
}

export function parseLocalApiUrl(value) {
  const url = new URL(value);
  if (
    url.protocol !== 'http:' ||
    !['localhost', '127.0.0.1'].includes(url.hostname)
  ) {
    throw new Error('API_COVERAGE_BASE_URL must be an http localhost URL.');
  }
  if (!url.port)
    throw new Error('API_COVERAGE_BASE_URL must include an explicit port.');
  return url;
}

function run(command, args, options) {
  return new Promise((resolveRun, reject) => {
    const child = spawn(command, args, {
      ...options,
      stdio: 'inherit',
      shell: process.platform === 'win32' && /\.(cmd|bat)$/iu.test(command)
    });
    child.once('error', reject);
    child.once('exit', (code, signal) => {
      if (code === 0) {
        resolveRun();
      } else {
        const outcome = signal ?? `code ${code}`;
        reject(new Error(`${command} exited with ${outcome}.`));
      }
    });
  });
}

async function waitForHealthyApi(baseUrl, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  let lastError = null;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(new URL(HEALTH_PATH, baseUrl));
      if (response.status === 200 && (await response.text()).trim() === 'true')
        return;
      lastError = new Error(`health endpoint returned HTTP ${response.status}`);
    } catch (error) {
      lastError = error;
    }
    await new Promise((resolveDelay) => setTimeout(resolveDelay, 1_000));
  }
  throw new Error(
    `API did not become healthy within ${timeoutMs}ms: ${lastError?.message ?? 'unknown error'}`
  );
}

async function terminateOwnedProcess(child) {
  if (!child || child.exitCode !== null) return;
  if (process.platform === 'win32') {
    await run('taskkill', ['/pid', String(child.pid), '/t', '/f'], {
      cwd: apiDirectory
    });
    return;
  }
  child.kill('SIGTERM');
  await new Promise((resolveExit) => child.once('exit', resolveExit));
}

async function removeStaleExecutionData(apiRoot) {
  await Promise.all(
    [
      'jacoco-playwright.exec',
      'jacoco-playwright-unit.exec',
      'jacoco-playwright-merged.exec'
    ].map((filename) =>
      rm(resolve(apiRoot, 'target', filename), { force: true })
    )
  );
}

export async function runApiCoverage({
  baseUrl = process.env.API_COVERAGE_BASE_URL ?? 'http://localhost:8081',
  minimum = parseCoverageMinimum(process.env.API_JACOCO_MIN_LINE_COVERAGE),
  healthTimeoutMs = Number(
    process.env.API_COVERAGE_HEALTH_TIMEOUT_MS ?? '90000'
  ),
  apiRoot = apiDirectory,
  playwrightRoot = testDirectory
} = {}) {
  if (!Number.isInteger(healthTimeoutMs) || healthTimeoutMs < 1_000) {
    throw new Error(
      'API_COVERAGE_HEALTH_TIMEOUT_MS must be an integer of at least 1000.'
    );
  }
  await access(resolve(apiRoot, 'pom.xml'));
  await access(resolve(playwrightRoot, 'package.json'));
  await removeStaleExecutionData(apiRoot);
  const localApiUrl = parseLocalApiUrl(baseUrl);

  const mvn = mavenCommand();
  const coverageProperty = `-Djacoco.playwright.minimumLineCoverage=${minimum}`;
  await run(mvn, ['-Pplaywright-coverage', coverageProperty, 'test'], {
    cwd: apiRoot
  });
  const apiProcess = spawn(
    mvn,
    [
      '-Pplaywright-coverage',
      coverageProperty,
      `-Dspring-boot.run.arguments=--server.port=${localApiUrl.port}`,
      'initialize',
      'spring-boot:run',
      '-Dspring-boot.run.profiles=dev'
    ],
    {
      cwd: apiRoot,
      stdio: 'inherit',
      shell: process.platform === 'win32' && /\.(cmd|bat)$/iu.test(mvn)
    }
  );
  let processRunning = true;
  apiProcess.once('exit', () => {
    processRunning = false;
  });

  try {
    await waitForHealthyApi(baseUrl, healthTimeoutMs);
    const npm = npmCommand();
    await run(npm, ['run', 'test:api'], {
      cwd: playwrightRoot,
      env: {
        ...process.env,
        API_BASE_URL: baseUrl,
        PLAYWRIGHT_WORKERS: '1'
      },
      shell: process.platform === 'win32' && /\.(cmd|bat)$/iu.test(npm)
    });
    await run(
      mvn,
      [
        '-Pplaywright-coverage',
        coverageProperty,
        'jacoco:dump@playwright-dump'
      ],
      { cwd: apiRoot }
    );
    await terminateOwnedProcess(apiProcess);
    processRunning = false;
    await run(
      mvn,
      [
        '-Pplaywright-coverage',
        coverageProperty,
        'jacoco:merge@playwright-merge',
        'jacoco:report@playwright-report',
        'jacoco:check@playwright-check'
      ],
      { cwd: apiRoot }
    );
  } finally {
    if (processRunning) await terminateOwnedProcess(apiProcess);
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  runApiCoverage().then(
    () =>
      console.log(`JaCoCo report available at ${coverageReportDirectory()}`),
    (error) => {
      console.error(error.message);
      process.exitCode = 1;
    }
  );
}
