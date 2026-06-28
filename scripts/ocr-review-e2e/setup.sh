#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/env.sh
source "${SCRIPT_DIR}/lib/env.sh"
# shellcheck source=./lib/github.sh
source "${SCRIPT_DIR}/lib/github.sh"
# shellcheck source=./lib/repo.sh
source "${SCRIPT_DIR}/lib/repo.sh"
# shellcheck source=./lib/assert.sh
source "${SCRIPT_DIR}/lib/assert.sh"

echo "=========================================="
echo "Preparing ocr-review e2e test environment"
echo "Base repo:  ${BASE_REPO}"
echo "Fork repo:  ${FORK_REPO}"
echo "Workdir:    ${TEST_WORKDIR}"
echo "=========================================="

verify_accounts

ensure_test_repo
ensure_fork

prepare_local_clone

echo "Closing stale pull requests..."
for pr_number in $(list_open_prs); do
  close_pr "${pr_number}"
done

echo "Deleting stale test branches..."
delete_test_branches
delete_fork_test_branches

echo "Resetting base branch..."
reset_base_branch "origin/${TEST_BASE_BRANCH}"

echo "Checking base owner token scopes..."
gh_auth_switch "${BASE_OWNER}"
require_repo_token

echo "Deploying workflow..."
deploy_workflow "${SCRIPT_DIR}/../../examples/ocr-review.yml"

echo "Deploying base code..."
deploy_base_code

echo "Verifying secrets..."
verify_secrets

echo ""
echo "=========================================="
echo "Test environment is ready"
echo "=========================================="
