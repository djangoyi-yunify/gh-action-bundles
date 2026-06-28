# OCR Review Action

## Purpose

Provide a GitHub Composite Action that invokes the Open Code Review (OCR) CLI to review Pull Request diffs and publish comments back to the PR.

## Requirements

### Requirement: Action exposes required LLM inputs
The action SHALL expose inputs for configuring the OCR LLM provider.

#### Scenario: Minimal required inputs
- **WHEN** the calling workflow invokes `actions/ocr-review` with `llm-url`, `llm-token`, `llm-model`, and `pr-number`
- **THEN** the action configures OCR and attempts to review the specified PR

### Requirement: Action infers PR base and head from PR number
The action SHALL infer `base-ref` and `head-sha` from the provided `pr-number` using the GitHub CLI or API.

#### Scenario: PR opened event
- **WHEN** the action receives a `pr-number`
- **THEN** it queries the PR metadata and uses the PR base branch name and head commit SHA as the review range

### Requirement: Action installs OCR CLI
The action SHALL install the `@alibaba-group/open-code-review` npm package globally.

#### Scenario: Default version installation
- **WHEN** no `ocr-version` input is provided
- **THEN** the action installs the latest published version

#### Scenario: Pinned version installation
- **WHEN** `ocr-version` input is provided
- **THEN** the action installs the specified version

### Requirement: Action configures OCR LLM provider
The action SHALL configure OCR using `ocr config set` for URL, token, model, Anthropic flag, and extra body.

#### Scenario: OpenAI-compatible provider
- **WHEN** `use-anthropic` is `false`
- **THEN** OCR is configured for OpenAI-compatible protocol with the provided credentials

#### Scenario: Anthropic provider
- **WHEN** `use-anthropic` is `true`
- **THEN** OCR is configured for Anthropic protocol

### Requirement: Action runs OCR review on PR diff
The action SHALL execute `ocr review --from origin/<base-ref> --to <head-sha> --format json` with optional flags.

#### Scenario: Basic review
- **WHEN** all required inputs are valid
- **THEN** OCR reviews the diff and outputs JSON to a known temporary path

#### Scenario: Custom rule file
- **WHEN** `rule-path` is provided and the file exists
- **THEN** OCR is invoked with `--rule <rule-path>`

#### Scenario: Exclude patterns
- **WHEN** `exclude` input is provided
- **THEN** OCR is invoked with `--exclude <patterns>`

#### Scenario: Background context
- **WHEN** `background` input is provided
- **THEN** OCR is invoked with `--background <text>`

### Requirement: Action publishes review comments to PR
The action SHALL parse OCR JSON output and publish comments to the Pull Request.

#### Scenario: Inline comments
- **WHEN** OCR returns comments with valid line information
- **THEN** the action posts them as GitHub PR review inline comments

#### Scenario: Summary comment
- **WHEN** OCR returns no inline comments but returns a non-empty `message`
- **THEN** the action posts the `message` as a PR issue comment

#### Scenario: No comments and no message
- **WHEN** OCR returns no inline comments and an empty `message`
- **THEN** the action does not post any comment

### Requirement: Action exposes review statistics as outputs
The action SHALL expose `review-count`, `inline-count`, `summary-count`, and `failed-count` as outputs.

#### Scenario: Successful review with comments
- **WHEN** OCR returns comments and the action publishes them
- **THEN** the outputs reflect the total, inline, summary, and failed comment counts

### Requirement: Action handles OCR failures gracefully
The action SHALL capture OCR stderr and continue to report errors as PR comments rather than failing silently.

#### Scenario: OCR CLI fails
- **WHEN** `ocr review` exits with an error
- **THEN** the action reads stderr and posts a PR comment describing the failure
