## Why

The `ocr-review` action currently posts PR comments such as "OpenCodeReview produced no output" when the OCR CLI returns no results, and "OpenCodeReview failed to parse output" when the JSON cannot be parsed. These comments add noise to PRs without indicating an actionable failure, because the OCR CLI itself exited successfully. Silencing these cases keeps PR threads focused on real review findings.

## What Changes

- Modify `actions/ocr-review/src/post-review.ts` so that when `/tmp/ocr-result.json` is empty or missing, the action sets all review-count outputs to `0` and returns without posting a PR comment.
- Modify the same file so that when OCR output cannot be parsed as JSON, the action sets all review-count outputs to `0` and returns without posting a PR comment or failing the step.
- Rebuild and commit `actions/ocr-review/dist/post-review.js` so the composite action uses the updated behavior.
- Update the `ocr-review` capability spec to reflect the new silent handling of empty and unparseable output.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `ocr-review`: Changes the requirement for handling empty or unparseable OCR output from "post a PR comment explaining the situation" to "do not post any comment and keep the step successful".

## Impact

- `actions/ocr-review/src/post-review.ts`
- `actions/ocr-review/dist/post-review.js`
- `openspec/specs/ocr-review/spec.md`
