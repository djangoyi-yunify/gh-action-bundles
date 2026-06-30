## Context

The repository `origin` is `git@github.com:djangoyi-yunify/gh-action-bundles.git`. The `ocr-review` composite action exists at `actions/ocr-review/action.yml`. However, all user-facing examples and E2E test templates currently reference the action with the placeholder owner `your-org`. The E2E harness (`scripts/ocr-review-e2e/lib/repo.sh`) compensates by replacing `your-org` with the real owner at deployment time. This is unnecessary once the source files contain the correct owner.

## Goals / Non-Goals

**Goals:**
- Make `examples/ocr-review.yml` copy-paste ready.
- Keep documentation in `actions/ocr-review/README.md` consistent with the example.
- Simplify the E2E harness by removing the placeholder owner replacement.
- Keep E2E workflow templates internally consistent with the real owner.

**Non-Goals:**
- Changing the `ocr-review` action behavior or inputs/outputs.
- Changing branch references (remain `@main`).
- Adding new features or capabilities.

## Decisions

- **Use the real owner `djangoyi-yunify` in all source files.** This makes examples work out of the box and removes the need for runtime string replacement.
- **Keep a comment in `examples/ocr-review.yml` explaining fork replacement.** Users who fork the action can still understand how to adapt the reference.
- **Retain the `concurrency` removal in `repo.sh`.** E2E tests still need to strip `concurrency` to avoid parallel test runs cancelling each other, but the owner replacement is no longer needed.
- **Update README and E2E templates together.** Leaving any `your-org` occurrences would create inconsistencies.

## Risks / Trade-offs

- **[Risk]** If the repository is transferred or heavily forked under a different owner, hardcoded references become stale.  
  **Mitigation:** The comment in `examples/ocr-review.yml` tells users exactly what to replace.
- **[Risk]** Removing the `sed` owner replacement could break external E2E setups that override `BASE_OWNER` to a different account.  
  **Mitigation:** Those setups should already maintain their own workflow templates; the default templates now match the canonical repository.

## Migration Plan

Not applicable. This is a documentation and test-harness cleanup with no deployment steps.
