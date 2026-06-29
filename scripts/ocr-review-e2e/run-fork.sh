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
# shellcheck source=./lib/runner.sh
source "${SCRIPT_DIR}/lib/runner.sh"

# Ensure the fork remote is available before any fork operations.
prepare_fork_remote

# Create a fork PR with problematic code. Prints progress to stderr and returns
# the created PR number on stdout.
# Usage: pr_number=$(create_fork_pr <branch> <title>)
create_fork_pr() {
  local branch="$1"
  local title="$2"

  echo "Creating fork branch ${branch}..." >&2
  create_fork_branch "${branch}" >&2
  write_main_py_with_bugs >&2
  commit_changes "test(fork): ${title}" >&2
  push_fork_branch "${branch}" >&2
  create_cross_repo_pr "${title}" "E2E fork-PR scenario" "${branch}" "${TEST_BASE_BRANCH}"
}

# Cleanup a fork PR scenario.
# Usage: cleanup_fork_pr <pr_number> <branch>
cleanup_fork_pr() {
  local pr_number="$1"
  local branch="$2"
  echo "Cleaning up PR #${pr_number}, fork branch ${branch}"
  close_pr "${pr_number}" || true
  gh_auth_switch "${FORK_OWNER}"
  git -C "${TEST_WORKDIR}" push fork --delete "${branch}" || true
}

# Trigger a manual review by posting /ocr review as the base owner.
# Usage: trigger_review <pr_number>
trigger_review() {
  local pr_number="$1"
  gh_auth_switch "${BASE_OWNER}"
  post_comment "${pr_number}" "/ocr review"
  echo "Posted /ocr review comment on PR #${pr_number}"
}

# Scenario: external user opens fork PR, automatic review is skipped.
run_tc_fork_auto_external() {
  local branch="tc-fork-auto-external-$(date +%s)"
  local pr_number

  pr_number=$(create_fork_pr "${branch}" "external user opens fork PR")
  echo "Created fork PR #${pr_number}"

  # External fork PRs often require maintainer approval before the run can proceed.
  wait_for_run_start "${branch}" "pull_request" 300
  approve_pull_request_run_if_needed "${branch}"

  wait_for_run "${branch}" "pull_request" 300
  assert_run_conclusion "${branch}" "pull_request" "skipped" || return 1
  assert_no_comments "${pr_number}" || return 1

  cleanup_fork_pr "${pr_number}" "${branch}"
}

# Scenario: base owner comments /ocr review on fork PR, review runs.
run_tc_fork_manual_trusted() {
  local branch="tc-fork-manual-trusted-$(date +%s)"
  local pr_number
  local title="test(fork): base owner comments /ocr review (${branch})"

  create_fork_branch "${branch}"
  write_main_py_with_bugs
  commit_changes "test(fork): same-repo PR for /ocr review"
  push_fork_branch "${branch}"
  pr_number=$(create_cross_repo_pr "${title}" "E2E fork manual-trigger scenario" "${branch}" "${TEST_BASE_BRANCH}")
  echo "Created fork PR #${pr_number}"

  trigger_review "${pr_number}"

  wait_for_run "${branch}" "issue_comment" 300 "${title}"
  assert_run_conclusion "${branch}" "issue_comment" "success" "${title}" || return 1
  assert_has_comments "${pr_number}" || return 1

  cleanup_fork_pr "${pr_number}" "${branch}"
}

