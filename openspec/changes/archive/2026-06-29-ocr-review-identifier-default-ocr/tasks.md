## 1. Update action metadata

- [x] 1.1 Change `actions/ocr-review/action.yml` `identifier` input to `required: false` with `default: 'OCR'`
- [x] 1.2 Update the `identifier` description to reflect the default value and that empty values are normalized

## 2. Update implementation

- [x] 2.1 Change `actions/ocr-review/src/post-review.ts` empty-identifier fallback from `''` to `'OCR'`
- [x] 2.2 Build the action with `pnpm build` and commit `actions/ocr-review/dist/post-review.js`

## 3. Update documentation

- [x] 3.1 Update `actions/ocr-review/README.md` inputs table: set `identifier` default to `OCR` and remove "Optional" wording
- [x] 3.2 Update `actions/ocr-review/README.md` "How it works" section to state that comments are always prefixed
- [x] 3.3 Update `actions/ocr-review/README.md` "Multiple review actions" example wording if needed

## 4. Update OpenSpec main spec

- [x] 4.1 Apply the modified `ocr-review` requirement from the change delta spec to `openspec/specs/ocr-review/spec.md`
- [x] 4.2 Update `openspec/specs/ocr-review-same-repo-verification/spec.md` identifier scenario to verify the default `OCR` behavior

## 5. Update E2E tests

- [x] 5.1 Review `scripts/ocr-review-e2e/workflows/ocr-review-identifier.yml` and decide whether to keep explicit `identifier: OCR` or rely on the default
- [x] 5.2 Update `scripts/ocr-review-e2e/run-same-repo.sh` `tc-identifier` scenario description and assertions to match the new default behavior
- [x] 5.3 Update `scripts/ocr-review-e2e/README.md` if it describes the identifier test case

## 6. Verify

- [x] 6.1 Run `pnpm lint` in `actions/ocr-review`
- [x] 6.2 Confirm `dist/post-review.js` contains the normalized fallback to `OCR`
- [x] 6.3 Review all changed files against the spec scenarios
