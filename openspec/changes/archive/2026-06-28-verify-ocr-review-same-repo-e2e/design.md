## Context

Same-repository PRs are the simplest e2e scenario for `ocr-review`. The `pull_request` event runs in the base repository context, has access to secrets, and the action's automatic checkout can fetch `origin/<headRef>` directly.

This change runs a structured, automated test matrix against the prepared `gh-action-test-01` repository.

## Goals / Non-Goals

**Goals:**
- Verify `author_association` gating for `OWNER` on automatic and manual triggers.
- Verify merge-base calculation when the base branch advances.
- Verify automatic checkout, review execution, and comment posting.
- Verify identifier prefix, OCR failure handling, and inline-comment fallback.
- Produce reproducible results with minimal manual steps.

**Non-Goals:**
- Cover fork PR behavior (handled by a separate change).
- Automate LLM-output assertions (we assert comment existence, not content).

## Decisions

### 1. One script per scenario family
**Decision:** `run-same-repo.sh` accepts flags or environment variables to run specific scenario groups: `auto`, `manual`, `merge-base`, `checkout`, `fallback`.

**Rationale:**
- Speeds up reruns when only one boundary condition is being debugged.
- Keeps the script readable.

### 2. Test branch names encode the scenario
**Decision:** Use branch names like `tc-auto-owner`, `tc-manual-collab`, `tc-merge-base`.

**Rationale:**
- Makes workflow logs and PR lists self-documenting.
- Simplifies cleanup.

### 3. Assertions focus on outcomes, not LLM content
**Decision:** The script asserts:
- Workflow run conclusion (`success`, `skipped`, `failure`).
- Presence of `[OCR]` review comments or summary comments.
- Absence of comments when the gate skips the run.

**Rationale:**
- LLM output is non-deterministic.
- The action's contract is to run OCR and post comments, not to produce specific findings.

### 4. Scenarios are cleaned up automatically
**Decision:** After each scenario passes, close the PR and delete the base-repo branch.

**Rationale:**
- Keeps the test repository tidy.
- Failed scenarios are left open for inspection.

## Scenario Matrix

```
                    pull_request           issue_comment
                   ┌─────────────┐        ┌─────────────┐
OWNER              │  run + post │        │  run + post │
                   │  comments   │        │  comments   │
                   └─────────────┘        └─────────────┘

MEMBER/            │  deferred   │        │  deferred   │
COLLABORATOR/      │             │        │             │
CONTRIBUTOR/NONE   └─────────────┘        └─────────────┘
```

This change verifies the `OWNER` trusted path. `MEMBER`, `COLLABORATOR`, and untrusted-author scenarios are deferred due to test-account availability.

## Account Model

Same-repo tests run entirely under the base-repository owner account (`djangoyi-yunify`). The `yijing1998` account is not used here because same-repo PRs opened by `yijing1998` would actually come from a fork, which belongs to the fork PR change.

This change focuses exclusively on the `OWNER` trusted path. `MEMBER`, `COLLABORATOR`, and untrusted-author scenarios are deferred to a follow-up change or to the fork-PR verification change, because the current test environment does not provide the required accounts.

## Risks / Trade-offs

- [Risk] GitHub API rate limits during rapid PR/comment creation. → Mitigation: add small delays between operations.
- [Risk] Workflow run polling can be slow. → Mitigation: configurable timeout; print progress.
- [Risk] MEMBER/COLLABORATOR accounts may not be available in a personal test org. → Mitigation: document that these scenarios require the corresponding association and can be skipped if unavailable.
