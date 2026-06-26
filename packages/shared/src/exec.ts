import { spawn } from 'child_process';
import { log } from './log';

export interface ExecOptions {
  cwd?: string;
  env?: NodeJS.ProcessEnv;
  ignoreExitCode?: boolean;
}

export interface ExecResult {
  stdout: string;
  stderr: string;
  exitCode: number;
}

export function exec(command: string, args: string[] = [], options: ExecOptions = {}): Promise<ExecResult> {
  return new Promise((resolve, reject) => {
    log.info(`$ ${command} ${args.map(a => (a.includes(' ') ? `"${a}"` : a)).join(' ')}`);

    const child = spawn(command, args, {
      cwd: options.cwd,
      env: { ...process.env, ...options.env },
      stdio: ['ignore', 'pipe', 'pipe'],
    });

    let stdout = '';
    let stderr = '';

    child.stdout.on('data', (data: Buffer) => {
      const chunk = data.toString();
      stdout += chunk;
      process.stdout.write(chunk);
    });

    child.stderr.on('data', (data: Buffer) => {
      const chunk = data.toString();
      stderr += chunk;
      process.stderr.write(chunk);
    });

    child.on('error', reject);

    child.on('close', (exitCode) => {
      const result: ExecResult = { stdout, stderr, exitCode: exitCode ?? 0 };
      if (exitCode !== 0 && !options.ignoreExitCode) {
        reject(new Error(`Command failed with exit code ${exitCode}: ${stderr || stdout}`));
      } else {
        resolve(result);
      }
    });
  });
}

export function execCapture(command: string, args: string[] = [], options: ExecOptions = {}): Promise<ExecResult> {
  return new Promise((resolve, reject) => {
    log.info(`$ ${command} ${args.map(a => (a.includes(' ') ? `"${a}"` : a)).join(' ')}`);

    const child = spawn(command, args, {
      cwd: options.cwd,
      env: { ...process.env, ...options.env },
      stdio: ['ignore', 'pipe', 'pipe'],
    });

    let stdout = '';
    let stderr = '';

    child.stdout.on('data', (data: Buffer) => {
      stdout += data.toString();
    });

    child.stderr.on('data', (data: Buffer) => {
      stderr += data.toString();
    });

    child.on('error', reject);

    child.on('close', (exitCode) => {
      const result: ExecResult = { stdout: stdout.trim(), stderr: stderr.trim(), exitCode: exitCode ?? 0 };
      if (exitCode !== 0 && !options.ignoreExitCode) {
        reject(new Error(`Command failed with exit code ${exitCode}: ${stderr || stdout}`));
      } else {
        resolve(result);
      }
    });
  });
}
