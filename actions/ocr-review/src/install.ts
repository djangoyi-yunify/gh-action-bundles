import { exec, getEnv } from '@gh-action-bundles/shared';

async function main(): Promise<void> {
  const version = getEnv('OCR_VERSION', false) || 'latest';
  const packageSpec = version === 'latest'
    ? '@alibaba-group/open-code-review'
    : `@alibaba-group/open-code-review@${version}`;

  await exec('npm', ['install', '-g', packageSpec]);
  await exec('ocr', ['version']);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
