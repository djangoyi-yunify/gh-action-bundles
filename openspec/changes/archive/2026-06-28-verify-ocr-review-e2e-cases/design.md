## Context

The `ocr-review` action has recently gained several features:

1. Optional `identifier` input for labeling comments.
2. `author_association` gate for `pull_request` auto-review.
3. `/ocr review` comment trigger via `issue_comment`.
4. Merge-base calculation to keep the review diff correct when the base branch advances.

These features were tested individually, but not in a clean, reproducible way. The test repository currently has stale PRs from earlier exploratory tests, making it hard to map results to specific features.

## Goals / Non-Goals

**Goals:**
- Establish a clean test environment.
- Run a structured test matrix that covers all new behaviors.
- Resolve the open question of whether OCR reviews newly added files.
- Document results clearly.

**Non-Goals:**
- Modify production code unless a bug is found.
- Automate the tests in CI (this is a one-time manual verification).

## Decisions

### 1. Close existing PRs without merging
**Decision:** Close PR #1 through PR #5 and delete their base-repo branches.

**Rationale:**
- Keeps `main` clean.
- Avoids confusion between old exploratory tests and new structured tests.
- Fork PR branches live in the fork and do not need to be deleted from the base repo.

### 2. Use descriptive branch names
**Decision:** Name branches `tc01-auto-review`, `tc04-merge-base`, `tc07-new-file-review`, etc.

**Rationale:**
- Makes it easy to map branches to test cases.
- Simplifies result reporting.

### 3. Reuse the same problematic code pattern across test cases
**Decision:** Use `eval()`, hardcoded password, and `os.system()` as the injected bugs wherever possible.

**Rationale:**
- OCR has proven it flags these patterns in existing files.
- Keeps the only variable per test case the feature under test, not the code content.

### 4. Record results in the change tasks
**Decision:** Mark each test case task as complete only after observing the actual GitHub output and capturing the conclusion.

**Rationale:**
- Keeps the change as the source of truth for test results.
- Makes it easy to refer back to findings.

## Risks / Trade-offs

- [Risk] Closing PRs without merging loses the historical comments from old tests. → Mitigation: The results were already observed; this change records new structured results.
- [Risk] Fork PR tests require access to the fork account. → Mitigation: Use the existing fork `yijing1998/gh-action-test-01`; if unavailable, document the limitation.
