## Why

Fork pull requests have a different security and execution context than same-repo PRs. The `pull_request` event runs in the fork repository context without access to base-repository secrets, so automatic review must be skipped. Manual review via `/ocr review` on an `issue_comment` event runs in the base repository context and is the intended path for reviewing fork PRs.

Previous verification covered fork PRs but combined them with same-repo scenarios. This change isolates fork PR verification, including cross-repository checkout, merge-base calculation across forks, and permission gating.

## What Changes

- Add an automated test script `scripts/ocr-review-e2e/run-fork.sh` that exercises fork PR scenarios.
- Run the script against the prepared `gh-action-test-01` environment using an external fork account.
- Cover required boundary conditions: automatic skip for external and trusted fork PRs, manual `/ocr review` by trusted users, comment gating, cross-repo checkout, and merge-base correctness.
- List optional/extreme boundary conditions separately so the team can decide whether to test them.
- Record results in this change's tasks.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `ocr-review`: Test results may reveal gaps; if so, update the capability spec or implementation in a follow-up change.

## Impact

- Adds test scripts and records results.
- Requires access to an external fork account.
- Does not modify production code unless a bug is discovered.
