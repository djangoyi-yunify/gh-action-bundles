## Why

The `ocr-review` action supports automatic review of same-repository pull requests via the `pull_request` event and manual review via the `/ocr review` comment command. Several features—`author_association` gating, merge-base calculation, automatic checkout, identifier prefixes, and fallback comment handling—must be verified in a real GitHub environment.

Previous verification mixed same-repo and fork-pr scenarios in a single change. This change focuses exclusively on same-repo PRs, making the test matrix smaller, faster, and independent of external fork accounts.

## What Changes

- Add an automated test script `scripts/ocr-review-e2e/run-same-repo.sh` that exercises same-repo PR scenarios.
- Run the script against the prepared `gh-action-test-01` environment.
- Cover required boundary conditions: OWNER trusted paths, manual triggers, merge-base correctness, new and modified files, OCR failures, inline-comment fallback, identifier prefixes, and `auto-checkout: false`.
- **Defer permission-gate scenarios** for `MEMBER`, `COLLABORATOR`, and untrusted authors to a follow-up change or the fork-PR verification change, due to test-account availability constraints.
- List optional/extreme boundary conditions separately so the team can decide whether to test them.
- Record results in this change's tasks.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `ocr-review`: Test results may reveal gaps; if so, update the capability spec or implementation in a follow-up change.

## Impact

- Adds test scripts and records results.
- Does not modify production code unless a bug is discovered.
