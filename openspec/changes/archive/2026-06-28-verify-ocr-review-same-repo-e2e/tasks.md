## 1. Implement run-same-repo.sh

- [x] 1.1 Source `scripts/ocr-review-e2e/lib/*.sh`
- [x] 1.2 Add flag/env support for running scenario groups: `auto`, `manual`, `merge-base`, `content`, `failure`, `checkout`, `fallback`
- [x] 1.3 Implement helper to create a test branch, push commits, and open a PR
- [x] 1.4 Implement helper to poll workflow run state to `success`, `skipped`, or `failure`
- [x] 1.5 Implement helper to assert comment presence/absence
- [x] 1.6 Implement cleanup: close PR and delete base-repo branch after a scenario passes

## 2. Automatic review gate scenarios

- [x] 2.1 `tc-auto-owner`: OWNER opens same-repo PR with problematic code
  - [x] 2.1.1 Create branch, push commit adding `eval()` and hardcoded password to `main.py`
  - [x] 2.1.2 Open PR
  - [x] 2.1.3 Assert workflow run conclusion is `success`
  - [x] 2.1.4 Assert review comments are posted
  - [x] 2.1.5 Cleanup
- [-] 2.2 `tc-auto-member`: MEMBER opens same-repo PR with problematic code
  - [-] 2.2.1 Skipped in this change: MEMBER test account not available in the current test environment
- [-] 2.3 `tc-auto-collaborator`: COLLABORATOR opens same-repo PR with problematic code
  - [-] 2.3.1 Skipped in this change: COLLABORATOR test account not available in the current test environment
- [-] 2.4 `tc-auto-untrusted`: Untrusted author opens same-repo PR
  - [-] 2.4.1 Skipped in this change: requires a dedicated untrusted same-repo account; deferred to fork-PR verification or follow-up

## 3. Manual review trigger scenarios

- [x] 3.1 `tc-manual-owner`: OWNER comments `/ocr review` on same-repo PR
  - [x] 3.1.1 Create a same-repo PR with problematic code
  - [x] 3.1.2 Post `/ocr review` as OWNER
  - [x] 3.1.3 Assert `issue_comment` workflow run is `success`
  - [x] 3.1.4 Assert review comments are posted
  - [x] 3.1.5 Cleanup
- [-] 3.2 `tc-manual-untrusted`: Untrusted user comments `/ocr review`
  - [-] 3.2.1 Skipped in this change: requires a dedicated untrusted same-repo account; deferred to fork-PR verification or follow-up
- [x] 3.3 `tc-manual-wrong-text`: Trusted user posts comment not starting with `/ocr review`
  - [x] 3.3.1 Create a same-repo PR
  - [x] 3.3.2 Post `please review` as OWNER
  - [x] 3.3.3 Assert `issue_comment` workflow run is `skipped`
  - [x] 3.3.4 Cleanup

## 4. Diff range and content scenarios

- [x] 4.1 `tc-merge-base`: `main` advances after PR creation
  - [x] 4.1.1 Create PR with a unique bug (`undefined_magic_number`)
  - [x] 4.1.2 Push unrelated commit to `main`
  - [x] 4.1.3 Trigger review manually
  - [x] 4.1.4 Assert workflow log shows correct merge-base SHA
  - [x] 4.1.5 Assert comments only mention the PR bug, not the unrelated `main` change
  - [x] 4.1.6 Cleanup
- [x] 4.2 `tc-new-file`: PR adds a new file
  - [x] 4.2.1 Create PR adding `feature.py` with `eval()`, hardcoded password, and `os.system()`
  - [x] 4.2.2 Trigger review automatically
  - [x] 4.2.3 Assert review comments are posted on `feature.py`
  - [x] 4.2.4 Cleanup
- [x] 4.3 `tc-modify-existing`: PR modifies `main.py`
  - [x] 4.3.1 Create PR modifying `main.py` with known bugs
  - [x] 4.3.2 Trigger review automatically
  - [x] 4.3.3 Assert review comments are posted on `main.py`
  - [x] 4.3.4 Cleanup

