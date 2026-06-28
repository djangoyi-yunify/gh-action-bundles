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

### Requirement: Action accepts an identifier input
The action SHALL accept an optional `identifier` input that labels the source of each review comment.

#### Scenario: Identifier provided
- **WHEN** the action is invoked with `identifier: OCR`
- **THEN** each review comment body is prefixed with `[OCR] `

#### Scenario: Identifier omitted
- **WHEN** the action is invoked without an identifier
- **THEN** comments are posted without any prefix

### Requirement: Action supports an author association gate
The action's example workflow SHALL only automatically review PRs opened by trusted authors.

#### Scenario: Trusted author opens same-repo PR
- **WHEN** an `OWNER`, `MEMBER`, or `COLLABORATOR` opens a PR from a branch in the same repository
- **THEN** the `pull_request` workflow runs and performs OCR review

#### Scenario: Untrusted author opens PR
- **WHEN** a user with any other `author_association` opens a PR
- **THEN** the `pull_request` workflow is skipped and no review is performed

### Requirement: Action supports a manual review command
The action's example workflow SHALL support a comment command that allows trusted users to request a review of any PR.

#### Scenario: Trusted user requests review via comment
- **WHEN** an `OWNER`, `MEMBER`, or `COLLABORATOR` comments `/ocr review` on a PR
- **THEN** the `issue_comment` workflow runs and performs OCR review

#### Scenario: Untrusted user requests review via comment
- **WHEN** a user with any other `author_association` comments `/ocr review`
- **THEN** the `issue_comment` workflow is skipped

### Requirement: Comment-triggered workflows checkout PR head
The action's example workflow SHALL checkout the PR head branch when triggered by an `issue_comment` event.

#### Scenario: Manual review of same-repo PR
- **WHEN** `/ocr review` is commented on a same-repository PR
- **THEN** the workflow checks out the PR head before running OCR

#### Scenario: Manual review of fork PR
- **WHEN** `/ocr review` is commented on a fork PR
- **THEN** the workflow checks out the PR head before running OCR

### Requirement: Documentation explains the security model
The action's README SHALL document why fork PRs are not automatically reviewed and how to trigger them manually.

#### Scenario: User reads security notes
- **WHEN** a consumer reads the README
- **THEN** they understand the `pull_request` vs `pull_request_target` trade-off and the purpose of the `author_association` gate

### Requirement: Bundled example workflow matches the README-recommended default pattern
The bundled `examples/ocr-review.yml` SHALL use the same event model, access controls, and trigger phrase as the default workflow shown in `actions/ocr-review/README.md`.

#### Scenario: Example uses pull_request event for auto-review
- **WHEN** a consumer opens `examples/ocr-review.yml`
- **THEN** the workflow triggers on `pull_request`, not `pull_request_target`

#### Scenario: Example gates auto-review by author association
- **WHEN** the workflow is triggered by a `pull_request` event
- **THEN** it only runs when `github.event.pull_request.author_association` is `OWNER`, `MEMBER`, or `COLLABORATOR`

#### Scenario: Example uses the documented manual trigger phrase
- **WHEN** a consumer reads the example workflow
- **THEN** the `issue_comment` trigger only runs for comments starting with `/ocr review`

#### Scenario: Example gates manual trigger by author association
- **WHEN** the workflow is triggered by an `issue_comment` event
- **THEN** it only runs when `github.event.comment.author_association` is `OWNER`, `MEMBER`, or `COLLABORATOR`
