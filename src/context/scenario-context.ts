import type { APIResponse } from '@playwright/test';

const variablePlaceholderPattern = /\{([A-Za-z_]\w*)\}/g;

export class ScenarioContext {
  private readonly variables = new Map<string, unknown>();
  lastResponse?: APIResponse;
  lastBody: unknown;
  set(name: string, value: unknown) {
    this.variables.set(name, value);
  }
  get(name: string): unknown {
    if (!this.variables.has(name))
      throw new Error(`Variable not found: ${name}`);
    return this.variables.get(name);
  }
  hasValue(name: string): boolean {
    const value = this.variables.get(name);
    return value !== undefined && value !== null && String(value).trim() !== '';
  }
  replace(text: string): string {
    return text.replace(variablePlaceholderPattern, (_, name) =>
      String(this.get(name))
    );
  }
}
