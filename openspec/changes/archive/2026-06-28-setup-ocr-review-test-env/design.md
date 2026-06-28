## Context

`actions/ocr-review` 已经实现完成，但尚未在真实 GitHub Actions 环境中运行。本 change 旨在搭建一个最小可用的外部测试环境，验证 action 的端到端行为。测试仓库独立于主项目，避免污染 `gh-action-bundles` 本身。

## Goals / Non-Goals

**Goals:**
- 创建个人测试仓库 `gh-action-test-01`。
- 构造两个测试分支 `test01`（问题代码）和 `test02`（干净代码）。
- 配置 workflow 调用 `gh-action-bundles/actions/ocr-review@main`。
- 通过真实 PR 触发 workflow，验证 inline comments 和 summary 评论的发布。

**Non-Goals:**
- 不测试 fork PR 场景（需要第二个账号或组织，超出当前范围）。
- 不修改 `gh-action-bundles` 主仓库的 action 代码（仅根据测试结果可能产生后续 change）。
- 不长期维护测试仓库，仅用于一次性验证。

## Decisions

### 1. 测试仓库：个人账号下的 `gh-action-test-01`
个人账号即可创建，无需组织权限，管理成本低。

### 2. 触发事件：`pull_request`
测试 PR 来自同一仓库内部，使用 `pull_request` 最简单安全。在仓库设置中允许 workflow 读取 secrets 即可。

### 3. LLM Provider：`https://openapi.coreshub.cn/v1` + `DeepSeek-V4-Flash`
OpenAI 兼容协议，`use-anthropic` 保持默认 `false`。

### 4. 引用 action：`gh-action-bundles/actions/ocr-review@main`
测试时直接引用主分支最新 action，方便快速迭代。

### 5. 两个测试分支覆盖不同场景
- `test01`：引入硬编码密码、`os.system` 等明显问题，验证 inline comments 发布。
- `test02`：代码规范整洁，验证 summary / LGTM 评论发布。

## Risks / Trade-offs

- **Risk**: 测试仓库需要配置真实 LLM API key，存在泄露风险。
  - **Mitigation**: 使用 GitHub Secrets 存储，不在代码中硬编码。
- **Risk**: `ocr-review@main` 可能不稳定，测试时主仓库尚未合并最新改动。
  - **Mitigation**: 测试前确认主仓库 `main` 分支已包含目标 action 代码。
- **Risk**: `DeepSeek-V4-Flash` 模型输出可能与预期不同，导致 comments 数量/内容变化。
  - **Mitigation**: 测试目标聚焦在 action 链路是否通，不严格校验具体 comments 内容。

## Migration Plan

无迁移成本。

## Open Questions

- 是否需要把测试 workflow 文件也纳入 `gh-action-bundles` 的 `examples/` 目录长期维护？
- 测试完成后，是否需要更新 `add-ocr-review-action` 的 tasks.md 中 7.2 状态？
