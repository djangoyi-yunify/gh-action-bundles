import { execCapture } from './exec';

export interface PullRequestContext {
  number: number;
  baseRef: string;
  headSha: string;
  title: string;
  body: string;
}

export async function getPullRequestContext(
  repo: string,
  prNumber: number,
  token: string
): Promise<PullRequestContext> {
  const { stdout } = await execCapture('gh', [
    'pr',
    'view',
    String(prNumber),
    '--repo',
    repo,
    '--json',
    'number,baseRefName,headRefOid,title,body',
  ], {
    env: { GH_TOKEN: token },
  });

  const data = JSON.parse(stdout);
  return {
    number: data.number,
    baseRef: data.baseRefName,
    headSha: data.headRefOid,
    title: data.title || '',
    body: data.body || '',
  };
}

export interface ReviewComment {
  path: string;
  body: string;
  line?: number;
  start_line?: number;
  start_side?: 'RIGHT';
  side?: 'RIGHT';
}

async function ghApiPost(repo: string, token: string, endpoint: string, payload: unknown): Promise<unknown> {
  const { writeFileSync, unlinkSync } = await import('fs');
  const { tmpdir } = await import('os');
  const { join } = await import('path');
  const tmpFile = join(tmpdir(), `ocr-api-payload-${Date.now()}.json`);

  writeFileSync(tmpFile, JSON.stringify(payload));

  try {
    const { stdout } = await execCapture('gh', [
      'api',
      `--header=Authorization: token ${token}`,
      '--method=POST',
      endpoint,
      '--input',
      tmpFile,
    ], {
      env: { GH_TOKEN: token },
    });
    return stdout ? JSON.parse(stdout) : {};
  } finally {
    try {
      unlinkSync(tmpFile);
    } catch {
      // ignore
    }
  }
}

export async function createPullRequestReview(
  repo: string,
  prNumber: number,
  token: string,
  commitId: string,
  body: string,
  comments: ReviewComment[]
): Promise<unknown> {
  return ghApiPost(repo, token, `repos/${repo}/pulls/${prNumber}/reviews`, {
    commit_id: commitId,
    body,
    event: 'COMMENT',
    comments,
  });
}

export async function createIssueComment(
  repo: string,
  issueNumber: number,
  token: string,
  body: string
): Promise<unknown> {
  return ghApiPost(repo, token, `repos/${repo}/issues/${issueNumber}/comments`, { body });
}

export async function getPullRequest(repo: string, prNumber: number, token: string): Promise<{ headSha: string }> {
  const { stdout } = await execCapture('gh', [
    'api',
    `--header=Authorization: token ${token}`,
    `repos/${repo}/pulls/${prNumber}`,
  ], {
    env: { GH_TOKEN: token },
  });

  const data = JSON.parse(stdout);
  return { headSha: data.head.sha };
}

export function parseRepo(repository: string): { owner: string; repo: string } {
  const [owner, repoName] = repository.split('/');
  if (!owner || !repoName) {
    throw new Error(`Invalid repository format: ${repository}`);
  }
  return { owner, repo: repoName };
}
