"use strict";
var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __commonJS = (cb, mod) => function __require() {
  return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));

// ../../packages/shared/dist/log.js
var require_log = __commonJS({
  "../../packages/shared/dist/log.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.log = void 0;
    exports2.info = info;
    exports2.error = error;
    exports2.warning = warning;
    exports2.debug = debug;
    function info(message) {
      console.log(message);
    }
    function error(message) {
      console.log(`::error::${message}`);
    }
    function warning(message) {
      console.log(`::warning::${message}`);
    }
    function debug(message) {
      if (process.env.RUNNER_DEBUG === "1" || process.env.ACTIONS_STEP_DEBUG === "true") {
        console.log(`::debug::${message}`);
      }
    }
    exports2.log = { info, error, warning, debug };
  }
});

// ../../packages/shared/dist/exec.js
var require_exec = __commonJS({
  "../../packages/shared/dist/exec.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.exec = exec2;
    exports2.execCapture = execCapture;
    var child_process_1 = require("child_process");
    var log_1 = require_log();
    function exec2(command, args = [], options = {}) {
      return new Promise((resolve, reject) => {
        log_1.log.info(`$ ${command} ${args.map((a) => a.includes(" ") ? `"${a}"` : a).join(" ")}`);
        const child = (0, child_process_1.spawn)(command, args, {
          cwd: options.cwd,
          env: { ...process.env, ...options.env },
          stdio: ["ignore", "pipe", "pipe"]
        });
        let stdout = "";
        let stderr = "";
        child.stdout.on("data", (data) => {
          const chunk = data.toString();
          stdout += chunk;
          process.stdout.write(chunk);
        });
        child.stderr.on("data", (data) => {
          const chunk = data.toString();
          stderr += chunk;
          process.stderr.write(chunk);
        });
        child.on("error", reject);
        child.on("close", (exitCode) => {
          const result = { stdout, stderr, exitCode: exitCode ?? 0 };
          if (exitCode !== 0 && !options.ignoreExitCode) {
            reject(new Error(`Command failed with exit code ${exitCode}: ${stderr || stdout}`));
          } else {
            resolve(result);
          }
        });
      });
    }
    function execCapture(command, args = [], options = {}) {
      return new Promise((resolve, reject) => {
        log_1.log.info(`$ ${command} ${args.map((a) => a.includes(" ") ? `"${a}"` : a).join(" ")}`);
        const child = (0, child_process_1.spawn)(command, args, {
          cwd: options.cwd,
          env: { ...process.env, ...options.env },
          stdio: ["ignore", "pipe", "pipe"]
        });
        let stdout = "";
        let stderr = "";
        child.stdout.on("data", (data) => {
          stdout += data.toString();
        });
        child.stderr.on("data", (data) => {
          stderr += data.toString();
        });
        child.on("error", reject);
        child.on("close", (exitCode) => {
          const result = { stdout: stdout.trim(), stderr: stderr.trim(), exitCode: exitCode ?? 0 };
          if (exitCode !== 0 && !options.ignoreExitCode) {
            reject(new Error(`Command failed with exit code ${exitCode}: ${stderr || stdout}`));
          } else {
            resolve(result);
          }
        });
      });
    }
  }
});

// ../../packages/shared/dist/env.js
var require_env = __commonJS({
  "../../packages/shared/dist/env.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.setOutput = setOutput;
    exports2.setEnv = setEnv;
    exports2.getEnv = getEnv2;
    exports2.getEnvBool = getEnvBool;
    var fs_1 = require("fs");
    function setOutput(name, value) {
      const file = process.env.GITHUB_OUTPUT;
      if (!file) {
        throw new Error("GITHUB_OUTPUT is not defined");
      }
      (0, fs_1.appendFileSync)(file, `${name}=${value}
`);
    }
    function setEnv(name, value) {
      const file = process.env.GITHUB_ENV;
      if (!file) {
        throw new Error("GITHUB_ENV is not defined");
      }
      (0, fs_1.appendFileSync)(file, `${name}=${value}
`);
    }
    function getEnv2(name, required = true) {
      const value = process.env[name] || "";
      if (required && value === "") {
        throw new Error(`Environment variable ${name} is required`);
      }
      return value;
    }
    function getEnvBool(name, defaultValue = false) {
      const value = process.env[name];
      if (value === void 0)
        return defaultValue;
      return value === "true" || value === "1";
    }
  }
});

