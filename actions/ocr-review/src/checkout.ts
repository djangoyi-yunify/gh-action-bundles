import { getPullRequestCheckoutInfo, exec, getEnv, getEnvBool, log } from '@gh-action-bundles/shared';

function isEnabled(): boolean {
  return getEnvBool('AUTO_CHECKOUT', true);
}

function isPullRequestEvent(): boolean {
  const eventName = getEnv('GITHUB_EVENT_NAME');
  return eventName === 'pull_request' || eventName === 'issue_comment';
}

function generateLocalBranchName(prNumber: number): string {
  const timestamp = new Date()
    .toISOString()
    .replace(/[:-]/g, '')
    .replace(/\.\d{3}Z/, '')
    .split('T')
    .join('');
  return `ocr-review/pr${prNumber}-${timestamp}`;
}

async function setupGitCredentials(): Promise<void> {
  // actions/checkout runs with persist-credentials: false, so configure git
  // to use the GitHub CLI (authenticated via GH_TOKEN) for HTTPS operations.
  await exec('gh', ['auth', 'setup-git', '--hostname', 'github.com']);
}

async function main(): Promise<void> {
  if (!isEnabled()) {
    log.info('AUTO_CHECKOUT is disabled; skipping checkout');
    return;
  }

  if (!isPullRequestEvent()) {
    log.info(`Skipping checkout for non-PR event: ${getEnv('GITHUB_EVENT_NAME')}`);
    return;
  }

  const repo = getEnv('GITHUB_REPOSITORY');
  const prNumber = parseInt(getEnv('PR_NUMBER'), 10);
  const token = getEnv('GITHUB_TOKEN');

  if (Number.isNaN(prNumber) || prNumber <= 0) {
    throw new Error(`Invalid PR number: ${getEnv('PR_NUMBER')}`);
  }

  await setupGitCredentials();

  log.info(`Resolving checkout info for ${repo}#${prNumber}`);
  const info = await getPullRequestCheckoutInfo(repo, prNumber, token);

  log.info(`head-ref: ${info.headRefName}`);
  log.info(`head-repository: ${info.headRepository.nameWithOwner}`);
  log.info(`cross-repository: ${info.isCrossRepository}`);

  if (info.isCrossRepository) {
    log.info('Checking out fork PR branch');
    const localBranch = generateLocalBranchName(prNumber);
    const depth = Math.max(info.commitCount + 1, 20);

    await exec('git', [
      'remote', 'add', 'fork', `https://github.com/${info.headRepository.nameWithOwner}.git`,
    ]);
    await exec('git', [
      'fetch', 'fork', `--depth=${depth}`, info.headRefName,
    ]);
    await exec('git', [
      'checkout', '-b', localBranch, `fork/${info.headRefName}`,
    ]);
    log.info(`Checked out fork branch as ${localBranch}`);
  } else {
    log.info('Checking out same-repo PR branch');
    await exec('git', ['fetch', 'origin', `${info.headRefName}:${info.headRefName}`]);
    await exec('git', ['checkout', info.headRefName]);
    log.info(`Checked out origin/${info.headRefName}`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
