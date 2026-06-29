## Why

The `ocr-review` action currently treats `identifier` as optional and defaults to an empty string, so review comments have no prefix when the caller omits the input. This makes it hard to guarantee a consistent label for every review comment and conflicts with the desire to brand reviews as coming from OCR by default.

## What Changes

- **BREAKING**: Change the `identifier` input of `actions/ocr-review` from optional-with-empty-default to optional-with-default-`OCR`.
- When `identifier` is omitted, every review comment body is prefixed with `[OCR] `.
- When `identifier` is explicitly provided, that value is used as the prefix.
- Explicitly empty values (e.g., `identifier: ''`) are normalized to `OCR`, so there is no way to disable the prefix.
- Update the OpenSpec capability spec, action metadata (`action.yml`), README, source code, and E2E verification to reflect the new behavior.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `ocr-review`: The requirement "Action accepts an identifier input" changes from optional/no-default to optional/default-`OCR`, and the "identifier omitted" scenario is replaced with a "default identifier is OCR" scenario.

## Impact

- `actions/ocr-review/action.yml`: `identifier.default` becomes `OCR`.
- `actions/ocr-review/README.md`: input table, how-it-works, and multiple-review-actions example need updated wording.
- `actions/ocr-review/src/post-review.ts`: empty identifier fallback changes from `''` to `'OCR'`.
- `actions/ocr-review/dist/post-review.js`: rebuilt from source.
- `openspec/specs/ocr-review/spec.md`: updated requirement and scenarios.
- `openspec/specs/ocr-review-same-repo-verification/spec.md`: identifier verification scenario updated to test the default.
- `scripts/ocr-review-e2e/workflows/ocr-review-identifier.yml` and `run-same-repo.sh`: can simplify or keep explicit `identifier: OCR`.