// ../../packages/shared/dist/github.js
var require_github = __commonJS({
  "../../packages/shared/dist/github.js"(exports2) {
    "use strict";
    var __createBinding = exports2 && exports2.__createBinding || (Object.create ? function(o, m, k, k2) {
      if (k2 === void 0) k2 = k;
      var desc = Object.getOwnPropertyDescriptor(m, k);
      if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
        desc = { enumerable: true, get: function() {
          return m[k];
        } };
      }
      Object.defineProperty(o, k2, desc);
    } : function(o, m, k, k2) {
      if (k2 === void 0) k2 = k;
      o[k2] = m[k];
    });
    var __setModuleDefault = exports2 && exports2.__setModuleDefault || (Object.create ? function(o, v) {
      Object.defineProperty(o, "default", { enumerable: true, value: v });
    } : function(o, v) {
      o["default"] = v;
    });
    var __importStar = exports2 && exports2.__importStar || /* @__PURE__ */ function() {
      var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function(o2) {
          var ar = [];
          for (var k in o2) if (Object.prototype.hasOwnProperty.call(o2, k)) ar[ar.length] = k;
          return ar;
        };
        return ownKeys(o);
      };
      return function(mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) {
          for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        }
        __setModuleDefault(result, mod);
        return result;
      };
    }();
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.getPullRequestContext = getPullRequestContext;
    exports2.createPullRequestReview = createPullRequestReview;
    exports2.createIssueComment = createIssueComment;
    exports2.getPullRequest = getPullRequest;
    exports2.getMergeBase = getMergeBase;
    exports2.parseRepo = parseRepo;
    var exec_1 = require_exec();
    async function getPullRequestContext(repo, prNumber, token) {
      const { stdout } = await (0, exec_1.execCapture)("gh", [
        "pr",
        "view",
        String(prNumber),
        "--repo",
        repo,
        "--json",
        "number,baseRefName,headRefOid,title,body"
      ], {
        env: { GH_TOKEN: token }
      });
      const data = JSON.parse(stdout);
      return {
        number: data.number,
        baseRef: data.baseRefName,
        headSha: data.headRefOid,
        title: data.title || "",
        body: data.body || ""
      };
    }
    async function ghApiPost(repo, token, endpoint, payload) {
      const { writeFileSync, unlinkSync } = await Promise.resolve().then(() => __importStar(require("fs")));
      const { tmpdir } = await Promise.resolve().then(() => __importStar(require("os")));
      const { join } = await Promise.resolve().then(() => __importStar(require("path")));
      const tmpFile = join(tmpdir(), `ocr-api-payload-${Date.now()}.json`);
      writeFileSync(tmpFile, JSON.stringify(payload));
      try {
        const { stdout } = await (0, exec_1.execCapture)("gh", [
          "api",
          `--header=Authorization: token ${token}`,
          "--method=POST",
          endpoint,
          "--input",
          tmpFile
        ], {
          env: { GH_TOKEN: token }
        });
        return stdout ? JSON.parse(stdout) : {};
      } finally {
        try {
          unlinkSync(tmpFile);
        } catch {
        }
      }
    }
    async function createPullRequestReview(repo, prNumber, token, commitId, body, comments) {
      return ghApiPost(repo, token, `repos/${repo}/pulls/${prNumber}/reviews`, {
        commit_id: commitId,
        body,
        event: "COMMENT",
        comments
      });
    }
    async function createIssueComment(repo, issueNumber, token, body) {
      return ghApiPost(repo, token, `repos/${repo}/issues/${issueNumber}/comments`, { body });
    }
    async function getPullRequest(repo, prNumber, token) {
      const { stdout } = await (0, exec_1.execCapture)("gh", [
        "api",
        `--header=Authorization: token ${token}`,
        `repos/${repo}/pulls/${prNumber}`
      ], {
        env: { GH_TOKEN: token }
      });
      const data = JSON.parse(stdout);
      return { headSha: data.head.sha };
    }
    async function getMergeBase(repo, baseRef, headSha, token) {
      const { stdout } = await (0, exec_1.execCapture)("gh", [
        "api",
        `--header=Authorization: token ${token}`,
        `repos/${repo}/compare/${baseRef}...${headSha}`
      ], {
        env: { GH_TOKEN: token }
      });
      const data = JSON.parse(stdout);
      if (!data.merge_base_commit || !data.merge_base_commit.sha) {
        throw new Error(`Could not determine merge base for ${baseRef}...${headSha}`);
      }
      return data.merge_base_commit.sha;
    }
    function parseRepo(repository) {
      const [owner, repoName] = repository.split("/");
      if (!owner || !repoName) {
        throw new Error(`Invalid repository format: ${repository}`);
      }
      return { owner, repo: repoName };
    }
  }
});

