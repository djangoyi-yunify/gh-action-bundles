## Context

Fork PRs are the most security-sensitive scenario for `ocr-review`. The `pull_request` event runs in the fork repository context and cannot access base-repository secrets, so the action must not execute automatically for fork PRs. The supported path is a maintainer commenting `/ocr review`, which triggers an `issue_comment` event in the base repository context.

This change runs a structured, automated test matrix for fork PRs against the prepared `gh-action-test-01` repository.

## Goals / Non-Goals

**Goals:**
- Verify automatic review is skipped for fork PRs regardless of author trust level.
- Verify manual `/ocr review` works for trusted commenters on fork PRs.
- Verify cross-repository checkout fetches the fork head branch correctly.
- Verify merge-base calculation spans the fork and base repositories.
- Document platform behaviors such as first-time contributor workflow approval.

**Non-Goals:**
- Cover same-repo PR behavior (handled by a separate change).
- Require automatic review to work for arbitrary fork PRs.

## Decisions

### 1. Fork account is `yijing1998`
**Decision:** The fork PR verification uses `yijing1998` as the external contributor. The base repository is owned by `djangoyi-yunify`. Scripts switch between the two accounts using `gh auth switch`.

**Rationale:**
- The development environment already has both accounts configured for `gh auth switch`.
- `yijing1998` simulates an untrusted external contributor for skip scenarios.
- The base owner (`djangoyi-yunify`) posts trusted `/ocr review` comments.

### 2. Fork PR branches are created on the fork
**Decision:** Test branches like `tc-fork-auto` and `tc-fork-manual` are pushed to `yijing1998/gh-action-test-01`, and PRs are opened from the fork to `djangoyi-yunify/gh-action-test-01`.

**Rationale:**
- Matches real-world fork PR behavior.
- Tests the action's cross-repository checkout path.

### 3. Manual trigger runs from the base repo
**Decision:** The `/ocr review` comment is posted by `djangoyi-yunify` using the base repo's token.

**Rationale:**
- `issue_comment` runs in the base repository context, so the commenter must have base-repo permissions.
- Tests the intended security model.

### 4. Extreme scenarios are documented but optional
**Decision:** Scenarios such as "fork source branch deleted before review" and "organization fork vs personal fork" are listed as optional. The team decides per-run whether to execute them.

**Rationale:**
- Some extreme scenarios depend on GitHub caching behavior and may be flaky.
- Keeps the required test suite stable.

## Scenario Matrix

```
                              pull_request        issue_comment
                             ┌───────────┐       ┌───────────┐
External user fork PR        │  skipped  │       │  skipped  │
                             └───────────┘       └───────────┘

Trusted user fork PR         │  skipped  │       │ run + post│
(OWNER/MEMBER/COLLABORATOR)  │  (no      │       │ comments  │
                              │  secrets) │       │           │
                             └───────────┘       └───────────┘
```

The key insight: `pull_request` for a fork PR is skipped **because the event runs in the fork context**, not only because the author is untrusted.

## Account Switching Flow

```
Base owner (djangoyi-yunify)
        │
        ├──▶ setup test repo, push to main
        │
        ├──▶ post `/ocr review` on fork PRs  ──▶ issue_comment runs in base context
        │
        ▼
yijing1998 (gh auth switch)
        │
        ├──▶ create branches on fork
        ├──▶ open fork PRs
        └──▶ post untrusted `/ocr review` comments
```

## Risks / Trade-offs

- [Risk] `gh auth switch` may leave the wrong account active after a run. → Mitigation: script prints the active account before each operation; `setup.sh` verifies both accounts at start.
- [Risk] Fork account access may be lost. → Mitigation: script validates fork permissions early and exits with clear instructions.
- [Risk] First-time contributor workflows require manual approval. → Mitigation: script detects `action_required` state and prompts the operator.
- [Risk] Cross-repository operations are slower. → Mitigation: configurable timeouts and progress logging.
