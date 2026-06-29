## 1. Update implementation

- [x] 1.1 Change `actions/ocr-review/src/post-review.ts` `prefixIdentifier` to return `Reviewer ID: [${identifier}]\n${body}`
- [x] 1.2 Build the action with `pnpm build` and commit `actions/ocr-review/dist/post-review.js`

## 2. Update documentation

- [x] 2.1 Update `actions/ocr-review/README.md` how-it-works section to describe the two-line format
- [x] 2.2 Update `actions/ocr-review/README.md` multiple-review-actions example output description

## 3. Update OpenSpec main spec

- [x] 3.1 Apply the modified `ocr-review` requirement from the change delta spec to `openspec/specs/ocr-review/spec.md`
- [x] 3.2 Update `openspec/specs/ocr-review-same-repo-verification/spec.md` identifier scenario to verify the new two-line format

## 4. Update E2E verification if needed

- [x] 4.1 Confirm `scripts/ocr-review-e2e/run-same-repo.sh` `tc-identifier` assertion still matches the new format
- [x] 4.2 Update `scripts/ocr-review-e2e/README.md` if it describes the identifier output format

## 5. Verify

- [x] 5.1 Run `pnpm lint` in `actions/ocr-review`
- [x] 5.2 Confirm `dist/post-review.js` contains the new `Reviewer ID:` format
- [x] 5.3 Review all changed files against the spec scenarios
