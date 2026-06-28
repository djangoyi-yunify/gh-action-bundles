## Context

The `ocr-review` action is verified manually in a dedicated test repository named `gh-action-test-01`. The repository must be kept in a known clean state before each structured verification run. This change extracts that preparation work from the test scenarios themselves.

## Goals / Non-Goals

**Goals:**
- Provide a reproducible test environment for `ocr-review` e2e tests.
- Capture environment setup logic in version-controlled shell scripts.
- Keep the test repository `main` branch clean and stable.

**Non-Goals:**
- Automate the full e2e verification (this is handled by the dependent changes).
- Modify `ocr-review` production code.

## Decisions

### 1. Scripts live in `scripts/ocr-review-e2e/`
**Decision:** Place all e2e automation scripts under `scripts/ocr-review-e2e/`.

**Rationale:**
- Keeps test infrastructure separate from action distribution code.
- Matches common convention for repository-level helper scripts.
- Scripts are not part of the Composite Action, so they do not need to be committed to `dist/`.

### 2. Environment setup is idempotent
**Decision:** `setup.sh` can be run repeatedly; it creates the test repository only if it does not exist, re-applies the workflow and secrets checks, and cleans stale branches/PRs.

**Rationale:**
- Makes reruns cheap and safe.
- Allows the dependent verification changes to assume a clean state.

### 3. Base code is a simple Python file
**Decision:** Commit a minimal `main.py` with a single safe `greet` function to `main`.

**Rationale:**
- Provides a stable target for PR diffs.
- Test branches can introduce known problematic patterns (`eval()`, hardcoded passwords, `os.system()`).

### 4. Secrets are checked but not set
**Decision:** The script verifies that `OCR_LLM_URL`, `OCR_LLM_AUTH_TOKEN`, and `OCR_LLM_MODEL` are configured, but does not create them automatically.

**Rationale:**
- Secrets cannot be created safely via CLI in a generic way without exposing values.
- The script fails fast with a clear message if secrets are missing.

### 5. Two GitHub accounts are pre-configured for `gh auth switch`
**Decision:** The test environment assumes two `gh` CLI accounts are available: the base-repository owner (`djangoyi-yunify`) and an external fork user (`yijing1998`). Scripts switch between them with `gh auth switch`.

**Rationale:**
- Allows a single developer workstation to simulate both the repository owner and an external contributor.
- Avoids the need for a third test account.
- The fork PR verification change relies on `yijing1998` to open PRs and post untrusted comments.

## Script Layout

```
scripts/ocr-review-e2e/
├── README.md
├── setup.sh              # main entry for this change
├── run-same-repo.sh      # added by verify-ocr-review-same-repo-e2e
├── run-fork.sh           # added by verify-ocr-review-fork-pr-e2e
├── lib/
│   ├── env.sh            # environment variables, gh auth switch, token scopes
│   ├── github.sh         # gh CLI wrappers for repos, PRs, branches, runs
│   ├── repo.sh           # local clone, branch, commit, push helpers
│   └── assert.sh         # workflow run and comment assertions
└── tests/
    ├── test_env.sh       # unit tests for account parsing helpers
    ├── test_repo.sh      # unit tests for file generation helpers
    └── run_all.sh        # test runner
```

## Lessons Learned

### Older `gh` CLI versions lack `--json` on `gh pr create`
The initial implementation used `gh pr create --json number`, which is not supported in the installed `gh` version. We now create the PR silently and then call `gh pr view <branch> --json number` to retrieve the PR number.

### Workflow run filtering differs by event type
- `pull_request` runs are associated with the PR head branch.
- `issue_comment` runs are associated with the base branch (`main`).
- Because multiple issue_comment runs can exist concurrently, matching by PR title is required. PR titles must therefore be unique; we include the test branch name in the title.

### `gh auth switch` can be flaky
Added retry logic and idempotency so scripts do not fail or spam logs when the active account is already correct.

### Inline review comments are not in `gh pr view --json reviews`
Inline comments must be fetched via the API endpoint `repos/{repo}/pulls/{pr_number}/comments`. Comment presence assertions check both top-level review bodies and inline comments, including the file path.

### Concurrency cancels cross-PR issue_comment runs
The example workflow includes a `concurrency` group that cancels in-progress runs when a new comment is posted. For e2e testing, this concurrency block is removed from the deployed workflow so that each test scenario's run completes independently.

## Risks / Trade-offs

- [Risk] External test repository may be deleted or renamed. → Mitigation: `setup.sh` recreates it if missing.
- [Risk] Manual secrets setup is error-prone. → Mitigation: script prints exact secret names and checks their presence.
- [Risk] Cleaning stale PRs/branches is destructive. → Mitigation: only target branches matching known test prefixes (`tc-`, `test`, `ocr-review/pr`).