# Scenario: fork user comments /ocr review, review is skipped.
run_tc_fork_manual_untrusted() {
  local branch="tc-fork-manual-untrusted-$(date +%s)"
  local pr_number
  local title="test(fork): fork user comments /ocr review (${branch})"

  create_fork_branch "${branch}"
  write_main_py_with_bugs
  commit_changes "test(fork): fork user comments /ocr review"
  push_fork_branch "${branch}"
  pr_number=$(create_cross_repo_pr "${title}" "E2E fork untrusted-comment scenario" "${branch}" "${TEST_BASE_BRANCH}")
  echo "Created fork PR #${pr_number}"

  gh_auth_switch "${FORK_OWNER}"
  post_comment "${pr_number}" "/ocr review"
  echo "Posted /ocr review comment as fork user on PR #${pr_number}"

  wait_for_run "${branch}" "issue_comment" 300 "${title}"
  assert_run_conclusion "${branch}" "issue_comment" "skipped" "${title}" || return 1
  assert_comment_not_contains "${pr_number}" "[OCR]" || return 1

  cleanup_fork_pr "${pr_number}" "${branch}"
}

# Scenario: fork head branch is checked out correctly.
run_tc_fork_checkout() {
  local branch="tc-fork-checkout-$(date +%s)"
  local pr_number
  local title="test(fork): fork head branch checkout (${branch})"

  create_fork_branch "${branch}"
  write_main_py_with_bugs
  commit_changes "test(fork): verify fork checkout"
  push_fork_branch "${branch}"
  pr_number=$(create_cross_repo_pr "${title}" "E2E fork checkout scenario" "${branch}" "${TEST_BASE_BRANCH}")
  echo "Created fork PR #${pr_number}"

  trigger_review "${pr_number}"

  wait_for_run "${branch}" "issue_comment" 300 "${title}"
  assert_run_conclusion "${branch}" "issue_comment" "success" "${title}" || return 1

  local run_id
  run_id=$(get_issue_comment_run_by_title "${title}")
  assert_run_log_contains "${run_id}" "Checking out fork PR branch" || return 1
  assert_run_log_contains "${run_id}" "git remote add fork" || return 1
  assert_run_log_contains "${run_id}" "git fetch fork" || return 1

  cleanup_fork_pr "${pr_number}" "${branch}"
}

# Scenario: base branch advances after fork PR creation, merge-base is correct.
run_tc_fork_merge_base() {
  local branch="tc-fork-merge-base-$(date +%s)"
  local pr_number
  local title="test(fork): merge-base across fork (${branch})"

  create_fork_branch "${branch}"
  cat > "${TEST_WORKDIR}/main.py" <<'PY'
undefined_magic_number = 42
PY
  commit_changes "test(fork): add unique bug for merge-base"
  push_fork_branch "${branch}"
  pr_number=$(create_cross_repo_pr "${title}" "E2E fork merge-base scenario" "${branch}" "${TEST_BASE_BRANCH}")
  echo "Created fork PR #${pr_number}"

  # Advance main with an unrelated change.
  gh_auth_switch "${BASE_OWNER}"
  git -C "${TEST_WORKDIR}" checkout "${TEST_BASE_BRANCH}"
  git -C "${TEST_WORKDIR}" pull origin "${TEST_BASE_BRANCH}"
  echo "# unrelated advancement" >> "${TEST_WORKDIR}/README.md"
  git -C "${TEST_WORKDIR}" add README.md
  git -C "${TEST_WORKDIR}" commit -m "chore: advance main with unrelated change"
  git -C "${TEST_WORKDIR}" push origin "${TEST_BASE_BRANCH}"
  echo "Advanced main"

  trigger_review "${pr_number}"

  wait_for_run "${branch}" "issue_comment" 300 "${title}"
  assert_run_conclusion "${branch}" "issue_comment" "success" "${title}" || return 1

  local run_id
  run_id=$(get_issue_comment_run_by_title "${title}")
  assert_run_log_contains "${run_id}" "merge-base:" || return 1

  assert_has_comments "${pr_number}" || return 1
  assert_comment_not_contains "${pr_number}" "unrelated advancement" || return 1

  cleanup_fork_pr "${pr_number}" "${branch}"
}

