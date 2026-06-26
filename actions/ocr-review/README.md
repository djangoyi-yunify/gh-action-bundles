# OCR Review Action

A GitHub Composite Action that runs [alibaba/open-code-review](https://github.com/alibaba/open-code-review) on a Pull Request and posts review comments.

## Usage

Add a workflow to your repository (e.g. `.github/workflows/ocr-review.yml`):

```yaml
name: OCR Review

on:
  pull_request_target:
    types: [opened, synchronize, reopened]

permissions:
  contents: read
  pull-requests: write

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
          persist-credentials: false

      - name: Run OCR review
        uses: your-org/gh-action-bundles/actions/ocr-review@main
        with:
          llm-url: ${{ secrets.OCR_LLM_URL }}
          llm-token: ${{ secrets.OCR_LLM_AUTH_TOKEN }}
          llm-model: ${{ secrets.OCR_LLM_MODEL }}
          pr-number: ${{ github.event.pull_request.number }}
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
3. Uses `gh pr view` to infer the PR base branch and head SHA.
4. Runs `ocr review --from origin/<base> --to <head> --format json`.
5. Parses the JSON output and posts inline review comments via GitHub's PR review API.
6. Comments that cannot be posted inline are included in a summary issue comment.

## Custom rules

Place a rule file at `.opencodereview/rule.json` in your repository, or pass a custom path via `rule-path`:

```yaml
- uses: your-org/gh-action-bundles/actions/ocr-review@main
  with:
    rule-path: .github/ocr-rules.json
```

See the [OCR rule documentation](https://github.com/alibaba/open-code-review#review-rules) for the rule file format.
