#!/usr/bin/env bash
set -euo pipefail

# Default accounts for the e2e test environment.
# Override these via environment variables if needed.
: "${BASE_OWNER:=djangoyi-yunify}"
: "${FORK_OWNER:=yijing1998}"
: "${TEST_REPO_NAME:=gh-action-test-01}"
: "${BASE_REPO:=${BASE_OWNER}/${TEST_REPO_NAME}}"
: "${FORK_REPO:=${FORK_OWNER}/${TEST_REPO_NAME}}"
: "${TEST_BASE_BRANCH:=main}"
: "${WORKFLOW_FILE:=.github/workflows/ocr-review.yml}"

# Ensure required tools are available.
require_gh() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "Error: gh CLI is not installed" >&2
    exit 1
  fi
}

# Verify that both the base owner and fork owner accounts are logged in.
verify_accounts() {
  require_gh
  local status
  status=$(gh auth status 2>&1 || true)
  if ! echo "$status" | grep -q "account ${BASE_OWNER}"; then
    echo "Error: gh account ${BASE_OWNER} is not logged in. Run: gh auth login" >&2
    exit 1
  fi
  if ! echo "$status" | grep -q "account ${FORK_OWNER}"; then
    echo "Error: gh account ${FORK_OWNER} is not logged in. Run: gh auth login" >&2
    exit 1
  fi
  echo "Accounts verified: ${BASE_OWNER}, ${FORK_OWNER}"
}

# Switch the active gh account.
# Usage: gh_auth_switch <account>
gh_auth_switch() {
  local account="$1"
  require_gh
  local current
  current=$(gh_active_account)
  if [ "${current}" = "${account}" ]; then
    return 0
  fi

  local retries=0
  local max_retries=3
  while [ "${retries}" -lt "${max_retries}" ]; do
    if gh auth switch --user "${account}" >/dev/null 2>&1; then
      echo "Switched gh account to ${account}" >&2
      return 0
    fi
    retries=$((retries + 1))
    echo "Retry ${retries}/${max_retries}: failed to switch gh account to ${account}" >&2
    sleep 1
  done

  echo "Error: failed to switch gh account to ${account} after ${max_retries} attempts" >&2
  exit 1
}

# Print the currently active gh account username.
gh_active_account() {
  gh auth status --active 2>&1 | awk '/Active account: true/ { active=1 }
       /account [^ ]+/ { match($0, /account [^ ]+/); user=substr($0, RSTART+7, RLENGTH-7); gsub(/^[ \t]+|[ \t]+$/, "", user) }
       END { if (active) print user }'
}

# Ensure the GitHub token for the active account has repo and workflow access.
require_repo_token() {
  local token_scopes
  token_scopes=$(gh auth status --active 2>&1 | grep "Token scopes" || true)
  if ! echo "$token_scopes" | grep -q "repo"; then
    echo "Error: active gh token does not have 'repo' scope" >&2
    exit 1
  fi
  if ! echo "$token_scopes" | grep -q "workflow"; then
    echo "Error: active gh token does not have 'workflow' scope, which is required to push workflow files" >&2
    echo "Run: gh auth refresh -h github.com -s workflow" >&2
    exit 1
  fi
}
