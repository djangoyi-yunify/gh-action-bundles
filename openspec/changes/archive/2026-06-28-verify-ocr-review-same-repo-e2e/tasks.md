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
- [ ] 2.2 `tc-auto-member`: MEMBER opens same-repo PR with problematic code
  - [ ] 2.2.1 Repeat steps 2.1.1-2.1.5 with a MEMBER account (skip if unavailable)
- [ ] 2.3 `tc-auto-collaborator`: COLLABORATOR opens same-repo PR with problematic code
  - [ ] 2.3.1 Repeat steps 2.1.1-2.1.5 with a COLLABORATOR account (skip if unavailable)
- [ ] 2.4 `tc-auto-untrusted`: Untrusted author opens same-repo PR
  - [ ] 2.4.1 Create branch and PR from an untrusted account (requires third account)
  - [ ] 2.4.2 Assert workflow run conclusion is `skipped`
  - [ ] 2.4.3 Assert no review comments are posted
  - [ ] 2.4.4 Cleanup

## 3. Manual review trigger scenarios

- [x] 3.1 `tc-manual-owner`: OWNER comments `/ocr review` on same-repo PR
  - [x] 3.1.1 Create a same-repo PR with problematic code
  - [x] 3.1.2 Post `/ocr review` as OWNER
  - [x] 3.1.3 Assert `issue_comment` workflow run is `success`
  - [x] 3.1.4 Assert review comments are posted
  - [x] 3.1.5 Cleanup
- [x] 3.2 `tc-manual-untrusted`: Untrusted user comments `/ocr review`
  - [x] 3.2.1 Create a same-repo PR
  - [x] 3.2.2 Switch to `yijing1998` via `gh auth switch` and post `/ocr review`
  - [x] 3.2.3 Assert workflow run conclusion is `skipped`
  - [x] 3.2.4 Assert no new review comments appear
  - [x] 3.2.5 Cleanup
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

- [ ] 5.1 `tc-ocr-failure`: OCR CLI fails
  - [ ] 5.1.1 Temporarily configure invalid LLM credentials in the test repo
  - [ ] 5.1.2 Trigger review on a same-repo PR
  - [ ] 5.1.3 Assert workflow run is `success` (action handles failure gracefully)
  - [ ] 5.1.4 Assert an issue comment containing OCR stderr is posted
  - [ ] 5.1.5 Restore valid credentials
  - [ ] 5.1.6 Cleanup
- [ ] 5.2 `tc-inline-fallback`: Inline comments cannot be posted
  - [ ] 5.2.1 Create a scenario where inline comment line numbers are invalid (e.g., comment on a deleted line)
  - [ ] 5.2.2 Trigger review
  - [ ] 5.2.3 Assert a summary issue comment is posted containing the fallback content
  - [ ] 5.2.4 Cleanup

## 6. Input and checkout scenarios

- [ ] 6.1 `tc-identifier`: Comments carry `[OCR]` prefix
  - [ ] 6.1.1 Run a successful review scenario with `identifier: OCR` configured in the workflow
  - [ ] 6.1.2 Assert every posted comment starts with `[OCR]`
- [ ] 6.2 `tc-auto-checkout-false`: Caller provides checkout
  - [ ] 6.2.1 Create a workflow variant that checks out the PR head before calling `ocr-review` with `auto-checkout: false`
  - [ ] 6.2.2 Trigger review
  - [ ] 6.2.3 Assert review succeeds and comments are posted
  - [ ] 6.2.4 Cleanup

## 7. Optional/extreme boundary conditions

The following conditions are documented for the team to decide whether to test:

- [ ] 7.1 PR deletes an existing file
- [ ] 7.2 PR contains multiple commits; action checks out `headSha`, not branch tip
- [ ] 7.3 PR has no problematic code; verify no comments or only a summary comment
- [ ] 7.4 `rule-path` input points to a non-existent file; verify action fails fast
- [ ] 7.5 Workflow triggered by `workflow_dispatch` or other non-PR event with `auto-checkout: false`
- [ ] 7.6 Very large PR diff; verify timeout/concurrency behavior

## 8. Finalize

- [ ] 8.1 Run the full `run-same-repo.sh` suite
- [ ] 8.2 Record results and any discovered issues
- [ ] 8.3 If bugs are found, create follow-up changes to fix `ocr-review`
