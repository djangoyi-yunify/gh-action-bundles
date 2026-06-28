## MODIFIED Requirements

### Requirement: Automatic review is gated by author association
The action's example workflow SHALL only automatically review PRs opened by trusted authors.

#### Scenario: Trusted author opens same-repo PR
- **WHEN** an `OWNER`, `MEMBER`, or `COLLABORATOR` opens a PR from a branch in the same repository
- **THEN** the `pull_request` workflow runs and performs OCR review

#### Scenario: Untrusted author opens PR
- **WHEN** a user with any other `author_association` opens a PR
- **THEN** the `pull_request` workflow is skipped and no review is performed

### Requirement: Manual review command is supported
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

### Requirement: Action accepts an identifier input
The action SHALL accept an optional `identifier` input that labels the source of each review comment.

#### Scenario: Identifier provided
- **WHEN** the action is invoked with `identifier: OCR`
- **THEN** each review comment body is prefixed with `[OCR] `

#### Scenario: Identifier omitted
- **WHEN** the action is invoked without an identifier
- **THEN** comments are posted without any prefix

### Requirement: Identifier distinguishes multiple review actions
The action's example workflow SHALL demonstrate how to use different trigger keywords and identifiers for different review actions.

#### Scenario: Two review actions coexist
- **WHEN** one workflow uses `/ocr review` with `identifier: OCR` and another uses `/security review` with `identifier: Security`
- **THEN** each workflow only responds to its own trigger and comments are labeled accordingly

### Requirement: Documentation explains the security model
The action's README SHALL document why fork PRs are not automatically reviewed and how to trigger them manually.

#### Scenario: User reads security notes
- **WHEN** a consumer reads the README
- **THEN** they understand the `pull_request` vs `pull_request_target` trade-off and the purpose of the `author_association` gate
