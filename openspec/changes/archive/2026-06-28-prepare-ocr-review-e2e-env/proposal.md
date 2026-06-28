## Why

End-to-end verification of the `ocr-review` action requires a dedicated test repository with a known base branch, workflow configuration, secrets, and a clean set of pull requests. Previous verification runs mixed environment setup with test execution, making it hard to reproduce or rerun individual scenarios.

We need a standalone change that prepares and maintains the test environment, so that the same-repo and fork-pr verification changes can assume a clean, reproducible starting state.

## What Changes

- Create or verify the existence of the `gh-action-test-01` test repository.
- Configure the repository with the latest `ocr-review` example workflow.
- Verify or configure the LLM secrets required by the workflow.
- Commit a clean base `main.py` to the `main` branch.
- Close all stale test pull requests and delete their base-repo branches.
- Reset `main` to a known clean commit when necessary.
- Add reusable shell scripts under `scripts/ocr-review-e2e/` for environment setup, GitHub operations, and assertions.

## Capabilities

### New Capabilities
- `ocr-review-e2e-env`: A maintained test repository and automation scripts for `ocr-review` end-to-end testing.

### Modified Capabilities
- None.

## Impact

- Adds new files under `scripts/ocr-review-e2e/`.
- Modifies only the external `gh-action-test-01` repository state.
- No changes to `actions/ocr-review` production code.
