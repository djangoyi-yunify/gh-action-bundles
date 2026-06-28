# OCR Review E2E Test Scripts

This directory contains helper scripts for end-to-end testing of the `ocr-review` Composite Action.

## Prerequisites

- `gh` CLI installed and authenticated with two accounts:
  - `djangoyi-yunify` — owner of the test base repository
  - `yijing1998` — external contributor who owns the fork
- Both accounts must have the `repo` OAuth scope.

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `BASE_OWNER` | `djangoyi-yunify` | GitHub account that owns the base test repo |
| `FORK_OWNER` | `yijing1998` | GitHub account that owns the fork |
| `TEST_REPO_NAME` | `gh-action-test-01` | Name of the test repository |
| `TEST_WORKDIR` | `/tmp/ocr-review-e2e` | Local clone path used by scripts |

## Usage

### Prepare the test environment

```bash
./scripts/ocr-review-e2e/setup.sh
```

This will:

1. Verify both `gh` accounts are logged in.
2. Create `djangoyi-yunify/gh-action-test-01` if it does not exist.
3. Create `yijing1998/gh-action-test-01` as a fork if it does not exist.
4. Close all open PRs in the base repo.
5. Delete stale test branches from both base repo and fork.
6. Reset `main` to `origin/main`.
7. Deploy `.github/workflows/ocr-review.yml` from `examples/ocr-review.yml`.
8. Commit a clean `main.py` base file.
9. Verify that `OCR_LLM_URL`, `OCR_LLM_AUTH_TOKEN`, and `OCR_LLM_MODEL` secrets are set.

### Run verifications

After setup, run the same-repo or fork PR verification scripts:

```bash
./scripts/ocr-review-e2e/run-same-repo.sh
./scripts/ocr-review-e2e/run-fork.sh
```

(These scripts are created by their respective OpenSpec changes.)

## Script Layout

```
scripts/ocr-review-e2e/
├── README.md
├── setup.sh
└── lib/
    ├── env.sh      # environment variables and gh auth switch helpers
    ├── github.sh   # gh CLI wrappers for repos, PRs, branches, secrets
    ├── repo.sh     # local clone and commit helpers
    └── assert.sh   # workflow run assertions and polling
```

## Safety Notes

- `setup.sh` closes open PRs and deletes branches matching `tc-*`, `test*`, or `ocr-review/pr*`. Review the script before running it against a repo that contains important work.
- The scripts do not create or update GitHub secrets automatically; they only verify that the required secrets exist.
