## Why

The current `ocr-review` action passes `origin/<base-ref>` as the `--from` argument to OCR. When the base branch (e.g. `main`) advances after a PR is created—for example because another PR is merged first—`origin/main` no longer represents the point where the PR diverged. This causes OCR to review an incorrect diff that may include unrelated changes or make the PR's own changes appear as reversions. We need to use the PR's merge base as the diff starting point.

## What Changes

- Extend `resolve-pr` to compute and output the PR merge base SHA.
- Update `run-review` to use the merge base SHA as the `--from` argument instead of `origin/<base-ref>`.
- Keep `base-ref` output for logging/display purposes.
- Update `action.yml` to pass the new output through the step chain.
- Update `README.md` and the test repository workflow if necessary.
- Verify the fix with a PR whose base branch has moved forward since creation.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `ocr-review`: Update the review range calculation to use the PR merge base instead of the current base branch ref.

## Impact

- `actions/ocr-review/src/resolve-pr.ts` gains merge-base resolution.
- `actions/ocr-review/src/run-review.ts` changes its `--from` argument.
- `actions/ocr-review/action.yml` passes the new output.
- Review accuracy improves when the base branch advances between PR creation and review.
