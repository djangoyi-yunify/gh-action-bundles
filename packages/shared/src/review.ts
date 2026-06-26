export interface OcrComment {
  path: string;
  start_line: number;
  end_line: number;
  content: string;
  suggestion_code?: string;
  existing_code?: string;
}

export interface OcrWarning {
  type: string;
  file: string;
  message: string;
}

export interface OcrJsonOutput {
  status: string;
  message?: string;
  comments: OcrComment[];
  warnings?: OcrWarning[];
}

export interface ParsedReview {
  status: string;
  message: string;
  comments: OcrComment[];
  warnings: OcrWarning[];
  inlineComments: InlineComment[];
  summaryComments: OcrComment[];
}

export interface InlineComment {
  path: string;
  body: string;
  line: number;
  start_line?: number;
  start_side: 'RIGHT';
  side: 'RIGHT';
}

export function parseOcrOutput(raw: string): OcrJsonOutput {
  if (!raw || raw.trim() === '') {
    return { status: 'success', message: '', comments: [] };
  }
  return JSON.parse(raw) as OcrJsonOutput;
}

export function formatCommentBody(comment: OcrComment): string {
  let body = comment.content || '';

  if (comment.suggestion_code && comment.existing_code) {
    body += '\n\n**Suggestion:**\n```suggestion\n' + comment.suggestion_code + '\n```';
  }

  return body;
}

export function buildInlineComment(comment: OcrComment): InlineComment | null {
  const hasStart = comment.start_line >= 1;
  const hasEnd = comment.end_line >= 1;

  if (!hasStart && !hasEnd) {
    return null;
  }

  const inline: InlineComment = {
    path: comment.path,
    body: formatCommentBody(comment),
    line: comment.end_line || comment.start_line,
    start_side: 'RIGHT',
    side: 'RIGHT',
  };

  if (hasStart && hasEnd && comment.start_line !== comment.end_line) {
    inline.start_line = comment.start_line;
  }

  return inline;
}

export function splitComments(comments: OcrComment[]): { inline: InlineComment[]; summary: OcrComment[] } {
  const inline: InlineComment[] = [];
  const summary: OcrComment[] = [];

  for (const comment of comments) {
    const inlineComment = buildInlineComment(comment);
    if (inlineComment) {
      inline.push(inlineComment);
    } else {
      summary.push(comment);
    }
  }

  return { inline, summary };
}

export function formatSummaryComment(comment: OcrComment): string {
  let md = `### \`${comment.path}\``;
  if (comment.start_line && comment.end_line) {
    md += ` (L${comment.start_line}-L${comment.end_line})`;
  } else if (comment.end_line) {
    md += ` (L${comment.end_line})`;
  }
  md += '\n\n';
  md += comment.content || '';

  if (comment.suggestion_code && comment.existing_code) {
    md += '\n\n<details><summary>Suggested Change</summary>\n\n';
    md += '**Before:**\n```\n' + comment.existing_code + '\n```\n\n';
    md += '**After:**\n```\n' + comment.suggestion_code + '\n```\n\n';
    md += '</details>';
  }

  return md;
}

export function buildSummaryBody(
  totalCount: number,
  inlineCount: number,
  summaryCount: number,
  message: string,
  summaryComments: OcrComment[]
): string {
  let body = message || `OpenCodeReview found **${totalCount}** issue(s) in this PR.`;
  if (totalCount > 0) {
    body += `\n- ${inlineCount} posted as inline comment(s)`;
    body += `\n- ${summaryCount} posted as summary`;
  }

  for (const comment of summaryComments) {
    body += '\n\n---\n\n';
    body += formatSummaryComment(comment);
  }

  return body;
}
