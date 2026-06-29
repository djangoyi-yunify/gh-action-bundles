## Context

The `ocr-review` action's `post-review.ts` step reads `/tmp/ocr-result.json` after the OCR CLI runs. When that file is empty or cannot be parsed as JSON, the current implementation posts explanatory PR comments such as "OpenCodeReview produced no output" or "OpenCodeReview failed to parse output". Because the OCR CLI itself exited successfully, these messages are treated as noise rather than actionable failures.

## Goals / Non-Goals

**Goals:**
- When the OCR CLI succeeds but produces no output file content, the action must not post any PR comment and must succeed.
- When the OCR CLI succeeds but its output cannot be parsed, the action must not post any PR comment and must succeed.
- All existing review-count outputs (`review-count`, `inline-count`, `summary-count`, `failed-count`) must still be emitted as `0` in these cases.

**Non-Goals:**
- Changing behavior when the OCR CLI itself exits with an error; that path continues to report the failure as a PR comment.
- Adding new inputs or outputs.
- Modifying how valid review comments are posted.

## Decisions

1. **Silence both empty and unparseable output**
   - Both cases share the same principle: the CLI succeeded, so there is no user-visible error to report. Removing the `createIssueComment` calls keeps PR threads clean.

2. **Keep the step green**
   - Do not `throw` on parse failure. The action returns normally so callers' workflows are not marked failed for a non-actionable condition.

3. **Preserve output variables**
   - Setting all counts to `0` maintains the existing contract for downstream workflow steps that read these outputs.

4. **No new external behavior or configuration**
   - The change is strictly a removal of comment-posting paths; no new inputs, flags, or outputs are introduced.

## Risks / Trade-offs

- **Lost diagnostic visibility** → Operators can still inspect workflow logs and the `/tmp/ocr-stderr.log` file when debugging; only the PR comment is removed.
- **Parse errors hidden from users** → A parse error usually indicates an OCR CLI bug or JSON format change. By not failing the step, such issues may go unnoticed longer. This is accepted per the principle that the step should not fail when the CLI succeeded.
