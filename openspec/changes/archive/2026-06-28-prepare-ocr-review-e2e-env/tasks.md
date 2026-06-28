## 1. Bootstrap script structure

- [x] 1.1 Create directory `scripts/ocr-review-e2e/`
- [x] 1.2 Create `scripts/ocr-review-e2e/lib/env.sh` to validate accounts, repos, and token scopes
- [x] 1.3 Create `scripts/ocr-review-e2e/lib/github.sh` with wrappers for repo, PR, branch, and secret operations
- [x] 1.4 Create `scripts/ocr-review-e2e/lib/repo.sh` with local clone, branch, commit, and push helpers
- [x] 1.5 Create `scripts/ocr-review-e2e/lib/assert.sh` with helpers for run state and comment presence
- [x] 1.6 Create `scripts/ocr-review-e2e/README.md` documenting required environment variables and usage

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

## 3. Finalize

- [x] 3.1 Review script output and error messages
- [x] 3.2 Mark dependent changes `verify-ocr-review-same-repo-e2e` and `verify-ocr-review-fork-pr-e2e` as unblocked
