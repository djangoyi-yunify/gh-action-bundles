## Why

The current `examples/ocr-review.yml` requires consumers to write two checkout steps: a default `actions/checkout` for `pull_request` and a conditional `gh pr checkout` for `issue_comment`. This leaks PR-source complexity to every caller and is easy to get wrong for fork PRs. Moving the checkout logic into the `ocr-review` action itself makes the example workflow smaller, safer by default, and consistent with how `anomalyco/opencode/github` handles PRs internally.

## What Changes

- Add a new `checkout` step to `actions/ocr-review/action.yml` that runs after `configure` and before `resolve-pr`.
- Implement the step in `actions/ocr-review/src/checkout.ts` (compiled to `dist/checkout.js`).
- The step queries the PR metadata via `gh pr view` to obtain `headRefName`, `headRepository`, and `baseRepository`, then:
  - For same-repo PRs: fetches and checks out `origin/<headRefName>`.
  - For fork PRs: adds the fork as a remote, fetches the head branch, and checks it out locally.
- This mirrors the fork-vs-local branch handling in `anomalyco/opencode/github/index.ts`.
- Add an optional `auto-checkout` action input defaulting to `true`; set to `false` when the caller wants to manage checkout itself.
- Ensure `actions/checkout@v4` with `fetch-depth: 0` is still used inside the action when checkout is enabled, so the full history needed by OCR is available.
- Simplify `examples/ocr-review.yml` to remove checkout steps.
- Update `actions/ocr-review/README.md` usage example and input table.
- Rebuild `dist/` and run lint.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `ocr-review`: Add a requirement that the action checks out the repository and the correct PR head branch for both same-repo and fork PRs.

## Impact

- New file: `actions/ocr-review/src/checkout.ts` and `dist/checkout.js`.
- Updated: `actions/ocr-review/action.yml`, `actions/ocr-review/README.md`, `examples/ocr-review.yml`.
- Possibly updated: `packages/shared/src/github.ts` if a shared helper for head/base repository metadata is added.
- No breaking changes to action inputs other than the new optional `checkout` input.
