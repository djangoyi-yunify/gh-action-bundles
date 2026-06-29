## 1. Modify `post-review.ts`

- [x] 1.1 Remove the `createIssueComment` call in the empty-result branch and keep only the `setOutput` calls and `return`
- [x] 1.2 Remove the `createIssueComment` call and `throw error` in the parse-failure branch, replacing them with the same `setOutput` calls and `return`
- [x] 1.3 Run `pnpm lint` in `actions/ocr-review` to confirm TypeScript compiles cleanly

## 2. Rebuild action artifacts

- [x] 2.1 Run `pnpm build` in `actions/ocr-review` to regenerate `dist/post-review.js`
- [x] 2.2 Verify that `dist/post-review.js` no longer contains the removed comment bodies or `throw` paths
- [x] 2.3 Confirm `dist/` changes are staged alongside the source change

## 3. Verify and finalize

- [x] 3.1 Review the diff to ensure only the two silent paths are changed and valid-comment posting remains untouched
- [ ] 3.2 Commit using the project's commit message convention