# Scenario: fork PR adds a new file, OCR reviews it.
run_tc_fork_new_file() {
  local branch="tc-fork-new-file-$(date +%s)"
  local pr_number
  local title="test(fork): new file in fork PR (${branch})"

  create_fork_branch "${branch}"
  write_new_buggy_file "feature.py"
  commit_changes "test(fork): add new buggy file"
  push_fork_branch "${branch}"
  pr_number=$(create_cross_repo_pr "${title}" "E2E fork new-file scenario" "${branch}" "${TEST_BASE_BRANCH}")
  echo "Created fork PR #${pr_number}"

  trigger_review "${pr_number}"

  wait_for_run "${branch}" "issue_comment" 300 "${title}"
  assert_run_conclusion "${branch}" "issue_comment" "success" "${title}" || return 1
  assert_has_comments "${pr_number}" || return 1
  assert_comment_contains "${pr_number}" "feature.py" || return 1

  cleanup_fork_pr "${pr_number}" "${branch}"
}

# Scenario: fork PR modifies an existing file, OCR reviews it.
run_tc_fork_modify_existing() {
  local branch="tc-fork-modify-existing-$(date +%s)"
  local pr_number
  local title="test(fork): modify existing file in fork PR (${branch})"

  create_fork_branch "${branch}"
  write_main_py_with_bugs
  commit_changes "test(fork): modify main.py with bugs"
  push_fork_branch "${branch}"
  pr_number=$(create_cross_repo_pr "${title}" "E2E fork modify-existing scenario" "${branch}" "${TEST_BASE_BRANCH}")
  echo "Created fork PR #${pr_number}"

  trigger_review "${pr_number}"

  wait_for_run "${branch}" "issue_comment" 300 "${title}"
  assert_run_conclusion "${branch}" "issue_comment" "success" "${title}" || return 1
  assert_has_comments "${pr_number}" || return 1
  assert_comment_contains "${pr_number}" "main.py" || return 1

  cleanup_fork_pr "${pr_number}" "${branch}"
}

# Scenario: first-time contributor fork PR requires approval and is then skipped.
run_tc_fork_first_time() {
  local branch="tc-fork-first-time-$(date +%s)"
  local pr_number

  pr_number=$(create_fork_pr "${branch}" "first-time contributor fork PR")
  echo "Created fork PR #${pr_number}"

  # Record the action_required state and approve the run before it can proceed.
  wait_for_run_start "${branch}" "pull_request" 300
  approve_pull_request_run_if_needed "${branch}"

  wait_for_run "${branch}" "pull_request" 300
  assert_run_conclusion "${branch}" "pull_request" "skipped" || return 1
  assert_no_comments "${pr_number}" || return 1

  cleanup_fork_pr "${pr_number}" "${branch}"
}

# Register all fork-PR scenarios.
register_scenario "tc-fork-auto-external" "auto" "External user opens fork PR; pull_request run is skipped" "" run_tc_fork_auto_external
register_scenario "tc-fork-manual-trusted" "manual" "Base owner comments /ocr review on fork PR; review runs" "" run_tc_fork_manual_trusted
register_scenario "tc-fork-manual-untrusted" "manual" "Fork user comments /ocr review; review is skipped" "" run_tc_fork_manual_untrusted
register_scenario "tc-fork-checkout" "checkout" "Fork head branch is checked out correctly" "" run_tc_fork_checkout
register_scenario "tc-fork-merge-base" "merge-base" "Merge-base calculation spans fork and base repos" "" run_tc_fork_merge_base
register_scenario "tc-fork-new-file" "content" "Fork PR adds a new file and OCR reviews it" "" run_tc_fork_new_file
register_scenario "tc-fork-modify-existing" "content" "Fork PR modifies an existing file and OCR reviews it" "" run_tc_fork_modify_existing
register_scenario "tc-fork-first-time" "platform" "First-time contributor fork PR approval and skip behavior" "" run_tc_fork_first_time

# Run all registered scenarios by default.
runner_main "$@"
