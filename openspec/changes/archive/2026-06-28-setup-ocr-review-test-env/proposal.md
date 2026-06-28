## Why

`add-ocr-review-action` 已经完成了 `actions/ocr-review` 的实现与静态验证，但尚未在真实 GitHub Actions 运行环境中验证端到端链路。搭建一个专用的测试仓库，并构造不同场景的测试 PR，可以验证 OCR 安装、LLM 配置、PR 上下文推断、JSON 输出解析以及 PR review 评论发布等关键环节是否正常工作。

## What Changes

- 在个人账号下创建测试仓库 `gh-action-test-01`。
- 在 `main` 分支提交基础 Python Hello World 代码。
- 创建并推送 `test01` 分支（包含有明显问题的代码），用于验证 inline review comments 的发布。
- 创建并推送 `test02` 分支（包含干净代码），用于验证 summary / LGTM 评论的发布。
- 在 `main` 分支添加 `.github/workflows/ocr-review.yml`，使用 `gh-action-bundles/actions/ocr-review@main`。
- 在测试仓库中配置 LLM secrets（`OCR_LLM_URL`、`OCR_LLM_AUTH_TOKEN`、`OCR_LLM_MODEL`）。
- 在 GitHub 上为 `test01` 和 `test02` 分别创建 Pull Request，触发 workflow 运行。

## Capabilities

### New Capabilities

- `ocr-review-test-env`: 为 `ocr-review` action 搭建真实 GitHub Actions 测试环境，覆盖有问题代码和干净代码两种审查场景。

### Modified Capabilities

无。

## Impact

- 新增外部测试仓库 `gh-action-test-01`（不属于本仓库代码变更）。
- 可能需要更新 `add-ocr-review-action` 的测试任务状态或补充测试记录。
- 无破坏性变更。
