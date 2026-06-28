## Context

GitHub Actions provides two primary ways to react to pull requests:

- `pull_request`: Runs in the PR's own context. Safe for untrusted code, but for fork PRs it does not receive repository secrets and the `GITHUB_TOKEN` is read-only.
- `pull_request_target`: Runs in the base repository context. Receives secrets and a writable token, but executes with elevated privileges and is harder to use safely.

The current `ocr-review` README recommends `pull_request_target`, which is convenient but not the safest default. The goal is to switch to a pattern that:

1. Automatically reviews PRs opened by trusted authors (same repo or known collaborators).
2. Allows trusted maintainers to manually request a review of any PR via a comment command.
3. Does not fail on PRs from untrusted contributors.

## Goals / Non-Goals

**Goals:**
- Provide a safer default workflow example using `pull_request` + `issue_comment`.
- Add an `author_association` gate matching opencode-pr-reviewer (`OWNER`, `MEMBER`, `COLLABORATOR`).
- Support `/ocr review` as a manual trigger for any PR, including fork PRs.
- Document the security model clearly.

**Non-Goals:**
- Add automatic review of arbitrary fork PRs.
- Implement complex multi-workflow orchestration.

## Decisions

### 1. Workflow events: `pull_request` + `issue_comment`
**Decision:** Use `pull_request` for automatic reviews and `issue_comment` for manual triggers.

**Rationale:**
- `pull_request` is the safer default because it does not expose secrets to fork PRs.
- `issue_comment` runs in the base repository context, so it can access secrets and write comments even on fork PRs.
- This matches the established pattern from `opencode-pr-reviewer`.

### 2. Author association gate
**Decision:** Allow automatic review only for `OWNER`, `MEMBER`, and `COLLABORATOR`.

**Rationale:**
- These identities have a direct trust relationship with the repository.
- `CONTRIBUTOR` (someone whose PR was merged but who is not a collaborator) is deliberately excluded, following opencode-pr-reviewer's conservative model.
- The gate prevents untrusted users from consuming LLM API credits and from causing noisy workflow failures.

### 3. Manual trigger command: `/ocr review`
**Decision:** Support the exact command `/ocr review` at the start of a comment or preceded by a space.

**Rationale:**
- Simple and memorable.
- Avoids accidental triggers by requiring a specific prefix.

### 4. Checkout handling for comment triggers
**Decision:** For `issue_comment` triggers, run `gh pr checkout <number>` after the default checkout.

**Rationale:**
- `issue_comment` workflows check out the default branch by default.
- `gh pr checkout` switches to the PR head and fetches the necessary refs.
- This step is skipped for `pull_request` triggers where the PR code is already checked out.

### 5. Action identifier input
**Decision:** Add an optional `identifier` input to the action. When provided, inline and summary comments are prefixed with `[{identifier}] `.

**Rationale:**
- Allows multiple review actions to coexist in the same repository without confusing output.
- Makes it clear to PR authors which tool produced each comment.
- Keeps the trigger keyword customization in the workflow while centralizing output branding in the action.

## Risks / Trade-offs

- [Risk] Fork PRs are not automatically reviewed. → Mitigation: Document that maintainers can trigger review manually via `/ocr review`.
- [Risk] Trusted members opening fork PRs still cannot get automatic review under `pull_request`. → Mitigation: They can use `/ocr review` or the repository can opt into `pull_request_target` if they accept the risk.
- [Risk] Comment trigger requires the commenter to have `OWNER`, `MEMBER`, or `COLLABORATOR` association. → Mitigation: This is intentional; it prevents unauthorized users from consuming API credits.
