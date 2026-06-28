## Why

The current example workflow uses `pull_request_target`, which supports fork PRs but runs with elevated permissions and is easy to misconfigure. Users have reported that switching to `pull_request` causes fork PRs to fail because secrets and write permissions are unavailable. We need a safer default workflow that:

1. Works reliably for same-repository PRs.
2. Avoids failing on untrusted fork PRs.
3. Still allows trusted maintainers to review fork PRs on demand.

This aligns with the approach used by `opencode-pr-reviewer`: use `pull_request` with an `author_association` gate for automatic reviews, and `issue_comment` for manual review triggers on any PR.

## What Changes

- Replace the `pull_request_target` example in `actions/ocr-review/README.md` with a `pull_request` + `issue_comment` workflow.
- Add an `author_association` gate so only `OWNER`, `MEMBER`, and `COLLABORATOR` can trigger automatic reviews.
- Add support for a `/ocr review` comment command that trusted users can use on any PR, including fork PRs.
- Add an optional `identifier` input to the action so multiple review actions can coexist; the identifier is prepended to review comments.
- Document the security model and the limitation that fork PRs are not automatically reviewed.
- Update the `gh-action-test-01` test repository workflow to match the new recommended pattern.
- Verify the change with same-repo PR and comment-triggered e2e tests.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `ocr-review`: Update workflow usage requirements to support `issue_comment` triggers and require `author_association` gating for automatic review.
- `github-action-standard`: Update the documented workflow pattern and security notes.

## Impact

- `actions/ocr-review/README.md` workflow example changes.
- Test repository `.github/workflows/ocr-review.yml` changes.
- `AGENTS.md` may need a note about the recommended workflow pattern.
- `actions/ocr-review/action.yml` gains a new optional `identifier` input.
- `actions/ocr-review/src/post-review.ts` prefixes/suffixes comments with the identifier.
