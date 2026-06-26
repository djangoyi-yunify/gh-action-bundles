# 调研笔记：GitHub Action 本身的权限处理

> 调研范围：opencode 官方 `github/action.yml` 与 `opencode-pr-reviewer/action.yml`。  
> 调研重点：**只看 composite action 本身**如何处理权限，不考虑调用方 workflow 的 `permissions:` 声明、`if:` 过滤、`author_association` 等安全限制，也不深入 action 内部 handler 的运行时检查。

## 1. 核心前提

**composite action 本身无法声明 GitHub 权限。** `action.yml` 中没有 `permissions:` 部分。它只能：

1. 通过 `inputs` 接收参数
2. 通过 `env` 接收环境变量（包括 token）
3. 在 steps 中使用这些 token 调用 GitHub API

因此，action 的"权限处理"实际上体现在：**它需要调用方提供什么 token，以及它用这些 token 做什么**。

## 2. opencode 官方 `github/action.yml`

### 2.1 Inputs

```yaml
inputs:
  model:
    description: "Model to use"
    required: true
  agent:
    description: "Agent to use..."
    required: false
  share:
    description: "Share the opencode session..."
    required: false
  prompt:
    description: "Custom prompt to override the default prompt"
    required: false
  use_github_token:
    description: "Use GITHUB_TOKEN directly instead of OpenCode App token exchange..."
    required: false
    default: "false"
  mentions:
    description: "Comma-separated list of trigger phrases..."
    required: false
  variant:
    description: "Model variant..."
    required: false
  oidc_base_url:
    description: "Base URL for OIDC token exchange API..."
    required: false
```

### 2.2 Token 处理

```yaml
- name: Run opencode
  run: opencode github run
  env:
    MODEL: ${{ inputs.model }}
    AGENT: ${{ inputs.agent }}
    SHARE: ${{ inputs.share }}
    PROMPT: ${{ inputs.prompt }}
    USE_GITHUB_TOKEN: ${{ inputs.use_github_token }}
    MENTIONS: ${{ inputs.mentions }}
    VARIANT: ${{ inputs.variant }}
    OIDC_BASE_URL: ${{ inputs.oidc_base_url }}
```

### 2.3 权限思路

| 维度 | 说明 |
|------|------|
| **默认 token 来源** | 依赖 OIDC：`opencode github run` 内部会获取 OIDC token，再交换 OpenCode App token |
| **调用方需提供的权限** | 默认模式下，调用方 workflow 必须声明 `id-token: write`，否则 OIDC 获取失败 |
| **替代 token 来源** | 当 `use_github_token: true` 时，action 要求调用方在 `env` 中提供 `GITHUB_TOKEN` |
| **action 自身权限声明** | 无。composite action 不能声明 `permissions` |
| **action 内部权限验证** | `github/action.yml` 只是透传 env，具体验证在 `opencode github run` 内部 |

### 2.4 一句话总结

> opencode 官方 action 本身不处理权限验证，它只是告诉调用方："要么给我 `id-token: write` 让我换 App token，要么给我 `GITHUB_TOKEN`。"

## 3. opencode-pr-reviewer `action.yml`

### 3.1 Inputs

```yaml
inputs:
  model:
    description: 'opencode model string...'
    required: true
  pr-number:
    description: 'Pull request number to review.'
    required: true
  opencode-version:
    description: 'Pin a specific opencode version...'
    required: false
    default: ''
  user-comment:
    description: 'Body of the triggering comment...'
    required: false
    default: ''
  review-file:
    description: 'Path where opencode writes the review...'
    required: false
    default: './opencode-review.md'
  workflow-run-url:
    description: 'URL of the workflow run...'
    required: false
    default: ''
  post-start-comment:
    description: 'Post a "Starting review…" comment...'
    required: false
    default: 'true'
```

### 3.2 Token 处理

action 本身没有直接声明需要 `GH_TOKEN`，但在 steps 中通过 `gh` CLI 隐式使用：

```yaml
- name: Generate review prompt
  run: '"${{ github.action_path }}/scripts/opencode-review-prompt.sh" > /tmp/opencode-prompt.txt'

- name: Post starting comment
  run: '"${{ github.action_path }}/scripts/opencode-review-start-comment.sh"'

- name: Run opencode review
  run: opencode run --model "${{ inputs.model }}" "$(cat /tmp/opencode-prompt.txt)"

- name: Post review
  run: '"${{ github.action_path }}/scripts/opencode-review-post.sh"'
```

