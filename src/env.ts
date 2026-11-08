import dotenv from 'dotenv';
import { resolve } from 'node:path';

dotenv.config({
  path: resolve(process.cwd(), 'credentials', 'credentials.env')
});

export const env = {
  baseUrl: process.env.API_BASE_URL ?? 'http://localhost:8080',
  loginEndpoint: process.env.LOGIN_ENDPOINT ?? '/api/auth/login',
  loginTokenJsonPath: process.env.LOGIN_TOKEN_JSON_PATH ?? 'accessToken'
};
