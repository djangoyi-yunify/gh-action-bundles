"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.getPullRequestContext = getPullRequestContext;
exports.createPullRequestReview = createPullRequestReview;
exports.createIssueComment = createIssueComment;
exports.getPullRequest = getPullRequest;
exports.getMergeBase = getMergeBase;
exports.parseRepo = parseRepo;
const exec_1 = require("./exec");
async function getPullRequestContext(repo, prNumber, token) {
    const { stdout } = await (0, exec_1.execCapture)('gh', [
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
async function ghApiPost(repo, token, endpoint, payload) {
    const { writeFileSync, unlinkSync } = await Promise.resolve().then(() => __importStar(require('fs')));
    const { tmpdir } = await Promise.resolve().then(() => __importStar(require('os')));
    const { join } = await Promise.resolve().then(() => __importStar(require('path')));
    const tmpFile = join(tmpdir(), `ocr-api-payload-${Date.now()}.json`);
    writeFileSync(tmpFile, JSON.stringify(payload));
    try {
        const { stdout } = await (0, exec_1.execCapture)('gh', [
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
    }
    finally {
        try {
            unlinkSync(tmpFile);
        }
        catch {
            // ignore
        }
    }
}
async function createPullRequestReview(repo, prNumber, token, commitId, body, comments) {
    return ghApiPost(repo, token, `repos/${repo}/pulls/${prNumber}/reviews`, {
        commit_id: commitId,
        body,
        event: 'COMMENT',
        comments,
    });
}
async function createIssueComment(repo, issueNumber, token, body) {
    return ghApiPost(repo, token, `repos/${repo}/issues/${issueNumber}/comments`, { body });
}
async function getPullRequest(repo, prNumber, token) {
    const { stdout } = await (0, exec_1.execCapture)('gh', [
        'api',
        `--header=Authorization: token ${token}`,
        `repos/${repo}/pulls/${prNumber}`,
    ], {
        env: { GH_TOKEN: token },
    });
    const data = JSON.parse(stdout);
    return { headSha: data.head.sha };
}
async function getMergeBase(repo, baseRef, headSha, token) {
    const { stdout } = await (0, exec_1.execCapture)('gh', [
        'api',
        `--header=Authorization: token ${token}`,
        `repos/${repo}/compare/${baseRef}...${headSha}`,
    ], {
        env: { GH_TOKEN: token },
    });
    const data = JSON.parse(stdout);
    if (!data.merge_base_commit || !data.merge_base_commit.sha) {
        throw new Error(`Could not determine merge base for ${baseRef}...${headSha}`);
    }
    return data.merge_base_commit.sha;
}
function parseRepo(repository) {
    const [owner, repoName] = repository.split('/');
    if (!owner || !repoName) {
        throw new Error(`Invalid repository format: ${repository}`);
    }
    return { owner, repo: repoName };
}
