## Context

The `ocr-review` action currently prefixes every review comment body with `[{identifier}] ` on the same line. After the previous change, the identifier defaults to `OCR` and empty values are normalized to `OCR`. We now want to make the identifier label more explicit by rendering it as `Reviewer ID: [{identifier}]` on its own line, with the review content starting on the next line.

## Goals / Non-Goals

**Goals:**
- Change the rendered comment format so the identifier label is on its own line.
- Use the exact format `Reviewer ID: [{identifier}]\n{body}` for all comments.
- Apply the format to both inline review comments and summary issue comments.
- Keep the `identifier` input semantics unchanged; only the presentation changes.

**Non-Goals:**
- Changing the `identifier` input name, default value, or normalization behavior.
- Adding a blank line between the identifier label and the content.
- Making the label text configurable.

## Decisions

1. **Single helper change**
   - Update only the `prefixIdentifier` function in `src/post-review.ts`.
   - Return `Reviewer ID: [${identifier}]\n${body}`.
   - All callers (inline comments, summary comments) automatically get the new format.

2. **No blank line**
   - The newline immediately follows the identifier label; the review body starts on the second line.
   - This matches the user's requirement that OCR content appears on the second line.

3. **Fixed label text**
   - Use `Reviewer ID:` as a fixed prefix. The `identifier` input only controls the bracketed value.
   - This keeps the format consistent and predictable across different identifiers.

## Risks / Trade-offs

- **[Risk] Breaking change for consumers** → Workflows that previously saw `[OCR] **Title**...` will now see `Reviewer ID: [OCR]\n**Title**...`. This is accepted and marked as **BREAKING** in the proposal.
- **[Risk] Existing E2E assertion still needs identifier substring** → The `assert_comment_contains` check looks for `[OCR]`; the new format still contains `[OCR]`, so the existing `grep -F` assertion still works.
