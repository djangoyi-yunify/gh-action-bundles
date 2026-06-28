import { getEnv, log } from '@gh-action-bundles/shared';
import { existsSync } from 'fs';
import { spawn } from 'child_process';

const RESULT_PATH = '/tmp/ocr-result.json';
const STDERR_PATH = '/tmp/ocr-stderr.log';

async function main(): Promise<void> {
  const baseRef = getEnv('OCR_BASE_REF');
  const headSha = getEnv('OCR_HEAD_SHA');
  const mergeBase = getEnv('OCR_MERGE_BASE');

  log.info(`Review range: origin/${baseRef}...${headSha}, merge-base: ${mergeBase}`);

  const args = [
    'review',
    '--from', mergeBase,
    '--to', headSha,
    '--format', 'json',
  ];

  const concurrency = getEnv('CONCURRENCY', false);
  if (concurrency) {
    args.push('--concurrency', concurrency);
  }

  const timeout = getEnv('TIMEOUT', false);
  if (timeout) {
    args.push('--timeout', timeout);
  }

  const rulePath = getEnv('RULE_PATH', false);
  if (rulePath) {
    if (!existsSync(rulePath)) {
      throw new Error(`Rule file not found: ${rulePath}`);
    }
    args.push('--rule', rulePath);
  }

  const exclude = getEnv('EXCLUDE', false);
  if (exclude) {
    args.push('--exclude', exclude);
  }

  const background = getEnv('BACKGROUND', false);
  if (background) {
    args.push('--background', background);
  }

  log.info(`Running: ocr ${args.join(' ')}`);

  const { createWriteStream } = await import('fs');
  const stdoutStream = createWriteStream(RESULT_PATH);
  const stderrStream = createWriteStream(STDERR_PATH);

  await new Promise<void>((resolve, reject) => {
    const child = spawn('ocr', args, {
      stdio: ['ignore', 'pipe', 'pipe'],
    });

    child.stdout.pipe(stdoutStream);
    child.stderr.pipe(stderrStream);

    child.on('error', reject);
    child.on('close', (code) => {
      stdoutStream.end();
      stderrStream.end();
      if (code !== 0) {
        log.warning(`OCR exited with code ${code}`);
      }
      resolve();
    });
  });
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
