import { appendFileSync } from 'fs';

export function setOutput(name: string, value: string): void {
  const file = process.env.GITHUB_OUTPUT;
  if (!file) {
    throw new Error('GITHUB_OUTPUT is not defined');
  }
  appendFileSync(file, `${name}=${value}\n`);
}

export function setEnv(name: string, value: string): void {
  const file = process.env.GITHUB_ENV;
  if (!file) {
    throw new Error('GITHUB_ENV is not defined');
  }
  appendFileSync(file, `${name}=${value}\n`);
}

export function getEnv(name: string, required = true): string {
  const value = process.env[name] || '';
  if (required && value === '') {
    throw new Error(`Environment variable ${name} is required`);
  }
  return value;
}

export function getEnvBool(name: string, defaultValue = false): boolean {
  const value = process.env[name];
  if (value === undefined) return defaultValue;
  return value === 'true' || value === '1';
}
