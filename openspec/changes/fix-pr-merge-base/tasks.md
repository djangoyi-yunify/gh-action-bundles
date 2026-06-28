## 1. Extend Shared GitHub Helper

- [x] 1.1 Add `getMergeBase(repo, baseRef, headSha, token)` to `packages/shared/src/github.ts`
- [x] 1.2 Use `gh api repos/{owner}/{repo}/compare/{baseRef}...{headSha}` to fetch merge base
- [x] 1.3 Export the new helper from `packages/shared/src/index.ts`
- [x] 1.4 Rebuild `packages/shared/dist/`

## 2. Update resolve-pr Step

- [ ] 2.1 Call `getMergeBase` in `actions/ocr-review/src/resolve-pr.ts`
- [ ] 2.2 Set `merge-base` output in addition to `base-ref` and `head-sha`
- [ ] 2.3 Log merge base SHA for debugging

## 3. Update run-review Step

- [ ] 3.1 Read `OCR_MERGE_BASE` env var in `actions/ocr-review/src/run-review.ts`
- [ ] 3.2 Use merge base SHA as `--from` argument
- [ ] 3.3 Keep `OCR_BASE_REF` available for logging only

## 4. Update action.yml

- [ ] 4.1 Add `merge-base` output to the `Resolve PR context` step
- [ ] 4.2 Pass `OCR_MERGE_BASE` to the `Run review` step

## 5. Build and Verify

- [ ] 5.1 Run `pnpm build` and confirm dist files are updated
- [ ] 5.2 Run `pnpm lint` and confirm type checking passes
- [ ] 5.3 Commit and push changes to `gh-action-bundles@main`
- [ ] 5.4 Create or update a PR where base branch has advanced
- [ ] 5.5 Trigger review and verify diff range is correct
