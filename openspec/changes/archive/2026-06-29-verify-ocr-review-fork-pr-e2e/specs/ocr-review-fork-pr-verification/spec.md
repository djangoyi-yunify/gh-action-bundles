## ADDED Requirements

### Requirement: Automatic review is skipped for external fork PRs
The verification SHALL confirm that `pull_request` workflows are skipped for fork PRs opened by external contributors.

#### Scenario: External user opens fork PR
- **WHEN** a user with `NONE` or `CONTRIBUTOR` association opens a fork PR
- **THEN** the `pull_request` workflow is skipped and no review comments are posted

### Requirement: Automatic review is skipped even for trusted fork PR authors
The verification SHALL confirm that `pull_request` workflows are skipped for fork PRs opened by trusted authors, because the event runs in the fork context without base-repo secrets.

#### Scenario: OWNER opens fork PR
- **WHEN** an `OWNER`, `MEMBER`, or `COLLABORATOR` opens a fork PR
- **THEN** the `pull_request` workflow is skipped and no review comments are posted

### Requirement: Trusted users can manually review fork PRs
The verification SHALL confirm that `/ocr review` triggers review for trusted commenters on fork PRs.

#### Scenario: OWNER comments `/ocr review` on fork PR
- **WHEN** an `OWNER`, `MEMBER`, or `COLLABORATOR` comments `/ocr review` on a fork PR
- **THEN** the `issue_comment` workflow runs and posts `[OCR]` review comments

### Requirement: Untrusted users cannot manually review fork PRs
The verification SHALL confirm that `/ocr review` from untrusted commenters on fork PRs is ignored.

#### Scenario: External user comments `/ocr review` on fork PR
- **WHEN** a user outside the trusted set comments `/ocr review` on a fork PR
- **THEN** the `issue_comment` workflow is skipped and no comments are posted

### Requirement: Cross-repository checkout works for fork PRs
The verification SHALL confirm that the action adds the fork as a remote, fetches the head branch, and checks it out locally.

#### Scenario: Normal fork PR checkout
- **WHEN** a manual review is triggered on a fork PR
- **THEN** the workflow log shows the fork remote added and the fork head branch checked out

### Requirement: Merge-base calculation works across fork and base
The verification SHALL confirm that the action computes the correct merge base for a fork PR.

#### Scenario: Base branch advances after fork PR creation
- **WHEN** `main` receives unrelated commits after the fork PR is opened, and a review is triggered
- **THEN** the review only covers the diff from the merge base to the fork PR head

### Requirement: New files in fork PRs are reviewed
The verification SHALL confirm that fork PRs adding new files produce review comments.

#### Scenario: Fork PR adds a new file with known bugs
- **WHEN** a fork PR adds a new `.py` file containing `eval()`, hardcoded password, and `os.system()`
- **THEN** the manual review posts `[OCR]` review comments on the new file

### Requirement: Modified existing files in fork PRs are reviewed
The verification SHALL confirm that fork PRs modifying existing files produce review comments.

#### Scenario: Fork PR modifies an existing file with known bugs
- **WHEN** a fork PR modifies `main.py` to introduce `eval()`, hardcoded password, or `os.system()`
- **THEN** the manual review posts `[OCR]` review comments on the modified file

### Requirement: First-time contributor approval is documented
The verification SHALL record GitHub's behavior when a first-time contributor opens a fork PR and workflow approval is required.

#### Scenario: First-time contributor fork PR
- **WHEN** a first-time contributor opens a fork PR
- **THEN** the workflow remains in `action_required` until a maintainer approves, after which the `author_association` gate skips it

### Requirement: Optional boundary conditions are documented
The verification SHALL list fork PR boundary conditions that are not part of the required test suite so the team can decide whether to test them.

#### Scenario: Optional conditions reviewed
- **WHEN** the team reviews the optional list
- **THEN** they can choose to add any of them to the current or a future run
