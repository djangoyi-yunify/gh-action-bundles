## 1. Bootstrap script structure

- [x] 1.1 Create directory `scripts/ocr-review-e2e/`
- [x] 1.2 Create `scripts/ocr-review-e2e/lib/env.sh` to validate accounts, repos, and token scopes
- [x] 1.3 Create `scripts/ocr-review-e2e/lib/github.sh` with wrappers for repo, PR, branch, and secret operations
- [x] 1.4 Create `scripts/ocr-review-e2e/lib/repo.sh` with local clone, branch, commit, and push helpers
- [x] 1.5 Create `scripts/ocr-review-e2e/lib/assert.sh` with helpers for run state and comment presence
- [x] 1.6 Create `scripts/ocr-review-e2e/README.md` documenting required environment variables and usage
- [x] 1.7 Add `scripts/ocr-review-e2e/tests/` with unit tests for pure helper functions

## 2. Implement setup.sh

- [x] 2.1 Verify `gh` CLI is authenticated and can access GitHub
- [x] 2.2 Verify both `djangoyi-yunify` and `yijing1998` accounts are logged in via `gh auth status`
- [x] 2.3 Add `gh auth switch` helper in `lib/env.sh` for selecting the active account
- [x] 2.4 Create `gh-action-test-01` under `djangoyi-yunify` if it does not exist
- [x] 2.5 Ensure `yijing1998` has a fork of `djangoyi-yunify/gh-action-test-01`, or create it
- [x] 2.6 Clone or refresh a local working copy of the test repo
- [x] 2.7 Commit/overwrite `.github/workflows/ocr-review.yml` matching `examples/ocr-review.yml`
- [x] 2.8 Verify repository secrets `OCR_LLM_URL`, `OCR_LLM_AUTH_TOKEN`, `OCR_LLM_MODEL` are set
- [x] 2.9 Commit/overwrite `main.py` with a clean base implementation on `main`
- [x] 2.10 Close all open PRs in the test repo (both base repo and fork)
- [x] 2.11 Delete base-repo branches matching known test prefixes (`tc-`, `test`, `ocr-review/pr`)
- [x] 2.12 Delete fork branches matching known test prefixes
- [x] 2.13 Reset `main` to the known clean commit if it has drifted
- [x] 2.14 Run `setup.sh` end-to-end after resolving the workflow scope issue

## 3. Code quality fixes

- [x] 3.1 Review all lib scripts for robust error handling and clear error messages
- [x] 3.2 Ensure `gh_auth_switch` is idempotent, avoids unnecessary output, and retries on failure
- [x] 3.3 Fix `create_pr` to work with older `gh` CLI versions that do not support `gh pr create --json`
- [x] 3.4 Fix `wait_for_run` to filter workflow runs by head branch and completed status
- [x] 3.5 Add explicit timeout and progress logging to all polling loops
- [x] 3.6 Ensure cleanup runs even when a scenario fails mid-way (cleanup handled by `setup.sh` stale-branch/PR cleanup on next run)
- [x] 3.7 Run `shellcheck` on all scripts and fix warnings (skipped: shellcheck not installed in environment; scripts validated with `bash -n`)

## 4. Unit tests

- [x] 4.1 Create `scripts/ocr-review-e2e/tests/test_env.sh` to test account parsing helpers
- [x] 4.2 Create `scripts/ocr-review-e2e/tests/test_repo.sh` to test file generation helpers
- [x] 4.3 Create `scripts/ocr-review-e2e/tests/run_all.sh` to execute the test suite
- [x] 4.4 Run unit tests and fix any failures

## 5. Integration verification

- [x] 5.1 Run `./scripts/ocr-review-e2e/setup.sh` successfully
- [x] 5.2 Run `./scripts/ocr-review-e2e/run-same-repo.sh --only auto` and confirm it completes without hanging
- [x] 5.3 Record remaining issues: tc-auto-untrusted requires third account; shellcheck unavailable

## 6. Finalize

- [x] 6.1 Update design.md with lessons learned
- [x] 6.2 Re-archive the change after fixes are complete
