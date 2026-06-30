# OCR Review Action

A GitHub Composite Action that runs [alibaba/open-code-review](https://github.com/alibaba/open-code-review) on a Pull Request and posts review comments.

## Usage

Add a workflow to your repository (e.g. `.github/workflows/ocr-review.yml`):

```yaml
name: OCR Review

on:
  pull_request:
    types: [opened, synchronize, reopened]
  issue_comment:
    types: [created]

permissions:
  contents: read
  pull-requests: write

jobs:
  review:
    # Auto-review for trusted authors; manual trigger via /ocr review comment.
    if: |
      (
        github.event_name == 'pull_request' &&
        (
          github.event.pull_request.author_association == 'OWNER' ||
          github.event.pull_request.author_association == 'MEMBER' ||
          github.event.pull_request.author_association == 'COLLABORATOR'
        )
      ) ||
      (
        github.event_name == 'issue_comment' &&
        github.event.issue.pull_request != null &&
        startsWith(github.event.comment.body, '/ocr review') &&
        (
          github.event.comment.author_association == 'OWNER' ||
          github.event.comment.author_association == 'MEMBER' ||
          github.event.comment.author_association == 'COLLABORATOR'
        )
      )
    runs-on: ubuntu-latest
    steps:
      - name: Run OCR review
        uses: djangoyi-yunify/gh-action-bundles/actions/ocr-review@main
        with:
          identifier: OCR
          llm-url: ${{ secrets.OCR_LLM_URL }}
          llm-token: ${{ secrets.OCR_LLM_AUTH_TOKEN }}
          llm-model: ${{ secrets.OCR_LLM_MODEL }}
          pr-number: ${{ github.event.pull_request.number || github.event.issue.number }}
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `llm-url` | yes | - | LLM API endpoint URL |
| `llm-token` | yes | - | LLM API authentication token |
| `llm-model` | yes | - | LLM model name, e.g. `gpt-4o` |
| `pr-number` | yes | - | Pull request number to review |
| `github-token` | no | `${{ github.token }}` | GitHub token for posting comments |
| `ocr-version` | no | `latest` | Version of `@alibaba-group/open-code-review` to install |
| `use-anthropic` | no | `false` | Set to `true` for Anthropic Claude models |
| `extra-body` | no | `{"thinking": {"type": "disabled"}}` | Extra JSON body merged into LLM requests |
| `rule-path` | no | - | Path to custom OCR rule JSON file relative to repo root |
| `exclude` | no | - | Comma-separated gitignore-style exclude patterns |
| `concurrency` | no | `8` | Max concurrent file reviews |
| `timeout` | no | `10` | Concurrent task timeout in minutes |
| `background` | no | - | Optional business/requirement context for the review |
| `identifier` | no | `OCR` | Identifier prepended to review comments to distinguish multiple review actions |
| `auto-checkout` | no | `true` | Let the action checkout the repository and PR head branch; set to `false` if the caller already checked out the code |

## Outputs

| Output | Description |
|--------|-------------|
| `review-count` | Total number of review comments generated |
| `inline-count` | Number of comments posted as inline PR review comments |
| `summary-count` | Number of comments included in the summary |
| `failed-count` | Number of comments that failed to post |

## How it works

1. Installs the `@alibaba-group/open-code-review` npm package globally.
2. Configures the OCR LLM provider via `ocr config set`.
3. Checks out the repository and the PR head branch (same-repo or fork).
4. Uses `gh pr view` to infer the PR base branch and head SHA.
5. Runs `ocr review --from <merge-base> --to <head> --format json`.
5. Parses the JSON output and posts inline review comments via GitHub's PR review API.
6. Comments that cannot be posted inline are included in a summary issue comment.
7. Every comment body starts with `Reviewer ID: [{identifier}]` on its own line, followed by the OCR-generated content on the next line. The identifier defaults to `OCR`.

## Multiple review actions

If you run several review actions in the same repository, give each one a distinct trigger phrase and identifier:

```yaml
# .github/workflows/ocr-review.yml
if: startsWith(github.event.comment.body, '/ocr review')
...
- uses: djangoyi-yunify/gh-action-bundles/actions/ocr-review@main
  with:
    identifier: OCR
    ...

# .github/workflows/security-review.yml
if: startsWith(github.event.comment.body, '/security review')
...
- uses: djangoyi-yunify/gh-action-bundles/actions/ocr-review@main
  with:
    identifier: Security
    ...
```

Comments from the first workflow start with `Reviewer ID: [OCR]` on their own line, and comments from the second start with `Reviewer ID: [Security]`.

## Custom rules

Place a rule file at `.opencodereview/rule.json` in your repository, or pass a custom path via `rule-path`:

```yaml
- uses: djangoyi-yunify/gh-action-bundles/actions/ocr-review@main
  with:
    rule-path: .github/ocr-rules.json
```

See the [OCR rule documentation](https://github.com/alibaba/open-code-review#review-rules) for the rule file format.

## Security model

This workflow deliberately uses `pull_request` rather than `pull_request_target` as the default event.

- `pull_request` does **not** expose repository secrets to fork PRs. If an untrusted user opens a fork PR, the workflow is skipped by the `author_association` gate and cannot leak your LLM API keys.
- `issue_comment` runs in the base repository context, so trusted maintainers can still trigger a review of any PR (including fork PRs) by commenting `/ocr review`.

If you specifically need **automatic** review of arbitrary fork PRs, you can switch to `pull_request_target`. Only do this if you fully understand the security implications: the workflow runs with write permissions and access to secrets for every PR.
