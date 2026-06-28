## MODIFIED Requirements

### Requirement: Action uses PR merge base as review starting point
The action SHALL compute the merge base between the PR head and the base branch and use it as the starting point for OCR review.

#### Scenario: Base branch has advanced since PR creation
- **WHEN** the base branch receives new commits after the PR is created but before review
- **THEN** the action reviews only the diff from the PR merge base to the PR head

#### Scenario: Same-repo PR with stable base
- **WHEN** the base branch has not advanced since the PR was created
- **THEN** the merge base equals the previous base branch HEAD and the diff is unchanged

### Requirement: Action still exposes base branch name
The action SHALL continue to output the base branch name for display and logging purposes even when the review uses the merge base SHA.

#### Scenario: Review output logging
- **WHEN** the action resolves a PR
- **THEN** it outputs both `base-ref` (branch name) and `merge-base` (commit SHA)

### Requirement: Action works for fork PRs
The merge base computation SHALL work for PRs opened from fork repositories.

#### Scenario: Fork PR manual review
- **WHEN** a maintainer triggers review on a fork PR
- **THEN** the action computes the merge base using the base branch name and the fork head SHA
