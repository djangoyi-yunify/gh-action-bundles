import { exec, getEnv } from '@gh-action-bundles/shared';

async function main(): Promise<void> {
  const url = getEnv('OCR_LLM_URL');
  const token = getEnv('OCR_LLM_TOKEN');
  const model = getEnv('OCR_LLM_MODEL');
  const useAnthropic = getEnv('OCR_USE_ANTHROPIC', false) || 'false';
  const extraBody = getEnv('OCR_EXTRA_BODY', false) || '{"thinking": {"type": "disabled"}}';

  await exec('ocr', ['config', 'set', 'llm.url', url]);
  await exec('ocr', ['config', 'set', 'llm.auth_token', token]);
  await exec('ocr', ['config', 'set', 'llm.model', model]);
  await exec('ocr', ['config', 'set', 'llm.use_anthropic', useAnthropic]);

  if (extraBody) {
    await exec('ocr', ['config', 'set', 'llm.extra_body', extraBody]);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
