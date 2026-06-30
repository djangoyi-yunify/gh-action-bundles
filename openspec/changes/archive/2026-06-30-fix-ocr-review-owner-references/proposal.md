## Why

The example workflow `examples/ocr-review.yml` and related documentation reference `your-org/gh-action-bundles/actions/ocr-review@main`, which is not a real repository. This makes copy-paste usage fail and forces the E2E test harness to perform a runtime placeholder replacement. We should use the actual action owner and remove the now-unnecessary placeholder logic.

## What Changes

- Replace `your-org` with `djangoyi-yunify` in `examples/ocr-review.yml` and add a comment explaining how users can replace the owner if they fork the action.
- Replace all `your-org` occurrences in `actions/ocr-review/README.md` with `djangoyi-yunify`.
- Replace all `your-org` occurrences in E2E workflow templates under `scripts/ocr-review-e2e/workflows/` with `djangoyi-yunify`.
- Clean up `scripts/ocr-review-e2e/lib/repo.sh` by removing the `sed` placeholder replacement for the action owner while keeping the `concurrency` removal step.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This change only fixes documentation and test harness plumbing; it does not alter the behavior or requirements of any existing capability.

## Impact

- User-facing examples become copy-paste ready.
- Documentation stays consistent with the example.
- E2E tests no longer rely on runtime string replacement for the action owner, making the harness simpler and less surprising.
