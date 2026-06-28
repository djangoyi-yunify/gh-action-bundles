## Why

项目 `gh-action-bundles` 旨在提供一组可复用的 GitHub Composite Actions，用于自动化项目管理（代码审查、代码修复、问题解答等）。目前 `actions/` 目录为空，缺少第一个可用的 action。引入基于 alibaba/open-code-review 的 PR 代码审查 action，可以为仓库提供开箱即用的 AI 代码审查能力，并与后续其他工具实现的 review action 形成命名清晰、可对比的 action 矩阵。

## What Changes

- 新增 Composite Action `actions/ocr-review/`，封装 alibaba/open-code-review CLI 的 PR diff 审查流程。
- Action 内部通过多个 step 完成：安装 OCR CLI、配置 LLM provider、推断 PR 上下文、执行审查、解析 JSON 结果并发布 GitHub PR review comments。
- 引入 monorepo 结构：项目根使用 pnpm workspace，新增 `packages/shared/` 共享工具库，供多个 action 复用。
- 每个 step 脚本使用 TypeScript 编写，通过 esbuild 独立打包为 `dist/*.js`，确保 action 运行时无需安装依赖。
- 提供 `actions/ocr-review/README.md` 与调用示例 workflow。

## Capabilities

### New Capabilities

- `ocr-review`: 使用 alibaba/open-code-review 对 Pull Request 进行代码审查，并自动发布 inline review comments 与 summary comments。

### Modified Capabilities

无。

## Impact

- 新增 `actions/ocr-review/` 目录及其构建产物 `dist/`。
- 新增 `packages/shared/` 共享库。
- 新增/修改根目录 `package.json`、`pnpm-workspace.yaml` 等 monorepo 配置。
- 无破坏性变更，因为项目此前没有发布任何 action。