// ../../packages/shared/dist/review.js
var require_review = __commonJS({
  "../../packages/shared/dist/review.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.parseOcrOutput = parseOcrOutput;
    exports2.formatCommentBody = formatCommentBody;
    exports2.buildInlineComment = buildInlineComment;
    exports2.splitComments = splitComments;
    exports2.formatSummaryComment = formatSummaryComment;
    exports2.buildSummaryBody = buildSummaryBody;
    function parseOcrOutput(raw) {
      if (!raw || raw.trim() === "") {
        return { status: "success", message: "", comments: [] };
      }
      return JSON.parse(raw);
    }
    function formatCommentBody(comment) {
      let body = comment.content || "";
      if (comment.suggestion_code && comment.existing_code) {
        body += "\n\n**Suggestion:**\n```suggestion\n" + comment.suggestion_code + "\n```";
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
        start_side: "RIGHT",
        side: "RIGHT"
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
        } else {
          summary.push(comment);
        }
      }
      return { inline, summary };
    }
    function formatSummaryComment(comment) {
      let md = `### \`${comment.path}\``;
      if (comment.start_line && comment.end_line) {
        md += ` (L${comment.start_line}-L${comment.end_line})`;
      } else if (comment.end_line) {
        md += ` (L${comment.end_line})`;
      }
      md += "\n\n";
      md += comment.content || "";
      if (comment.suggestion_code && comment.existing_code) {
        md += "\n\n<details><summary>Suggested Change</summary>\n\n";
        md += "**Before:**\n```\n" + comment.existing_code + "\n```\n\n";
        md += "**After:**\n```\n" + comment.suggestion_code + "\n```\n\n";
        md += "</details>";
      }
      return md;
    }
    function buildSummaryBody(totalCount, inlineCount, summaryCount, message, summaryComments) {
      let body = message || `OpenCodeReview found **${totalCount}** issue(s) in this PR.`;
      if (totalCount > 0) {
        body += `
- ${inlineCount} posted as inline comment(s)`;
        body += `
- ${summaryCount} posted as summary`;
      }
      for (const comment of summaryComments) {
        body += "\n\n---\n\n";
        body += formatSummaryComment(comment);
      }
      return body;
    }
  }
});

// ../../packages/shared/dist/index.js
var require_dist = __commonJS({
  "../../packages/shared/dist/index.js"(exports2) {
    "use strict";
    var __createBinding = exports2 && exports2.__createBinding || (Object.create ? function(o, m, k, k2) {
      if (k2 === void 0) k2 = k;
      var desc = Object.getOwnPropertyDescriptor(m, k);
      if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
        desc = { enumerable: true, get: function() {
          return m[k];
        } };
      }
      Object.defineProperty(o, k2, desc);
    } : function(o, m, k, k2) {
      if (k2 === void 0) k2 = k;
      o[k2] = m[k];
    });
    var __exportStar = exports2 && exports2.__exportStar || function(m, exports3) {
      for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports3, p)) __createBinding(exports3, m, p);
    };
    Object.defineProperty(exports2, "__esModule", { value: true });
    __exportStar(require_exec(), exports2);
    __exportStar(require_env(), exports2);
    __exportStar(require_github(), exports2);
    __exportStar(require_log(), exports2);
    __exportStar(require_review(), exports2);
  }
});

// src/configure.ts
var import_shared = __toESM(require_dist());
async function main() {
  const url = (0, import_shared.getEnv)("OCR_LLM_URL");
  const token = (0, import_shared.getEnv)("OCR_LLM_TOKEN");
  const model = (0, import_shared.getEnv)("OCR_LLM_MODEL");
  const useAnthropic = (0, import_shared.getEnv)("OCR_USE_ANTHROPIC", false) || "false";
  const extraBody = (0, import_shared.getEnv)("OCR_EXTRA_BODY", false) || '{"thinking": {"type": "disabled"}}';
  await (0, import_shared.exec)("ocr", ["config", "set", "llm.url", url]);
  await (0, import_shared.exec)("ocr", ["config", "set", "llm.auth_token", token]);
  await (0, import_shared.exec)("ocr", ["config", "set", "llm.model", model]);
  await (0, import_shared.exec)("ocr", ["config", "set", "llm.use_anthropic", useAnthropic]);
  if (extraBody) {
    await (0, import_shared.exec)("ocr", ["config", "set", "llm.extra_body", extraBody]);
  }
}
main().catch((error) => {
  console.error(error);
  process.exit(1);
});
