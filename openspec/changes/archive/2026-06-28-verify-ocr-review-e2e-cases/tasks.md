## 1. Clean Test Environment

- [x] 1.1 Close PR #1 (test01) without merging
- [x] 1.2 Close PR #2 (test02) without merging
- [x] 1.3 Close PR #4 (test-merge-base) without merging
- [x] 1.4 Close PR #5 (test-merge-base-existing) without merging
- [x] 1.5 Leave PR #3 (fork test-bad-code) open or close it as appropriate (closed as stale)
- [x] 1.6 Delete stale base-repo branches: `test01`, `test02`, `test-merge-base`, `test-merge-base-existing`
- [x] 1.7 Reset `main` to a clean state (reset to fcb0232, removing advancement commits)

## 2. TC-01: Auto-review for trusted same-repo PR

- [x] 2.1 Create branch `tc01-auto-review` from `main`
- [x] 2.2 Modify `main.py` to add `eval()`, hardcoded password, and `os.system()`
- [x] 2.3 Push branch and open PR #6
- [x] 2.4 Confirm `pull_request` workflow runs automatically (run 28316762410)
- [x] 2.5 Confirm comments are posted with `[OCR]` prefix
- [x] 2.6 Record result: workflow ran and posted 2 inline `[OCR]` comments on `main.py` (hardcoded password, eval usage). `os.system()` was not flagged in a separate inline comment.

## 3. TC-02: No auto-review for untrusted fork PR

- [x] 3.1 Reopened fork PR #3 from `yijing1998:test-bad-code` (true external contributor PR)
- [x] 3.2 Confirm `pull_request` workflow is gated for external contributors (run 28316836813 initially `action_required`; after maintainer approval it concluded `skipped` due to `author_association` not in OWNER/MEMBER/COLLABORATOR)
- [x] 3.3 Confirm no comments are posted automatically
- [x] 3.4 Record result: external fork PR does not get automatic review; GitHub additionally requires workflow approval for first-time contributors

## 4. TC-03: Manual `/ocr review` on fork PR

- [x] 4.1 Commented `/ocr review` on PR #3 as OWNER
- [x] 4.2 Confirm `issue_comment` workflow runs (run 28316868114)
- [x] 4.3 Confirm `gh pr checkout` fetches fork head (log shows branch switched to `test-bad-code`)
- [x] 4.4 Confirm comments are posted with `[OCR]` prefix (2 inline comments on `main.py`)
- [x] 4.5 Record result: trusted maintainer can manually trigger review of any fork PR; `[OCR]` comments posted successfully

## 5. TC-04: Merge-base correctness when main advances

- [x] 5.1 Create branch `tc04-merge-base` from `main`
- [x] 5.2 Modify `main.py` to add `undefined_magic_number` bug
- [x] 5.3 Push branch and open PR #8
- [x] 5.4 Push unrelated `README.md` change to `main` (commit 7b15345)
- [x] 5.5 Comment `/ocr review` on PR #8
- [x] 5.6 Verify workflow log shows correct merge-base SHA (`fcb02329cbcb96a1ba8d18f23bffcfd38f7525de`, the divergence point before main advanced)
- [x] 5.7 Verify comments only mention the PR's bug (`undefined_magic_number`) and do not mention the unrelated `README.md` change
- [x] 5.8 Record result: merge-base calculation is correct; review range excludes unrelated main advancement

## 6. TC-05: Manual `/ocr review` on same-repo PR

- [x] 6.1 Create branch `tc05-comment-trigger` from `main`
- [x] 6.2 Modify `main.py` to add `eval()` and hardcoded password
- [x] 6.3 Push branch and open PR #9
- [x] 6.4 Comment `/ocr review` as OWNER
- [x] 6.5 Confirm workflow runs and posts comments (run 28316938966; 2 inline `[OCR]` comments)
- [x] 6.6 Record result: manual trigger works for same-repo PR and posts `[OCR]` comments

## 7. TC-06: Untrusted user cannot trigger `/ocr review`

- [x] 7.1 On PR #9 from TC-05, `yijing1998` commented `/ocr review` (author_association: `NONE`)
- [x] 7.2 Confirm `issue_comment` workflow is skipped by author_association gate (run 28317355667 concluded `skipped`)
- [x] 7.3 Confirm no new comments appear after yijing1998's comment
- [x] 7.4 Record result: untrusted user cannot trigger `/ocr review`; workflow is skipped and no review comments are posted

## 8. TC-07: New file review behavior

- [x] 8.1 Create branch `tc07-new-file-review` from `main`
- [x] 8.2 Add a new file `feature.py` containing `eval()`, hardcoded password, and `os.system()`
- [x] 8.3 Push branch and open PR #10
- [x] 8.4 Trigger review automatically via `pull_request`
- [x] 8.5 Observe OCR behavior: OCR exited with code 1; action posted summary comment `[OCR] ⚠️ OpenCodeReview produced no output. Error: review failed: all 1 file review(s) failed`
- [x] 8.6 Compare with TC-01: existing `main.py` modifications produced inline comments; the newly added `feature.py` did not
- [x] 8.7 Record result: OCR currently fails to review newly added files in this repository/configuration. No doc update made yet pending decision on whether to document as known limitation or investigate further

## 9. Finalize

- [x] 9.1 Summarize all test results (see summary below)
- [x] 9.2 Close test PRs #6, #8, #9, #10 without merging; PR #3 was already closed
- [x] 9.3 Delete base-repo test branches: `tc01-auto-review`, `tc04-merge-base`, `tc05-comment-trigger`, `tc07-new-file-review`
- [x] 9.4 Update production docs: added "Known limitations" section to `actions/ocr-review/README.md` documenting OCR's failure to review newly added files
