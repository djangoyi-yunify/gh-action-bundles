#!/usr/bin/env bash
set -euo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./env.sh
source "${LIB_DIR}/env.sh"

# shellcheck source=./github.sh
source "${LIB_DIR}/github.sh"

# Poll for a workflow run to complete for a head branch/event.
# Usage: wait_for_run <head_branch> <event> <timeout_seconds> [pr_title]
wait_for_run() {
  local head_branch="$1"
  local event="$2"
  local timeout="${3:-300}"
  local pr_title="${4:-}"
  local elapsed=0
  local sleep_interval=5
  echo "Waiting for ${event} workflow run on branch ${head_branch}..."
  while [ "${elapsed}" -lt "${timeout}" ]; do
    local run_id
    if [ "${event}" = "issue_comment" ] && [ -n "${pr_title}" ]; then
      run_id=$(get_issue_comment_run_by_title "${pr_title}")
    else
      run_id=$(get_latest_run_id "${head_branch}" "${event}")
    fi
    if [ -n "${run_id}" ]; then
      echo "Workflow run ${run_id} completed"
      return 0
    fi
    sleep "${sleep_interval}"
    elapsed=$((elapsed + sleep_interval))
    echo "  ...elapsed ${elapsed}s"
  done
  echo "Error: timed out after ${timeout}s waiting for ${event} workflow run on ${head_branch}" >&2
  return 1
}

# Poll for a workflow run to appear (regardless of completion) for a head branch/event.
# Usage: wait_for_run_start <head_branch> <event> <timeout_seconds> [pr_title]
wait_for_run_start() {
  local head_branch="$1"
  local event="$2"
  local timeout="${3:-60}"
  local pr_title="${4:-}"
  local elapsed=0
  local sleep_interval=5
  echo "Waiting for ${event} workflow run to start on branch ${head_branch}..."
  while [ "${elapsed}" -lt "${timeout}" ]; do
    local run_id
    if [ "${event}" = "issue_comment" ] && [ -n "${pr_title}" ]; then
      run_id=$(get_issue_comment_run_any_by_title "${pr_title}")
    else
      run_id=$(get_latest_run_id_any "${head_branch}" "${event}")
    fi
    if [ -n "${run_id}" ]; then
      echo "Workflow run ${run_id} started"
      return 0
    fi
    sleep "${sleep_interval}"
    elapsed=$((elapsed + sleep_interval))
  done
  echo "Error: timed out after ${timeout}s waiting for ${event} workflow run to start on ${head_branch}" >&2
  return 1
}

# Assert that the latest workflow run for a head branch/event has the expected conclusion.
# Usage: assert_run_conclusion <head_branch> <event> <expected> [pr_title]
assert_run_conclusion() {
  local head_branch="$1"
  local event="$2"
  local expected="$3"
  local pr_title="${4:-}"
  local run_id
  if [ "${event}" = "issue_comment" ] && [ -n "${pr_title}" ]; then
    run_id=$(get_issue_comment_run_by_title "${pr_title}")
  else
    run_id=$(get_latest_run_id "${head_branch}" "${event}")
  fi
  if [ -z "${run_id}" ]; then
    echo "Error: no completed ${event} workflow run found on ${head_branch}" >&2
    return 1
  fi
  local conclusion
  conclusion=$(gh run view "${run_id}" --repo "${BASE_REPO}" --json conclusion --jq '.conclusion')
  if [ "${conclusion}" != "${expected}" ]; then
    echo "Error: expected ${event} run conclusion '${expected}', got '${conclusion}'" >&2
    return 1
  fi
  echo "Asserted ${event} run conclusion: ${conclusion}"
}

# Assert that PR comments or review comments contain at least one occurrence of a substring.
# Usage: assert_comment_contains <pr_number> <substring>
assert_comment_contains() {
  local pr_number="$1"
  local substring="$2"
  local count
  count=$(count_matching_comments "${pr_number}" "${substring}")
  if [ "${count}" -eq 0 ]; then
    echo "Error: expected PR #${pr_number} comments to contain '${substring}'" >&2
    return 1
  fi
  echo "Asserted PR #${pr_number} has ${count} comment(s) containing '${substring}'"
}

# Assert that PR comments or review comments do not contain a substring.
# Usage: assert_comment_not_contains <pr_number> <substring>
assert_comment_not_contains() {
  local pr_number="$1"
  local substring="$2"
  local count
  count=$(count_matching_comments "${pr_number}" "${substring}")
  if [ "${count}" -gt 0 ]; then
    echo "Error: expected PR #${pr_number} comments NOT to contain '${substring}', found ${count}" >&2
    return 1
  fi
  echo "Asserted PR #${pr_number} has no comments containing '${substring}'"
}

# Assert that a PR has at least one comment or inline review comment.
# Usage: assert_has_comments <pr_number>
assert_has_comments() {
  local pr_number="$1"
  local count
  count=$(count_matching_comments "${pr_number}" "")
  if [ "${count}" -eq 0 ]; then
    echo "Error: expected PR #${pr_number} to have comments, found none" >&2
    return 1
  fi
  echo "Asserted PR #${pr_number} has ${count} comment(s)"
}

# Assert that a workflow run log contains a substring.
# Usage: assert_run_log_contains <run_id> <substring>
assert_run_log_contains() {
  local run_id="$1"
  local substring="$2"
  if ! view_run_logs "${run_id}" | grep -q "${substring}"; then
    echo "Error: run ${run_id} log does not contain '${substring}'" >&2
    return 1
  fi
  echo "Asserted run ${run_id} log contains '${substring}'"
}
