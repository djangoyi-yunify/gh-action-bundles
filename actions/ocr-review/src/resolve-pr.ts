import { getPullRequestContext, getMergeBase, setOutput, getEnv, log } from '@gh-action-bundles/shared';

async function main(): Promise<void> {
  const repo = getEnv('GITHUB_REPOSITORY');
  const prNumber = parseInt(getEnv('PR_NUMBER'), 10);
  const token = getEnv('GITHUB_TOKEN');

  if (Number.isNaN(prNumber) || prNumber <= 0) {
    throw new Error(`Invalid PR number: ${getEnv('PR_NUMBER')}`);
  }

  log.info(`Resolving PR context for ${repo}#${prNumber}`);
  const pr = await getPullRequestContext(repo, prNumber, token);

  log.info(`base-ref: ${pr.baseRef}`);
  log.info(`head-sha: ${pr.headSha}`);

  const mergeBase = await getMergeBase(repo, pr.baseRef, pr.headSha, token);
  log.info(`merge-base: ${mergeBase}`);

  setOutput('base-ref', pr.baseRef);
  setOutput('head-sha', pr.headSha);
  setOutput('merge-base', mergeBase);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
