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

# Create a pull request. Returns the PR number.
# Usage: create_pr <title> <body> <head-branch> <base-branch>
create_pr() {
  local title="$1"
  local body="$2"
  local head_branch="$3"
  local base_branch="${4:-${TEST_BASE_BRANCH}}"
  gh_auth_switch "${BASE_OWNER}"
  gh pr create --repo "${BASE_REPO}" --title "${title}" --body "${body}" --base "${base_branch}" --head "${head_branch}" >/dev/null 2>&1
  gh pr view "${head_branch}" --repo "${BASE_REPO}" --json number --jq '.number'
}

# Post a comment on a PR or issue.
# Usage: post_comment <pr_number> <body>
post_comment() {
  local pr_number="$1"
  local body="$2"
  gh_auth_switch "$(gh_active_account)"
  gh issue comment "${pr_number}" --repo "${BASE_REPO}" --body "${body}"
}

# Get workflow runs for a head branch and event.
# Usage: get_branch_runs <head_branch> <event>
get_branch_runs() {
  local head_branch="$1"
  local event="$2"
  gh_auth_switch "${BASE_OWNER}"
  gh run list --repo "${BASE_REPO}" --event "${event}" --branch "${head_branch}" --json databaseId,conclusion,status --jq '.[]'
}

# Get the latest completed workflow run id for a head branch and event.
# Usage: get_latest_run_id <head_branch> <event>
get_latest_run_id() {
  local head_branch="$1"
  local event="$2"
  gh_auth_switch "${BASE_OWNER}"
  # issue_comment runs are associated with the base branch, not the PR head branch.
  local branch="${head_branch}"
  if [ "${event}" = "issue_comment" ]; then
    branch="${TEST_BASE_BRANCH}"
  fi
  gh run list --repo "${BASE_REPO}" --event "${event}" --branch "${branch}" --json databaseId,status,conclusion --jq '.[] | select(.status == "completed" and .conclusion != null and .conclusion != "") | .databaseId' | head -1
}

# Get the latest workflow run id (regardless of conclusion) for a head branch and event.
# Usage: get_latest_run_id_any <head_branch> <event>
get_latest_run_id_any() {
  local head_branch="$1"
  local event="$2"
  gh_auth_switch "${BASE_OWNER}"
  local branch="${head_branch}"
  if [ "${event}" = "issue_comment" ]; then
    branch="${TEST_BASE_BRANCH}"
  fi
  gh run list --repo "${BASE_REPO}" --event "${event}" --branch "${branch}" --json databaseId --jq '.[0].databaseId' | head -1
}

# View workflow run logs.
# Usage: view_run_logs <run_id>
view_run_logs() {
  local run_id="$1"
  gh_auth_switch "${BASE_OWNER}"
  gh run view "${run_id}" --repo "${BASE_REPO}" --log
}

# Get the latest completed issue_comment workflow run matching a PR title.
# Usage: get_issue_comment_run_by_title <display_title>
get_issue_comment_run_by_title() {
  local display_title="$1"
  gh_auth_switch "${BASE_OWNER}"
  gh api "repos/${BASE_REPO}/actions/runs?event=issue_comment&branch=${TEST_BASE_BRANCH}&per_page=10" \
    --jq ".workflow_runs[] | select(.status == \"completed\" and .display_title == \"${display_title}\") | .id" 2>/dev/null | head -1
}

# Get any issue_comment workflow run matching a PR title.
# Usage: get_issue_comment_run_any_by_title <display_title>
get_issue_comment_run_any_by_title() {
  local display_title="$1"
  gh_auth_switch "${BASE_OWNER}"
  gh api "repos/${BASE_REPO}/actions/runs?event=issue_comment&branch=${TEST_BASE_BRANCH}&per_page=10" \
    --jq ".workflow_runs[] | select(.display_title == \"${display_title}\") | .id" 2>/dev/null | head -1
}

# Count PR comments and inline review comments containing a substring.
# Checks both comment bodies and inline comment paths (filenames).
# Usage: count_matching_comments <pr_number> <substring>
count_matching_comments() {
  local pr_number="$1"
  local substring="$2"
  gh_auth_switch "${BASE_OWNER}"
  local count=0
  # Issue comments on the PR
  count=$((count + $(gh pr view "${pr_number}" --repo "${BASE_REPO}" --json comments --jq '.comments[].body' 2>/dev/null | grep -c "${substring}" || true)))
  # Review comments (top-level review bodies)
  count=$((count + $(gh pr view "${pr_number}" --repo "${BASE_REPO}" --json reviews --jq '.reviews[].body' 2>/dev/null | grep -c "${substring}" || true)))
  # Inline review comments (body and path)
  count=$((count + $(gh api "repos/${BASE_REPO}/pulls/${pr_number}/comments" --jq '.[] | "\(.path) \(.body)"' 2>/dev/null | grep -c "${substring}" || true)))
  echo "${count}"
}

# Delete a branch in the base repo.
# Usage: delete_branch <branch>
delete_branch() {
  local branch="$1"
  gh_auth_switch "${BASE_OWNER}"
  gh api "repos/${BASE_REPO}/git/refs/heads/${branch}" --method DELETE || true
}
