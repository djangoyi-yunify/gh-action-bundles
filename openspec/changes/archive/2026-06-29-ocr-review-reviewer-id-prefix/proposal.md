## Why

The current `[OCR]` inline prefix is visually thin and does not clearly communicate that the value is a reviewer identifier. Putting `Reviewer ID: [OCR]` on its own line and starting the review content on the next line makes the label explicit and improves readability.

## What Changes

- **BREAKING**: Change the comment prefix format from `[{identifier}] {body}` to `Reviewer ID: [{identifier}]\n{body}`.
- Inline review comments and summary issue comments both use the new multi-line format.
- The first line contains only `Reviewer ID: [{identifier}]` with no trailing blank line.
- The second line begins the OCR-generated review content.
- Update the OpenSpec capability spec, README, source code, built artifacts, and E2E verification to reflect the new format.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `ocr-review`: The requirement "Action accepts an identifier input" changes its expected comment format from an inline prefix to a two-line format starting with `Reviewer ID: [{identifier}]`.

## Impact

- `actions/ocr-review/src/post-review.ts`: `prefixIdentifier` returns the new two-line format.
- `actions/ocr-review/dist/post-review.js`: rebuilt from source.
- `actions/ocr-review/README.md`: input description, how-it-works, and multiple-review-actions example updated.
- `openspec/specs/ocr-review/spec.md`: identifier scenarios updated to the new format.
- `openspec/specs/ocr-review-same-repo-verification/spec.md`: identifier verification scenario updated.
- `scripts/ocr-review-e2e/lib/github.sh`: existing `grep -F` assertion works with the new format once comments contain the identifier.
