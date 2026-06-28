# ocr-review-same-repo-verification Specification

## Purpose
TBD - created by archiving change verify-ocr-review-same-repo-e2e. Update Purpose after archive.
## Requirements
### Requirement: Trusted authors receive automatic review
The verification SHALL confirm that `pull_request` workflows run and post review comments for PRs opened by `OWNER`. Verification of `MEMBER` and `COLLABORATOR` associations is deferred to a follow-up change due to test-account availability.

#### Scenario: OWNER opens same-repo PR
- **WHEN** an `OWNER` opens a same-repo PR containing known problematic code
- **THEN** the `pull_request` workflow runs and posts `[OCR]` review comments

### Requirement: Untrusted authors do not receive automatic review [DEFERRED]
The verification SHALL confirm that `pull_request` workflows are skipped for PRs opened by authors outside the trusted set. This requirement is deferred to a follow-up change due to the need for a dedicated untrusted test account in the same-repo scenario.

#### Scenario: CONTRIBUTOR opens same-repo PR
- **WHEN** a `CONTRIBUTOR` or `NONE` association user opens a same-repo PR
- **THEN** the `pull_request` workflow is skipped and no review comments are posted

### Requirement: Trusted users can trigger manual review
The verification SHALL confirm that `/ocr review` triggers review for trusted commenters on same-repo PRs.

#### Scenario: OWNER comments `/ocr review`
- **WHEN** an `OWNER`, `MEMBER`, or `COLLABORATOR` comments `/ocr review` on a same-repo PR
- **THEN** the `issue_comment` workflow runs and posts `[OCR]` review comments

### Requirement: Untrusted users cannot trigger manual review [DEFERRED]
The verification SHALL confirm that `/ocr review` from untrusted commenters is ignored. This requirement is deferred to a follow-up change due to the need for a dedicated untrusted test account in the same-repo scenario.

#### Scenario: Untrusted user comments `/ocr review`
- **WHEN** a user with `CONTRIBUTOR`, `NONE`, or similar association comments `/ocr review`
- **THEN** the `issue_comment` workflow is skipped and no comments are posted

### Requirement: Only `/ocr review` triggers manual review
The verification SHALL confirm that other comment text does not trigger the workflow.

#### Scenario: Comment does not start with `/ocr review`
- **WHEN** a trusted user posts a comment that does not start with `/ocr review`
- **THEN** the `issue_comment` workflow is not triggered

### Requirement: Merge-base calculation excludes unrelated base branch changes
The verification SHALL confirm that review uses the PR merge base even when `main` advances after PR creation.

#### Scenario: Base branch advances after PR creation
- **WHEN** `main` receives unrelated commits after the PR is opened, and a review is triggered
- **THEN** the review only covers the diff from the merge base to the PR head

### Requirement: New files are reviewed
The verification SHALL confirm that PRs adding new files produce review comments.

#### Scenario: PR adds a new file with known bugs
- **WHEN** a same-repo PR adds a new `.py` file containing `eval()`, hardcoded password, and `os.system()`
- **THEN** the workflow posts `[OCR]` review comments on the new file

### Requirement: Modified existing files are reviewed
The verification SHALL confirm that PRs modifying existing files produce review comments.

#### Scenario: PR modifies an existing file with known bugs
- **WHEN** a same-repo PR modifies `main.py` to introduce `eval()`, hardcoded password, or `os.system()`
- **THEN** the workflow posts `[OCR]` review comments on the modified file

### Requirement: OCR failures are reported
The verification SHALL confirm that OCR CLI failures result in a PR comment describing the failure.

#### Scenario: OCR CLI exits with an error
- **WHEN** OCR cannot complete (for example, due to invalid LLM credentials)
- **THEN** the action posts an issue comment containing the stderr output

### Requirement: Inline comment fallback works
The verification SHALL confirm that inline comments that cannot be posted are included in a summary comment.

#### Scenario: GitHub rejects inline review comments
- **WHEN** the action attempts to post inline comments but GitHub rejects the batch review
- **THEN** the comments are posted as part of a summary issue comment

### Requirement: Identifier prefix is applied
The verification SHALL confirm that the `identifier` input prefixes every review comment.

#### Scenario: Identifier is `OCR`
- **WHEN** the action runs with `identifier: OCR`
- **THEN** every posted comment body starts with `[OCR]`

### Requirement: Automatic checkout can be disabled
The verification SHALL confirm that `auto-checkout: false` skips the checkout steps.

#### Scenario: Caller provides its own checkout
- **WHEN** the action is invoked with `auto-checkout: false` and the caller has already checked out the PR head
- **THEN** the action resolves the PR and runs OCR without performing its own fetch/checkout

### Requirement: Optional boundary conditions are documented
The verification SHALL list same-repo boundary conditions that are not part of the required test suite so the team can decide whether to test them.

#### Scenario: Optional conditions reviewed
- **WHEN** the team reviews the optional list
- **THEN** they can choose to add any of them to the current or a future run

## DEFERRED Requirements

The following requirements are valid for same-repo verification but are not executed in this change due to test-account availability. They are deferred to a follow-up change or to the fork-PR verification change.

### Requirement: MEMBER opens same-repo PR
- **WHEN** a `MEMBER` opens a same-repo PR containing known problematic code
- **THEN** the `pull_request` workflow runs and posts `[OCR]` review comments

### Requirement: COLLABORATOR opens same-repo PR
- **WHEN** a `COLLABORATOR` opens a same-repo PR containing known problematic code
- **THEN** the `pull_request` workflow runs and posts `[OCR]` review comments

### Requirement: Untrusted authors do not receive automatic review
- **WHEN** a `CONTRIBUTOR` or `NONE` association user opens a same-repo PR
- **THEN** the `pull_request` workflow is skipped and no review comments are posted

### Requirement: Untrusted users cannot trigger manual review
- **WHEN** a user with `CONTRIBUTOR`, `NONE`, or similar association comments `/ocr review`
- **THEN** the `issue_comment` workflow is skipped and no comments are posted

