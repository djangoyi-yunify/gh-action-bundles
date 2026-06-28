## Context

`gh-action-bundles` 目标是提供多个可复用的 GitHub Composite Actions 来自动化项目管理。当前 `actions/` 目录为空，需要先落地第一个 action。经过调研，决定基于 `alibaba/open-code-review`（OCR）实现 PR 代码审查 action，因为 OCR 是专用于代码审查的确定性 CLI 工具，比通用 Agent 更适合单一、高确定性的审查场景。

## Goals / Non-Goals

**Goals:**
- 提供 `actions/ocr-review` Composite Action，封装 OCR 的完整 PR 审查流程。
- 调用方只需配置触发条件、LLM 凭证和 PR 编号即可使用。
- 自动推断 `base-ref` 与 `head-sha`，无需调用方手动计算。
- 解析 OCR JSON 输出，批量发布 GitHub PR inline review comments，失败时退化为逐条发布。
- 建立 monorepo 结构，沉淀可复用的共享工具库，为后续 action 做准备。

**Non-Goals:**
- 不处理 action 触发事件的选择（如 `pull_request` vs `pull_request_target`），由调用方 workflow 决定。
- 不支持 OCR 的 `scan` 模式（全文件扫描），本 action 仅支持 `ocr review`（PR diff 审查）。
- 不提供复杂的权限沙箱（OCR 是确定性 CLI，非通用 Agent，不需要 opencode-pr-reviewer 级别的权限白名单）。
- 不自动创建或复制默认 rule 文件，依赖 OCR 原生 rule 优先级链。

## Decisions

### 1. Action 命名：actions/ocr-review
采用 `<tool>-<function>` 命名模式，便于与后续 `opencode-review`、`ocr-scan` 等 action 区分。

### 2. 技术栈：Node.js / TypeScript + pnpm workspace + esbuild
团队决定使用 Node.js 实现。pnpm workspace 管理 monorepo，esbuild 将每个 step 脚本及其共享库依赖打包为独立的 `dist/*.js`，确保 action 运行时无需安装 npm 依赖。

### 3. 安装 OCR：npm install -g @alibaba-group/open-code-review
与 OCR 官方 GitHub Actions 示例保持一致，最简单且跨平台。

### 4. 配置 LLM：ocr config set
与官方示例一致，使用 `ocr config set llm.url`、`llm.auth_token`、`llm.model`、`llm.use_anthropic`、`llm.extra_body`。

### 5. PR 上下文推断：由 pr-number 自动获取
Composite Action 内部通过 `gh pr view ${PR_NUMBER} --json baseRefName,headRefOid` 推断 `base-ref` 和 `head-sha`，减少调用方负担。使用 SHA 而非分支名以支持 fork PR。

### 6. rule-path：可选，默认留空
`rule-path` 非空时传入 `ocr review --rule`，并做文件存在性检查；留空时 OCR 按自身优先级链（`.opencodereview/rule.json`、全局 rule、系统默认）处理。

### 7. background：可选字符串
非空时传给 `ocr review --background`，留空时不传。参照官方示例，不自动从 PR title 填充。

### 8. 输出发布：解析 JSON 后批量发布 PR review
使用 GitHub Pull Request Review API 批量创建 inline comments；失败时退化为逐条发布并记录统计。无 inline comments 但 OCR `message` 有值时，发布 summary comment。

### 9. 共享代码组织：packages/shared
抽象 `exec`、`github`、`env`、`review`、`log` 等模块，供当前及未来 action 复用。

## Risks / Trade-offs

- **Risk**: `npm install -g` 每次运行都重新安装 OCR，增加 CI 时间。
  - **Mitigation**: 后续可考虑缓存策略或切换到 release 二进制安装，但首版保持与官方示例一致。
- **Risk**: `gh pr view` 需要正确的 git remote 和 GITHUB_TOKEN 权限。
  - **Mitigation**: 文档中明确要求调用方 workflow 设置 `permissions: pull-requests: write` 并先 checkout 代码。
- **Risk**: GitHub PR Review API 对行号要求严格，部分 inline comments 可能发布失败。
  - **Mitigation**: 实现 fallback 到 summary comment，确保反馈不丢失。
- **Risk**: 多 action 共享库版本管理复杂。
  - **Mitigation**: 使用 pnpm workspace，构建时把共享代码内联到每个 action 的 dist 中，避免运行时版本冲突。

## Migration Plan

无迁移成本，本 change 为新增功能，不影响现有代码。

## Open Questions

- 后续是否需要为 `ocr-review` 添加缓存 OCR 安装的能力？
- 是否需要将 rate-limit 重试参数（max-retries、success-delay 等）暴露为 action inputs？
