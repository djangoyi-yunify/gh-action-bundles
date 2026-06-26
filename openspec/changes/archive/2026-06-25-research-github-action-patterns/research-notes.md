# 调研笔记：opencode 生态中的 GitHub Action 实现思路

> 调研范围：opencode 官方 `github/action.yml` 与 `opencode-pr-reviewer/action.yml`。
> 调研重点：GitHub Action 配置结构、composite action 实现模式、关键差异。

## 1. 调研对象

| 项目 | 路径 | 定位 |
|------|------|------|
| opencode 官方 | `github/action.yml` | 通用 GitHub Agent |
| opencode-pr-reviewer | `action.yml` | 专用 PR Reviewer |

## 2. 通用 Composite Action 模式

两个项目都使用 GitHub Actions 的 `composite` 类型。整体流程高度相似：安装 opencode CLI、准备运行环境、准备输入数据、调用 opencode、处理输出。

主要差异在于：权限控制方式、prompt 构建位置、输出处理方式。

## 3. opencode 官方 `github/action.yml`

### 3.1 Inputs

- `model`：必填，模型字符串
- `agent`：非必填，当前未实际读取
- `share`：非必填，是否分享 session
- `prompt`：非必填，自定义提示词
- `use_github_token`：非必填，默认 false
- `mentions`：非必填，触发词列表
- `variant`：非必填，模型变体
- `oidc_base_url`：非必填，OIDC 交换 API

### 3.2 Steps

1. 获取 opencode 最新版本号
2. 缓存 `~/.opencode/bin`
3. 安装 opencode
4. 添加 opencode 到 PATH
5. 运行 `opencode github run`
6. 通过环境变量传入所有 inputs

### 3.3 Action 文档中的使用示例

`github/action.yml` 的配套文档是 `github/README.md`，其中提供了手动设置的 workflow 示例：

```yaml
name: opencode

on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]

jobs:
  opencode:
    if: |
      contains(github.event.comment.body, '/oc') ||
      contains(github.event.comment.body, '/opencode')
    runs-on: ubuntu-latest
    permissions:
      id-token: write
    steps:
      - name: Checkout repository
        uses: actions/checkout@v6
        with:
          fetch-depth: 1
          persist-credentials: false

      - name: Run opencode
        uses: anomalyco/opencode/github@latest
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          model: anthropic/claude-sonnet-4-20250514
          use_github_token: true
```

特点：

- 触发词匹配在 workflow 层完成
- action 本身不绑定特定事件，调用方 workflow 决定触发条件
- action 内部通过 `opencode github run` 处理事件路由和 prompt 构建

## 4. opencode-pr-reviewer `action.yml`

### 4.1 Inputs

- `model`：必填
- `pr-number`：必填
- `opencode-version`：非必填，可固定 opencode 版本
- `user-comment`：非必填，触发评论 body
- `review-file`：非必填，默认 `./opencode-review.md`
- `workflow-run-url`：非必填
- `post-start-comment`：非必填，默认 true

### 4.2 Steps

1. 安装 opencode CLI
2. 删除项目级 `opencode.json` / `opencode.jsonc` / `.opencode/`（防止恶意 PR 覆盖权限）
3. 生成 `/tmp/opencode-config.json`，设置严格只读权限
4. 运行 `scripts/opencode-review-prompt.sh` 生成 prompt
5. 发布 "Starting review…" 评论
6. 运行 `opencode run --model <model> "$(cat /tmp/opencode-prompt.txt)"`
7. 发布/编辑最终 review 评论

### 4.3 配套 Workflow

`examples/opencode-review.yml` 在 `pull_request` 和 `issue_comment` 事件触发，负责：

- 作者身份过滤（OWNER / MEMBER / COLLABORATOR）
- `/no-bot-review` 跳过标记
- `/oc review` 评论触发
- 评论触发时切换到 PR head 分支

特点：触发逻辑、身份过滤完全在调用方 workflow 中，action 只负责执行 review。

## 5. 关键差异对比

