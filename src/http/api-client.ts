import type { APIRequestContext, APIResponse } from '@playwright/test';

export class ApiClient {
  constructor(private readonly request: APIRequestContext) {}
  async send(
    method: string,
    endpoint: string,
    body?: unknown,
    token?: unknown
  ): Promise<APIResponse> {
    return this.request.fetch(endpoint, {
      method,
      data: body,
      headers: token ? { Authorization: `Bearer ${String(token)}` } : undefined,
      failOnStatusCode: false
    });
  }

  async sendRaw(
    method: string,
    endpoint: string,
    body: string,
    token?: unknown
  ): Promise<APIResponse> {
    return this.request.fetch(endpoint, {
      method,
      data: body,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${String(token)}` } : {})
      },
      failOnStatusCode: false
    });
  }
}
