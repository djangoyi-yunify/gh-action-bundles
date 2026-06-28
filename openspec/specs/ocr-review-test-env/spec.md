# OCR Review Test Environment

## Purpose

Establish a dedicated test repository and sample Pull Requests to validate the OCR Review Action end-to-end.

## Requirements

### Requirement: Create test repository
The system SHALL create a public repository named `gh-action-test-01` under the user's personal GitHub account.

#### Scenario: Repository creation
- **WHEN** the user creates `gh-action-test-01`
- **THEN** the repository exists and is accessible

### Requirement: Initialize main branch with base code
The system SHALL commit a basic Python Hello World program to the `main` branch.

#### Scenario: Base code on main
- **WHEN** `main.py` with a simple `greet` function is committed to `main`
- **THEN** the `main` branch contains the base code

### Requirement: Create test01 branch with problematic code
The system SHALL create a `test01` branch containing code with obvious issues suitable for generating inline review comments.

#### Scenario: Problematic code branch
- **WHEN** `test01` branch is pushed with hardcoded credentials and unsafe `os.system` usage
- **THEN** the branch is available for opening a Pull Request

### Requirement: Create test02 branch with clean code
The system SHALL create a `test02` branch containing clean, well-structured code.

#### Scenario: Clean code branch
- **WHEN** `test02` branch is pushed with type-annotated, safe Python code
- **THEN** the branch is available for opening a Pull Request

### Requirement: Configure workflow in test repository
The system SHALL add a GitHub Actions workflow to `main` that invokes `gh-action-bundles/actions/ocr-review@main` on pull requests.

#### Scenario: Workflow file present
- **WHEN** `.github/workflows/ocr-review.yml` is committed to `main`
- **THEN** opening or updating a PR triggers the workflow

### Requirement: Configure LLM secrets
The system SHALL configure the required secrets in the test repository for the OCR action to authenticate with the LLM endpoint.

#### Scenario: Secrets configured
- **WHEN** `OCR_LLM_URL`, `OCR_LLM_AUTH_TOKEN`, and `OCR_LLM_MODEL` are set in repository secrets
- **THEN** the workflow can access them via `${{ secrets.* }}`

### Requirement: Open Pull Requests for test branches
The system SHALL open Pull Requests from `test01` and `test02` to `main`.

#### Scenario: test01 Pull Request
- **WHEN** a Pull Request is opened from `test01` to `main`
- **THEN** the OCR workflow runs and attempts to post inline review comments

#### Scenario: test02 Pull Request
- **WHEN** a Pull Request is opened from `test02` to `main`
- **THEN** the OCR workflow runs and attempts to post a summary comment

### Requirement: Record test results
The system SHALL record the outcome of the test workflows for later analysis.

#### Scenario: Workflow completion
- **WHEN** each test workflow completes
- **THEN** the results are captured in the workflow logs and PR comments