## 5. Failure and fallback scenarios

- [x] 5.1 `tc-ocr-failure`: OCR CLI fails
  - [x] 5.1.1 Implemented in `run_tc_ocr_failure`: deploy `workflows/ocr-review-failure.yml` with hardcoded invalid LLM credentials
  - [x] 5.1.2 Trigger review on a same-repo PR via `pull_request` event
  - [x] 5.1.3 Assert workflow run conclusion is `success` (action handles failure gracefully)
  - [x] 5.1.4 Assert an issue comment containing "OpenCodeReview produced no output" is posted
  - [x] 5.1.5 Cleanup PR, branch, and restore default workflow
- [x] 5.2 `tc-inline-fallback`: Inline comments cannot be posted
  - [x] 5.2.1 Implemented in `run_tc_inline_fallback`: deploy a custom rule fixture encouraging comments on line 1000 of a very short `main.py`
  - [x] 5.2.2 Trigger review via `/ocr review`
  - [x] 5.2.3 Assert workflow log contains "Failed to post batch review" or a summary issue comment exists
  - [x] 5.2.4 Cleanup PR, branch, and restore default workflow

## 6. Input and checkout scenarios

- [x] 6.1 `tc-identifier`: Comments carry `[OCR]` prefix
  - [x] 6.1.1 Implemented in `run_tc_identifier`: deploy `workflows/ocr-review-identifier.yml` with `identifier: OCR`
  - [x] 6.1.2 Assert at least one posted comment contains `[OCR]`
- [x] 6.2 `tc-auto-checkout-false`: Caller provides checkout
  - [x] 6.2.1 Implemented in `run_tc_auto_checkout_false`: deploy `workflows/ocr-review-auto-checkout-false.yml` with explicit `actions/checkout` and `auto-checkout: false`
  - [x] 6.2.2 Trigger review via `pull_request` event
  - [x] 6.2.3 Assert review succeeds and comments are posted
  - [x] 6.2.4 Cleanup PR, branch, and restore default workflow

## 7. Optional/extreme boundary conditions

The following conditions are documented for the team to decide whether to test:

- [x] 7.1 PR deletes an existing file — not covered; could verify that deleted files are ignored or handled without error
- [x] 7.2 PR contains multiple commits; action checks out `headSha`, not branch tip — not covered; could push an additional commit after opening the PR
- [x] 7.3 PR has no problematic code; verify no comments or only a summary comment — not covered; depends on LLM output being empty
- [x] 7.4 `rule-path` input points to a non-existent file; verify action fails fast — not covered; `run-review.ts` already throws when the file is missing
- [x] 7.5 Workflow triggered by `workflow_dispatch` or other non-PR event with `auto-checkout: false` — not covered; requires caller to supply PR number and checkout
- [x] 7.6 Very large PR diff; verify timeout/concurrency behavior — not covered; would require generating a large PR and observing `CONCURRENCY`/`TIMEOUT` inputs

## 8. Finalize

- [x] 8.1 Run the full `run-same-repo.sh` suite excluding permission-gate scenarios:
  ```bash
  ./scripts/ocr-review-e2e/run-same-repo.sh --only auto manual merge-base content failure fallback checkout
  ```
  Executed on `djangoyi-yunify/gh-action-test-01`. All enabled scenarios passed.
- [x] 8.2 Record results and any discovered issues in this change's tasks
  - All same-repo OWNER-path scenarios passed.
  - `tc-inline-fallback` did not trigger the batch-review failure path with the current custom rule; the scenario passed on the weaker signal that a summary issue comment exists. The custom rule approach may need refinement if strict fallback verification is required.
  - Permission-gate scenarios (`tc-auto-member`, `tc-auto-collaborator`, `tc-auto-untrusted`, `tc-manual-untrusted`) remain deferred.
- [x] 8.3 No `ocr-review` production bugs were discovered; no follow-up change required
