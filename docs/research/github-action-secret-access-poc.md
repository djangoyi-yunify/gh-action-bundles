# POC：GitHub Actions 不同 PR 类型下的 secrets 可访问性

> 测试时间：2026-06-29  
> 测试目的：验证 `pull_request` 与 `pull_request_target` 两种事件在同仓库 PR 和 fork PR 下，能否读取仓库 secrets，为项目 workflow 安全模式选择提供实测依据。

## 1. 测试仓库

| 仓库 | 角色 | 说明 |
|------|------|------|
| [djangoyi-yunify/gh-action-test-01](https://github.com/djangoyi-yunify/gh-action-test-01) | 主库（upstream） | 存放 workflow 与 secrets |
| [yijing1998/gh-action-test-01](https://github.com/yijing1998/gh-action-test-01) | fork 库 | 仅用于创建 fork PR |

在主库设置了测试 secret：`TEST_SECRET=poc-secret-value-2026-06-29`。

## 2. 测试工作流

文件：[`.github/workflows/secret-access-poc.yml`](https://github.com/djangoyi-yunify/gh-action-test-01/blob/main/.github/workflows/secret-access-poc.yml)

```yaml
name: Secret Access POC

on:
  pull_request:
  pull_request_target:

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - name: Check secret availability
        run: |
          echo "event_name=${{ github.event_name }}"
          echo "is_fork=${{ github.event.pull_request.head.repo.fork }}"
          echo "head_repo=${{ github.event.pull_request.head.repo.full_name }}"
          echo "base_repo=${{ github.event.pull_request.base.repo.full_name }}"
          if [ -n "$TEST_SECRET" ]; then
            echo "secret_status=present"
          else
            echo "secret_status=missing"
          fi
        env:
          TEST_SECRET: ${{ secrets.TEST_SECRET }}
```

设计要点：
- 同时监听 `pull_request` 与 `pull_request_target`，一次 PR 动作会触发两次独立的 workflow run
- 不打印 secret 值，只输出 `present` / `missing`
- 输出 `event_name`、`is_fork`、`head_repo`、`base_repo` 便于区分运行上下文

## 3. 测试结果

### 3.1 同仓库 PR

- PR：[djangoyi-yunify/gh-action-test-01#85](https://github.com/djangoyi-yunify/gh-action-test-01/pull/85)
- 分支：`djangoyi-yunify/gh-action-test-01:poc/same-repo-pr` → `main`

| 事件 | Run 状态 | `is_fork` | `secret_status` | Run 链接 |
|------|----------|-----------|-----------------|----------|
| `pull_request` | success | false | **present** | [Run #28344760757](https://github.com/djangoyi-yunify/gh-action-test-01/actions/runs/28344760757) |
| `pull_request_target` | success | false | **present** | [Run #28344760839](https://github.com/djangoyi-yunify/gh-action-test-01/actions/runs/28344760839) |

### 3.2 Fork PR

- PR：[djangoyi-yunify/gh-action-test-01#86](https://github.com/djangoyi-yunify/gh-action-test-01/pull/86)
- 分支：`yijing1998/gh-action-test-01:poc/fork-pr` → `djangoyi-yunify/gh-action-test-01:main`

| 事件 | Run 状态 | `is_fork` | `secret_status` | Run 链接 |
|------|----------|-----------|-----------------|----------|
| `pull_request` | success（需 maintainer 批准） | true | **missing** | [Run #28344805877](https://github.com/djangoyi-yunify/gh-action-test-01/actions/runs/28344805877) |
| `pull_request_target` | success | true | **present** | [Run #28344805837](https://github.com/djangoyi-yunify/gh-action-test-01/actions/runs/28344805837) |

## 4. 结论矩阵

| 事件 \ PR 类型 | 同仓库 PR | Fork PR |
|----------------|-----------|---------|
| `pull_request` | ✅ 可读取 secrets | ❌ 不可读取 secrets |
| `pull_request_target` | ✅ 可读取 secrets | ✅ 可读取 secrets |

关键理解：
- `pull_request` 运行在 PR 的 merge 上下文里，fork PR 属于不可信上下文，因此**不暴露 secrets**
- `pull_request_target` 运行在 base 仓库的上下文里，因此**始终能读取 base 仓库的 secrets**，无论 PR 是否来自 fork
- 同一 workflow 同时监听两个事件时，一次 PR 动作会触发**两次独立的 workflow run**

## 5. 对项目的启示

本项目的 `AGENTS.md` 已明确推荐 `pull_request` + `issue_comment` 的默认组合，本次 POC 从实测角度验证了其安全假设：

| 需求 | 推荐事件 | 风险 |
|------|----------|------|
| 同仓库 PR 自动触发 | `pull_request` | 低，secrets 可用且无需特殊处理 |
| Fork PR 手动触发 | `issue_comment` | 极低，仅 maintainer 评论触发，避免 secrets 泄露 |
| Fork PR 自动触发 | `pull_request_target` | 高，必须用 base ref checkout，避免执行 PR 中的不可信代码 |

若未来确实需要为 fork PR 提供自动 review，使用 `pull_request_target` 时必须：
1. 显式 checkout base ref：`ref: ${{ github.event.pull_request.base.sha }}`
2. 不直接执行 PR 分支中的脚本或 action 代码
3. 参考 `opencode-pr-reviewer` 的做法，在 action 内部删除项目级 config、生成严格只读配置

## 6. 清理记录

本次 POC 在主库留下了以下内容，测试结束后可选择清理：
- Workflow 文件：`.github/workflows/secret-access-poc.yml`
- Secret：`TEST_SECRET`
- 测试 PR：#85、#86
- 测试分支：`poc/same-repo-pr`、`yijing1998:poc/fork-pr`
