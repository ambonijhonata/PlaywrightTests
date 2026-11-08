import playwright from 'eslint-plugin-playwright';
import sonarjs from 'eslint-plugin-sonarjs';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  {
    ignores: [
      'node_modules/**',
      'playwright-report/**',
      'test-results/**',
      'credenciais/**'
    ]
  },
  tseslint.configs.recommended,
  sonarjs.configs.recommended,
  {
    files: ['src/**/*.ts', 'playwright.config.ts'],
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname
      }
    },
    rules: {
      '@typescript-eslint/no-floating-promises': 'error',
      // The project deliberately uses concise one-line guards in context storage.
      'sonarjs/no-unenclosed-multiline-block': 'off'
    }
  },
  { ...playwright.configs['flat/recommended'], files: ['src/**/*.ts'] },
  {
    files: ['src/steps/**/*.ts'],
    rules: { 'playwright/no-standalone-expect': 'off' }
  }
);
