#!/usr/bin/env bash
set -euo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./env.sh
source "${LIB_DIR}/env.sh"

# Create the test repository if it does not exist.
ensure_test_repo() {
  gh_auth_switch "${BASE_OWNER}"
  if ! gh repo view "${BASE_REPO}" >/dev/null 2>&1; then
    echo "Creating repository ${BASE_REPO}..."
    gh repo create "${BASE_REPO}" --public --confirm || true
  else
    echo "Repository ${BASE_REPO} already exists"
  fi
}

# Ensure the fork exists. If not, create it from the base repo.
ensure_fork() {
  gh_auth_switch "${FORK_OWNER}"
  if ! gh repo view "${FORK_REPO}" >/dev/null 2>&1; then
    echo "Creating fork ${FORK_REPO} from ${BASE_REPO}..."
    gh repo fork "${BASE_REPO}" --clone=false --default-branch-only || true
  else
    echo "Fork ${FORK_REPO} already exists"
  fi
}

# List open pull requests in the base repo, returning only numbers.
list_open_prs() {
  gh_auth_switch "${BASE_OWNER}"
  gh pr list --repo "${BASE_REPO}" --state open --json number --jq '.[].number' || true
}

# Close a pull request by number.
close_pr() {
  local pr_number="$1"
  gh_auth_switch "${BASE_OWNER}"
  echo "Closing PR #${pr_number} in ${BASE_REPO}"
  gh pr close "${pr_number}" --repo "${BASE_REPO}" || true
}

# Delete branches in the base repo matching known test prefixes.
delete_test_branches() {
  gh_auth_switch "${BASE_OWNER}"
  local branches
  branches=$(gh api "repos/${BASE_REPO}/git/refs/heads" --jq '.[].ref' 2>/dev/null | sed 's|refs/heads/||' || true)
  for branch in ${branches}; do
    if [[ "${branch}" == tc-* ]] || [[ "${branch}" == test* ]] || [[ "${branch}" == ocr-review/pr* ]]; then
      echo "Deleting base branch: ${branch}"
      gh api "repos/${BASE_REPO}/git/refs/heads/${branch}" --method DELETE || true
    fi
  done
}

# Delete branches in the fork repo matching known test prefixes.
delete_fork_test_branches() {
  gh_auth_switch "${FORK_OWNER}"
  local branches
  branches=$(gh api "repos/${FORK_REPO}/git/refs/heads" --jq '.[].ref' 2>/dev/null | sed 's|refs/heads/||' || true)
  for branch in ${branches}; do
    if [[ "${branch}" == tc-* ]] || [[ "${branch}" == test* ]] || [[ "${branch}" == ocr-review/pr* ]]; then
      echo "Deleting fork branch: ${branch}"
      gh api "repos/${FORK_REPO}/git/refs/heads/${branch}" --method DELETE || true
    fi
  done
}

# Verify that required secrets are set in the test repo.
verify_secrets() {
  gh_auth_switch "${BASE_OWNER}"
  local missing=()
  for secret in OCR_LLM_URL OCR_LLM_AUTH_TOKEN OCR_LLM_MODEL; do
    if ! gh api "repos/${BASE_REPO}/actions/secrets/${secret}" >/dev/null 2>&1; then
      missing+=("${secret}")
    fi
  done
  if [ ${#missing[@]} -gt 0 ]; then
    echo "Error: missing repository secrets in ${BASE_REPO}: ${missing[*]}" >&2
    echo "Please add them via GitHub UI or: gh secret set <name> --repo ${BASE_REPO}" >&2
    exit 1
  fi
  echo "Secrets verified: OCR_LLM_URL, OCR_LLM_AUTH_TOKEN, OCR_LLM_MODEL"
}
