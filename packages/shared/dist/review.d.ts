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
export declare function parseOcrOutput(raw: string): OcrJsonOutput;
export declare function formatCommentBody(comment: OcrComment): string;
export declare function buildInlineComment(comment: OcrComment): InlineComment | null;
export declare function splitComments(comments: OcrComment[]): {
    inline: InlineComment[];
    summary: OcrComment[];
};
export declare function formatSummaryComment(comment: OcrComment): string;
export declare function buildSummaryBody(totalCount: number, inlineCount: number, summaryCount: number, message: string, summaryComments: OcrComment[]): string;
