export interface PullRequestContext {
    number: number;
    baseRef: string;
    headSha: string;
    title: string;
    body: string;
}
export declare function getPullRequestContext(repo: string, prNumber: number, token: string): Promise<PullRequestContext>;
export interface ReviewComment {
    path: string;
    body: string;
    line?: number;
    start_line?: number;
    start_side?: 'RIGHT';
    side?: 'RIGHT';
}
export declare function createPullRequestReview(repo: string, prNumber: number, token: string, commitId: string, body: string, comments: ReviewComment[]): Promise<unknown>;
export declare function createIssueComment(repo: string, issueNumber: number, token: string, body: string): Promise<unknown>;
export declare function getPullRequest(repo: string, prNumber: number, token: string): Promise<{
    headSha: string;
}>;
export declare function parseRepo(repository: string): {
    owner: string;
    repo: string;
};
