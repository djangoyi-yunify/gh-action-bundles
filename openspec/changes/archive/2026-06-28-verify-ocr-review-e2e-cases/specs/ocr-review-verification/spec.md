## ADDED Requirements

### Requirement: Test environment is clean before structured verification
The test repository SHALL have no open exploratory PRs or stale test branches before the structured test cases run.

#### Scenario: Test repository cleanup
- **WHEN** structured verification begins
- **THEN** all previous test PRs are closed and base-repo test branches are removed

### Requirement: Auto-review gate is verified for same-repo PRs
The verification SHALL confirm that trusted authors receive automatic review and untrusted authors do not.

#### Scenario: Trusted same-repo PR
- **WHEN** an OWNER/MEMBER/COLLABORATOR opens a same-repo PR
- **THEN** the `pull_request` workflow runs and posts review comments

#### Scenario: Untrusted fork PR
- **WHEN** an external user opens a fork PR
- **THEN** the `pull_request` workflow is skipped by the author_association gate

### Requirement: Manual review trigger is verified for trusted commenters
The verification SHALL confirm that `/ocr review` triggers review for trusted commenters on both same-repo and fork PRs.

#### Scenario: Manual trigger on same-repo PR
- **WHEN** a trusted user comments `/ocr review` on a same-repo PR
- **THEN** the `issue_comment` workflow runs and posts review comments

#### Scenario: Manual trigger on fork PR
- **WHEN** a trusted user comments `/ocr review` on a fork PR
- **THEN** the `issue_comment` workflow runs and posts review comments

#### Scenario: Untrusted user manual trigger
- **WHEN** an external user comments `/ocr review`
- **THEN** the `issue_comment` workflow is skipped by the author_association gate

### Requirement: Merge-base calculation is verified
The verification SHALL confirm that review uses the PR merge base even when the base branch advances after PR creation.

#### Scenario: Base branch advances
- **WHEN** the base branch receives unrelated commits after the PR is created
- **THEN** the review only covers changes from the PR merge base to the PR head

### Requirement: New file review behavior is verified
The verification SHALL determine whether OCR reviews newly added files in a PR.

#### Scenario: PR adds a new file with known bugs
- **WHEN** a PR adds a new `.py` file containing `eval()`, hardcoded password, and `os.system()`
- **THEN** the test records whether OCR produces comments, a "no supported files" message, or another response
