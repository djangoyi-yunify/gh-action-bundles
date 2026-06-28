## Why

The `examples/ocr-review.yml` workflow still uses `pull_request_target` and lacks the `author_association` gate, while `actions/ocr-review/README.md` already recommends the safer `pull_request` + `issue_comment` pattern. This inconsistency makes the example contradict the project's security guidelines and the default pattern documented for users.

## What Changes

- Switch `examples/ocr-review.yml` from `pull_request_target` to `pull_request`.
- Add the `author_association` gate (`OWNER` / `MEMBER` / `COLLABORATOR`) for both `pull_request` auto-review and `issue_comment` manual triggers.
- Align the manual trigger phrase with README: `/ocr` → `/ocr review`.
- Adopt the checkout pattern from README (default checkout + `gh pr checkout` for comment triggers) instead of fetching the head SHA via `actions/github-script`.
- Preserve beneficial enhancements already present in the example: `concurrency`, `ready_for_review` type, and passing the PR title as `background`.
- Remove any remaining references to `pull_request_target` from the example.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `ocr-review`: Add a requirement that the bundled `examples/ocr-review.yml` workflow matches the README-recommended default pattern (`pull_request`, `author_association` gate, `/ocr review` trigger).

## Impact

- Only `examples/ocr-review.yml` is modified.
- No changes to `actions/ocr-review` source, `action.yml`, or built `dist/` files.
