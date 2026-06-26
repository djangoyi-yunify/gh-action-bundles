import {
  createIssueComment,
  createPullRequestReview,
  getEnv,
  getPullRequest,
  log,
  parseOcrOutput,
  setOutput,
  splitComments,
  buildSummaryBody,
} from '@gh-action-bundles/shared';
import { readFileSync } from 'fs';

const RESULT_PATH = '/tmp/ocr-result.json';
const STDERR_PATH = '/tmp/ocr-stderr.log';

async function main(): Promise<void> {
  const repo = getEnv('GITHUB_REPOSITORY');
  const prNumber = parseInt(getEnv('PR_NUMBER'), 10);
  const token = getEnv('GITHUB_TOKEN');

  let resultRaw = '';
  try {
    resultRaw = readFileSync(RESULT_PATH, 'utf8');
  } catch {
    resultRaw = '';
  }

  if (!resultRaw.trim()) {
    let body = '⚠️ **OpenCodeReview** produced no output.';
    try {
      const stderr = readFileSync(STDERR_PATH, 'utf8').trim();
      if (stderr) {
        body += '\n\n```\n' + stderr + '\n```';
      }
    } catch {
      // ignore
    }
    await createIssueComment(repo, prNumber, token, body);
    setOutput('review-count', '0');
    setOutput('inline-count', '0');
    setOutput('summary-count', '0');
    setOutput('failed-count', '0');
    return;
  }

  let result;
  try {
    result = parseOcrOutput(resultRaw);
  } catch (error) {
    let body = '⚠️ **OpenCodeReview** failed to parse output.';
    try {
      const stderr = readFileSync(STDERR_PATH, 'utf8').trim();
      if (stderr) {
        body += '\n\n```\n' + stderr + '\n```';
      }
    } catch {
      // ignore
    }
    await createIssueComment(repo, prNumber, token, body);
    throw error;
  }

  const comments = result.comments || [];
  const { inline, summary } = splitComments(comments);

  let inlineCount = 0;
  let summaryCount = summary.length;
  let failedCount = 0;

  if (inline.length > 0) {
    try {
      const pr = await getPullRequest(repo, prNumber, token);
      await createPullRequestReview(repo, prNumber, token, pr.headSha, '', inline);
      inlineCount = inline.length;
      log.info(`Posted ${inline.length} inline comments`);
    } catch (error) {
      log.warning(`Failed to post batch review: ${error instanceof Error ? error.message : String(error)}`);
      // Fallback: post inline comments as summary
      summary.unshift(...inline.map((c) => ({
        path: c.path,
        start_line: c.start_line || c.line,
        end_line: c.line,
        content: c.body,
      })));
      summaryCount = summary.length;
      inlineCount = 0;
      failedCount = inline.length;
    }
  }

  if (summary.length > 0 || (result.message && result.message.trim() !== '')) {
    const totalCount = comments.length;
    const body = buildSummaryBody(
      totalCount,
      inlineCount,
      summaryCount,
      result.message || '',
      summary
    );
    await createIssueComment(repo, prNumber, token, body);
  }

  setOutput('review-count', String(comments.length));
  setOutput('inline-count', String(inlineCount));
  setOutput('summary-count', String(summaryCount));
  setOutput('failed-count', String(failedCount));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
