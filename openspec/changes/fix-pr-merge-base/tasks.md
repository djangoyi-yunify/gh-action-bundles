## 1. Extend Shared GitHub Helper

- [x] 1.1 Add `getMergeBase(repo, baseRef, headSha, token)` to `packages/shared/src/github.ts`
- [x] 1.2 Use `gh api repos/{owner}/{repo}/compare/{baseRef}...{headSha}` to fetch merge base
- [x] 1.3 Export the new helper from `packages/shared/src/index.ts`
- [x] 1.4 Rebuild `packages/shared/dist/`

## 2. Update resolve-pr Step

- [x] 2.1 Call `getMergeBase` in `actions/ocr-review/src/resolve-pr.ts`
- [x] 2.2 Set `merge-base` output in addition to `base-ref` and `head-sha`
- [x] 2.3 Log merge base SHA for debugging

## 3. Update run-review Step

- [x] 3.1 Read `OCR_MERGE_BASE` env var in `actions/ocr-review/src/run-review.ts`
- [x] 3.2 Use merge base SHA as `--from` argument
- [x] 3.3 Keep `OCR_BASE_REF` available for logging only

## 4. Update action.yml

- [x] 4.1 Add `merge-base` output to the `Resolve PR context` step
- [x] 4.2 Pass `OCR_MERGE_BASE` to the `Run review` step

## 5. Build and Verify

- [x] 5.1 Run `pnpm build` and confirm dist files are updated
- [x] 5.2 Run `pnpm lint` and confirm type checking passes
- [x] 5.3 Commit and push changes to `gh-action-bundles@main`
- [x] 5.4 Create or update a PR where base branch has advanced
  - PR: https://github.com/djangoyi-yunify/gh-action-test-01/pull/14
  - Created when main was at `83470e90`
  - Advanced main to `1f0a3c22` via PR https://github.com/djangoyi-yunify/gh-action-test-01/pull/15
- [x] 5.5 Trigger review and verify diff range is correct
  - Run: https://github.com/djangoyi-yunify/gh-action-test-01/actions/runs/28319866011
  - Verified `merge-base: 83470e903f3bf9bcd0df41a140d664ab56218688`
  - Verified `--from 83470e90... --to c4e2e02...` uses the PR merge base, not the current main HEAD
