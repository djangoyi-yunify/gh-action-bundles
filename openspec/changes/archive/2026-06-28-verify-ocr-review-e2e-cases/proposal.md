## Why

After adding the access control gate, manual `/ocr review` trigger, `identifier` prefix, and merge-base calculation to `ocr-review`, the test repository `gh-action-test-01` contains stale PRs from earlier ad-hoc tests. We need to clean up the test environment and run a structured set of end-to-end test cases to verify all new behaviors, including the open question of whether OCR reviews newly added files.

## What Changes

- Close all existing PRs in `gh-action-test-01` without merging.
- Delete stale test branches from the base repository.
- Create seven focused test PRs/branches covering:
  1. Auto-review for trusted same-repo PRs.
  2. No auto-review for fork PRs from untrusted authors.
  3. Manual `/ocr review` trigger on fork PRs by maintainers.
  4. Correct merge-base calculation when `main` advances after PR creation.
  5. Manual `/ocr review` trigger on same-repo PRs.
  6. No manual trigger for untrusted commenters.
  7. Whether OCR reviews newly added files.
- Record the outcome of each test case.
- Update the main `ocr-review` spec or documentation if any test reveals a bug or unexpected behavior.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- None expected. If tests reveal issues, update the relevant capability (likely `ocr-review`).

## Impact

- Only affects the test repository `gh-action-test-01` and this OpenSpec change.
- No changes to `gh-action-bundles` code unless a bug is discovered.
