"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseOcrOutput = parseOcrOutput;
exports.formatCommentBody = formatCommentBody;
exports.buildInlineComment = buildInlineComment;
exports.splitComments = splitComments;
exports.formatSummaryComment = formatSummaryComment;
exports.buildSummaryBody = buildSummaryBody;
function parseOcrOutput(raw) {
    if (!raw || raw.trim() === '') {
        return { status: 'success', message: '', comments: [] };
    }
    return JSON.parse(raw);
}
function formatCommentBody(comment) {
    let body = comment.content || '';
    if (comment.suggestion_code && comment.existing_code) {
        body += '\n\n**Suggestion:**\n```suggestion\n' + comment.suggestion_code + '\n```';
    }
    return body;
}
function buildInlineComment(comment) {
    const hasStart = comment.start_line >= 1;
    const hasEnd = comment.end_line >= 1;
    if (!hasStart && !hasEnd) {
        return null;
    }
    const inline = {
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
function splitComments(comments) {
    const inline = [];
    const summary = [];
    for (const comment of comments) {
        const inlineComment = buildInlineComment(comment);
        if (inlineComment) {
            inline.push(inlineComment);
        }
        else {
            summary.push(comment);
        }
    }
    return { inline, summary };
}
function formatSummaryComment(comment) {
    let md = `### \`${comment.path}\``;
    if (comment.start_line && comment.end_line) {
        md += ` (L${comment.start_line}-L${comment.end_line})`;
    }
    else if (comment.end_line) {
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
function buildSummaryBody(totalCount, inlineCount, summaryCount, message, summaryComments) {
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
