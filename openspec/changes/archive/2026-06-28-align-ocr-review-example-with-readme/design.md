## Context

The `actions/ocr-review/README.md` already documents the recommended workflow pattern:

- Trigger on `pull_request` (auto) and `issue_comment` (manual).
- Gate both triggers on `author_association` being `OWNER`, `MEMBER`, or `COLLABORATOR`.
- Use `/ocr review` as the manual trigger phrase.
- Use `actions/checkout@v4` with `fetch-depth: 0` and `gh pr checkout` for comment triggers.

`examples/ocr-review.yml` was created earlier and still uses `pull_request_target` without the `author_association` gate and with the `/ocr` trigger phrase. This contradicts both the README and the `ocr-review` spec, which now expects the example workflow to follow the safer default pattern.

## Goals / Non-Goals

**Goals:**
- Update `examples/ocr-review.yml` to use the same security model as the README example.
- Keep beneficial enhancements already present in the example (`concurrency`, `ready_for_review`, `background`).
- Ensure the example satisfies the `ocr-review` spec requirements for the example workflow.

**Non-Goals:**
- Change the `ocr-review` action implementation, inputs, outputs, or `dist/` files.
- Change the README example (it is already correct).
- Introduce a separate `pull_request_target` example.

## Decisions

### 1. Keep `concurrency`, `ready_for_review`, and `background`
**Decision:** Preserve the existing `concurrency` group, `ready_for_review` event type, and `background: ${{ github.event.pull_request.title }}` input.

**Rationale:**
- These are not security-sensitive and improve the example's usefulness.
- Removing them would make the example a strict subset of the README sample, which is unnecessary as long as the event model and access controls match.

### 2. Align access controls with README
**Decision:** Add `author_association` checks for both `pull_request` and `issue_comment` triggers, exactly as shown in README.

**Rationale:**
- This is the core security requirement from the `ocr-review` spec.
- Without it, fork PRs or untrusted comments could consume LLM tokens or post unwanted comments.

### 3. Use `/ocr review` as the manual trigger phrase
**Decision:** Change the `issue_comment` condition from `startsWith(github.event.comment.body, '/ocr')` to `startsWith(github.event.comment.body, '/ocr review')`.

**Rationale:**
- The spec and README already use `/ocr review`.
- `/ocr` is ambiguous and could accidentally match unrelated comments.

### 4. Adopt README checkout pattern
**Decision:** Replace the `actions/github-script` step that resolves the PR head SHA with the README pattern: default checkout for `pull_request`, and `gh pr checkout` for `issue_comment`.

**Rationale:**
- Simpler and consistent with README.
- `gh pr checkout` works in the base repository context of `issue_comment` events.

## Risks / Trade-offs

- [Risk] Users who copied the old `pull_request_target` example will need to update their workflows. → Mitigation: This is an intentional security improvement; the README already documents the new pattern.
- [Risk] Removing `pull_request_target` means automatic review of arbitrary fork PRs is no longer possible with this example. → Mitigation: The README still explains how to opt into `pull_request_target` if a repository explicitly accepts the security trade-off.