| 维度 | opencode 官方 | opencode-pr-reviewer |
|------|--------------|---------------------|
| 定位 | 通用 GitHub Agent | 专用 PR Reviewer |
| Action 类型 | composite | composite |
| 入口命令 | `opencode github run` | `opencode run --model <model> "<prompt>"` |
| 示例触发事件 | issue_comment, pull_request_review_comment（由示例 workflow 决定） | pull_request, issue_comment（由示例 workflow 决定） |
| action 内部支持事件 | issue_comment, pull_request_review_comment, issues, pull_request, schedule, workflow_dispatch | 任意事件，只要传入 pr-number |
| 认证方式 | OIDC 换 App token 或 GITHUB_TOKEN | 直接使用 GITHUB_TOKEN |
| 权限控制 | 运行时由 agent config / env 决定 | 预生成严格只读 config |
| 配置注入 | 环境变量 | `/tmp/opencode-config.json` 文件 |
| Prompt 构建 | TypeScript handler | bash 脚本 |
| 输出方式 | 模型响应直接发布 | 模型写入文件，post 脚本发布 |
| 安全配置 | 较轻 | 很重：删项目 config、bash 白名单、禁用 web/task/external |
| 示例中的作者身份过滤 | 无 | 限制为 OWNER/MEMBER/COLLABORATOR |
| 版本管理 | 运行时获取 latest 并缓存 | input 可固定版本 |

## 6. opencode 官方项目自身的其他工作流

opencode 官方项目内部还有 `.github/workflows/review.yml` 等工作流。这些工作流**没有使用** `github/action.yml`，而是直接调用 `opencode run`：

```yaml
run: |
  opencode run -m opencode/gpt-5.5 --variant medium "A new pull request has been created: ...
  ...
  Use the gh cli to create comments on the files for the violations."
```

这属于项目内部定制化 workflow，不是 `github/action.yml` 的用法。它说明：

- composite action 不是唯一选择
- 高度定制化的场景可以直接在 workflow 中调用 CLI
- 项目内部 workflow 和对外发布的 action 可以共存

## 7. 两种实现思路总结

### 思路 A：通用 Agent 封装

适合希望 opencode 在 GitHub 上处理多种任务的场景。

- 一个 composite action 暴露通用 inputs
- 内部用 TypeScript handler 处理事件路由和 prompt 构建
- 调用方 workflow 只需配置触发条件和模型

### 思路 B：专用工具封装

适合只解决"PR 代码审查"这一件事、要求高确定性的场景。

- composite action 只暴露与 review 相关的 inputs
- 内部用 bash 脚本严格限制权限、构建专用 prompt
- 调用方 workflow 控制触发逻辑和身份过滤
- 输出通过文件中转，post 脚本统一发布

## 8. 对我们项目的启示

1. 先从专用场景入手，聚焦代码审查，不要一开始就追求通用 Agent
2. 触发逻辑放在调用方 workflow，方便用户自由调整
3. 权限要收紧，参考 pr-reviewer 预生成严格权限配置
4. 输出方式选择：直接交互用官方模式，结构化输出用文件中转模式
5. 认证选择：简单接入用 GITHUB_TOKEN，需要 OpenCode 能力走 OIDC + App token

## 9. 关键发现

1. 两者都是 composite action，遵循相似流程
2. 权限模型是最大差异：官方较轻，pr-reviewer 很重
3. prompt 构建位置不同：官方在 TypeScript handler，pr-reviewer 在 bash 脚本
4. workflow 职责不同：官方只做触发词匹配，pr-reviewer 还负责身份过滤和分支切换
5. 输出处理不同：官方直接发布，pr-reviewer 通过文件中转
6. opencode 官方仓库本身也直接调用 `opencode run`

## 10. 后续可调研方向

- 我们自己的代码审查 Action 应该采用哪种权限模型
- 是否需要支持 `/oc review` 这类评论触发
- 输出格式采用自由文本还是结构化格式
- 是否需要集成 OpenCode 的 session sharing 功能
