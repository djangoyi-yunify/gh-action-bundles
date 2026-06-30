## 1. Update example workflow

- [x] 1.1 Replace `your-org` with `djangoyi-yunify` in `examples/ocr-review.yml`.
- [x] 1.2 Add a comment above the `uses` line explaining how to replace the owner when forking the action.

## 2. Update README

- [x] 2.1 Replace all `your-org` occurrences in `actions/ocr-review/README.md` with `djangoyi-yunify`.

## 3. Update E2E workflow templates

- [x] 3.1 Replace all `your-org` occurrences in `scripts/ocr-review-e2e/workflows/ocr-review-failure.yml` with `djangoyi-yunify`.
- [x] 3.2 Replace all `your-org` occurrences in `scripts/ocr-review-e2e/workflows/ocr-review-inline-fallback.yml` with `djangoyi-yunify`.
- [x] 3.3 Replace all `your-org` occurrences in `scripts/ocr-review-e2e/workflows/ocr-review-auto-checkout-false.yml` with `djangoyi-yunify`.
- [x] 3.4 Replace all `your-org` occurrences in `scripts/ocr-review-e2e/workflows/ocr-review-identifier.yml` with `djangoyi-yunify`.

## 4. Clean up E2E harness

- [x] 4.1 Remove the `sed` placeholder replacement for `your-org` from `scripts/ocr-review-e2e/lib/repo.sh`.
- [x] 4.2 Keep the `concurrency` removal step and update the surrounding comment to reflect that source files now contain the real owner.

## 5. Verify

- [x] 5.1 Search the repository for any remaining `your-org` references and confirm none exist outside of change artifacts.
- [x] 5.2 Run `pnpm lint` or `tsc --noEmit` for affected actions if applicable.
