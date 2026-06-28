## ADDED Requirements

### Requirement: Test repository exists
The system SHALL create or verify the existence of a public GitHub repository named `gh-action-test-01` under the user's personal GitHub account.

#### Scenario: Repository creation
- **WHEN** the setup script runs
- **THEN** the repository `gh-action-test-01` exists and is accessible to the test runner

### Requirement: Test repository has the ocr-review workflow
The system SHALL commit the current recommended `ocr-review` workflow to the `main` branch of the test repository.

#### Scenario: Workflow file present
- **WHEN** the test repository is prepared
- **THEN** `.github/workflows/ocr-review.yml` exists and matches the pattern documented in `actions/ocr-review/README.md`

### Requirement: Test repository has required secrets
The system SHALL verify that `OCR_LLM_URL`, `OCR_LLM_AUTH_TOKEN`, and `OCR_LLM_MODEL` are configured as repository secrets.

#### Scenario: Secrets configured
- **WHEN** the setup script validates secrets
- **THEN** all three secrets are present, or the script fails with a clear error message

### Requirement: Test repository has clean base code
The system SHALL commit a minimal, safe Python program to the `main` branch so that PR diffs have a stable starting point.

#### Scenario: Base code on main
- **WHEN** preparation completes
- **THEN** `main.py` with a simple `greet` function exists on `main`

### Requirement: Stale test artifacts are removed
The system SHALL close any open test pull requests and delete their base-repository branches before dependent verifications begin.

#### Scenario: Cleanup completes
- **WHEN** the setup script finishes
- **THEN** no open PRs from test branches remain, and no stale test branches exist in the base repo

### Requirement: Reusable automation scripts are provided
The system SHALL provide shell scripts under `scripts/ocr-review-e2e/` for environment setup, GitHub operations, and assertions.

#### Scenario: Scripts present
- **WHEN** this change is applied
- **THEN** `scripts/ocr-review-e2e/setup.sh` and its library files exist and are executable
