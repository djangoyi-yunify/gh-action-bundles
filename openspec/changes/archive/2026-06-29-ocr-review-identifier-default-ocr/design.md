## Context

The `ocr-review` action currently exposes `identifier` as an optional input with an empty default. The implementation in `src/post-review.ts` skips prefixing when the value is empty, so callers who omit `identifier` get unlabeled comments. We want every review comment to carry a label and use `OCR` as the default.

## Goals / Non-Goals

**Goals:**
- Ensure every review comment body is prefixed with `[{identifier}] `.
- Make `OCR` the default identifier when the caller does not provide one.
- Normalize explicit empty values to `OCR` so the prefix cannot be disabled.
- Keep the input optional in `action.yml` (Option B) to avoid forcing every caller to repeat `identifier: OCR`.

**Non-Goals:**
- Changing the prefix format (still `[{identifier}] `).
- Adding validation errors for empty strings (normalize instead).
- Renaming the input or introducing multiple identifiers.

## Decisions

1. **Default value lives in `action.yml`**
   - Set `identifier.default` to `'OCR'`.
   - This is the canonical source of the default and keeps workflow files simple.

2. **Source code normalizes empty strings to `OCR`**
   - Change `const identifier = getEnv('IDENTIFIER', false) || '';` to `const identifier = getEnv('IDENTIFIER', false) || 'OCR';`.
   - Rationale: GitHub Actions only applies the default when the input is omitted. A caller can still write `identifier: ''`, so the code must treat that the same as omitted.

3. **Keep `identifier` optional (`required: false`)**
   - This matches the user's choice of Option B. The input always has a value, but callers are not forced to supply it.

4. **Update specs, README, and E2E together**
   - The capability spec must state the new default and replace the "no prefix" scenario.
   - The README input table and examples must show `OCR` as the default.
   - The E2E workflow can keep `identifier: OCR` for clarity or rely on the default.

## Risks / Trade-offs

- **[Risk] Breaking change for existing consumers** → Existing workflows that omit `identifier` will start producing `[OCR]`-prefixed comments. This is accepted by the team and noted as **BREAKING** in the proposal. Consumers who want a different prefix can set `identifier` explicitly.
- **[Risk] Default value duplicated between `action.yml` and source code** → The code fallback to `'OCR'` mirrors the `action.yml` default. If one changes without the other, behavior diverges for explicit empty strings. Mitigation: keep the fallback value as a single constant or comment linking the two locations.
- **[Risk] Tests assume empty default** → The E2E scenario that verifies "no prefix when omitted" must be updated. Mitigation: update verification specs and test workflows in the same change.