这些脚本内部使用 `gh api ...` 和 `gh pr ...`，依赖 `GH_TOKEN` 环境变量。

### 3.3 权限思路

| 维度 | 说明 |
|------|------|
| **token 来源** | 直接依赖调用方提供的 `GH_TOKEN` 环境变量（即 `secrets.GITHUB_TOKEN`） |
| **调用方需提供的权限** | `contents: read`（checkout + 读代码）、`issues: write`（发评论）、`pull-requests: write`（发评论） |
| **action 自身权限声明** | 无。composite action 不能声明 `permissions` |
| **action 对 token 的使用范围** | 脚本用 `GH_TOKEN` 做三件事：读 PR 数据、发/改"Starting review"评论、发/改最终 review 评论 |
| **action 内部权限限制** | 生成 `/tmp/opencode-config.json` 限制 opencode 自身工具权限，但这属于 action 内部实现 |

### 3.4 一句话总结

> opencode-pr-reviewer action 本身不获取 token，只要求调用方提供 `GH_TOKEN`，然后用它通过 `gh` CLI 读取 PR 数据和发布评论。

## 4. 两者对比

| 维度 | opencode 官方 action | opencode-pr-reviewer |
|------|---------------------|---------------------|
| **action 自身能否声明权限** | 不能 | 不能 |
| **token 获取责任** | action 内部获取（OIDC 或直接使用 GITHUB_TOKEN） | 调用方提供 GH_TOKEN |
| **默认是否需要 OIDC** | 是 | 否 |
| **是否需要 GITHUB_TOKEN** | 仅在 `use_github_token: true` 时需要 | 始终需要 GH_TOKEN |
| **token 用途** | 传递给 `opencode github run`，由内部 handler 使用 | 脚本用 `gh` CLI 读 PR 数据、发评论 |
| **权限声明位置** | 调用方 workflow | 调用方 workflow |
| **action 对权限的最小要求** | 默认 `id-token: write`；GITHUB_TOKEN 模式需要 `contents/write/issues/pr: write` | `contents: read` + `issues: write` + `pull-requests: write` |

## 5. 关键发现

1. **composite action 没有权限声明能力**：两个 action 的 `action.yml` 都没有 `permissions:` 部分，权限必须在调用方 workflow 声明。

2. **token 获取方式不同**：
   - 官方 action 自己获取 token（OIDC 模式）
   - pr-reviewer 完全依赖调用方传入 GH_TOKEN

3. **官方 action 更"自闭环"**：它把 token 获取封装在 action 内部，调用方只需声明 workflow 权限。
   - pr-reviewer 更"透明"：调用方必须显式设置 `GH_TOKEN` 和 `permissions`。

4. **权限最小化差异**：
   - 官方 action 默认需要 `contents: write`（因为会 push commit/创建 PR）
   - pr-reviewer 只需要 `contents: read` + `issues/pr: write`（只发评论，不改代码）

5. **action 本身不做权限验证**：两个 action 的 `action.yml` 都不验证调用方是否有足够权限，验证发生在 action 内部实现或调用方 workflow 中。

## 6. 对我们项目的启示

设计我们自己的 GitHub Action 时需要考虑：

1. **token 获取方式**
   - 简单接入：要求调用方提供 `GH_TOKEN`
   - 高级功能：支持 OIDC 或 GitHub App token

2. **最小权限原则**
   - 如果只做 review：`contents: read` + `issues: write` + `pull-requests: write`
   - 如果需要修改代码：`contents: write` + `pull-requests: write`

3. **权限声明位置**
   - action 本身无法声明，必须在文档中明确告诉调用方需要哪些 workflow permissions

4. **token 使用范围**
   - 是否让模型直接调用 GitHub API？
   - 还是由 action 脚本控制所有写操作？

## 7. 后续可调研方向

- 我们自己的代码审查 Action 应该选择哪种 token 模式。
- 是否需要支持 GitHub App installation token。
- 如何在 action 文档中清晰描述所需 workflow permissions。
