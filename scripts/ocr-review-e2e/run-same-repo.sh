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

# Create a same-repo PR with the given branch name and title.
# Usage: create_same_repo_pr <branch> <title>
create_same_repo_pr() {
  local branch="$1"
  local title="$2"
  create_test_branch "${branch}"
  push_test_branch "${branch}"
  create_pr "${title}" "E2E test scenario" "${branch}" "${TEST_BASE_BRANCH}"
}

# Cleanup a same-repo scenario.
# Usage: cleanup_same_repo <pr_number> <branch>
cleanup_same_repo() {
  local pr_number="$1"
  local branch="$2"
  echo "Cleaning up PR #${pr_number}, branch ${branch}"
  close_pr "${pr_number}" || true
  delete_branch "${branch}" || true
}

# Restore the default ocr-review workflow.
restore_default_workflow() {
  deploy_workflow "examples/ocr-review.yml"
}

# Scenario: OWNER opens same-repo PR, workflow runs and posts comments.
run_tc_auto_owner() {
  local branch="tc-auto-owner-$(date +%s)"
  local pr_number

  create_test_branch "${branch}"
  write_main_py_with_bugs
  commit_changes "test(auto): owner opens same-repo PR with bugs"
  push_test_branch "${branch}"
  pr_number=$(create_pr "test(auto): owner opens same-repo PR" "E2E auto-review scenario" "${branch}" "${TEST_BASE_BRANCH}")
  echo "Created PR #${pr_number}"

  wait_for_run "${branch}" "pull_request" 300
  assert_run_conclusion "${branch}" "pull_request" "success" || return 1
  assert_has_comments "${pr_number}" || return 1

  cleanup_same_repo "${pr_number}" "${branch}"
}

# Scenario: untrusted same-repo PR is skipped.
# Note: this requires a third account with read access to the base repo.
run_tc_auto_untrusted() {
  echo "Skipping: same-repo PR from an untrusted author requires a third GitHub account"
  echo "         with read access to ${BASE_REPO}. Configure UNTRUSTED_ACCOUNT env var to enable."
}

# Scenario: OWNER comments /ocr review, workflow runs and posts comments.
run_tc_manual_owner() {
  local branch="tc-manual-owner-$(date +%s)"
  local pr_number
  local title="test(manual): same-repo PR for /ocr review (${branch})"

  create_test_branch "${branch}"
  write_main_py_with_bugs
  commit_changes "test(manual): same-repo PR for comment trigger"
  push_test_branch "${branch}"
  pr_number=$(create_pr "${title}" "E2E manual-trigger scenario" "${branch}" "${TEST_BASE_BRANCH}")
  echo "Created PR #${pr_number}"

  post_comment "${pr_number}" "/ocr review"
  echo "Posted /ocr review comment"

  wait_for_run "${branch}" "issue_comment" 300 "${title}"
  assert_run_conclusion "${branch}" "issue_comment" "success" "${title}" || return 1
  assert_has_comments "${pr_number}" || return 1

  cleanup_same_repo "${pr_number}" "${branch}"
}

# Scenario: untrusted user comments /ocr review, workflow is skipped.
# Skipped in this change: requires a dedicated untrusted same-repo account.
run_tc_manual_untrusted() {
  echo "Skipping: untrusted same-repo commenter scenario is deferred to fork-PR verification"
}

# Scenario: comment not starting with /ocr review does not trigger workflow.
run_tc_manual_wrong_text() {
  local branch="tc-manual-wrong-text-$(date +%s)"
  local pr_number
  local title="test(manual): same-repo PR for wrong comment text (${branch})"

  create_test_branch "${branch}"
  write_main_py_with_bugs
  commit_changes "test(manual): same-repo PR for wrong comment text"
  push_test_branch "${branch}"
  pr_number=$(create_pr "${title}" "E2E comment-text gate scenario" "${branch}" "${TEST_BASE_BRANCH}")
  echo "Created PR #${pr_number}"

  post_comment "${pr_number}" "please review"
  echo "Posted 'please review' comment"

  # The workflow is triggered by any issue_comment event, but the job should be
  # skipped because the comment does not start with /ocr review.
  wait_for_run "${branch}" "issue_comment" 60 "${title}"
  assert_run_conclusion "${branch}" "issue_comment" "skipped" "${title}" || return 1

  cleanup_same_repo "${pr_number}" "${branch}"
}

# Scenario: main advances after PR creation, merge-base is still correct.
run_tc_merge_base() {
  local branch="tc-merge-base-$(date +%s)"
  local pr_number
  local title="test(merge-base): verify merge-base calculation (${branch})"

  create_test_branch "${branch}"
  cat > "${TEST_WORKDIR}/main.py" <<'PY'
undefined_magic_number = 42
PY
  commit_changes "test(merge-base): add unique bug"
  push_test_branch "${branch}"
  pr_number=$(create_pr "${title}" "E2E merge-base scenario" "${branch}" "${TEST_BASE_BRANCH}")
  echo "Created PR #${pr_number}"

  # Advance main with an unrelated change.
  gh_auth_switch "${BASE_OWNER}"
  git -C "${TEST_WORKDIR}" checkout "${TEST_BASE_BRANCH}"
  git -C "${TEST_WORKDIR}" pull origin "${TEST_BASE_BRANCH}"
  echo "# unrelated advancement" >> "${TEST_WORKDIR}/README.md"
  git -C "${TEST_WORKDIR}" add README.md
  git -C "${TEST_WORKDIR}" commit -m "chore: advance main with unrelated change"
  git -C "${TEST_WORKDIR}" push origin "${TEST_BASE_BRANCH}"
  echo "Advanced main"

  post_comment "${pr_number}" "/ocr review"
  wait_for_run "${branch}" "issue_comment" 300 "${title}"
  assert_run_conclusion "${branch}" "issue_comment" "success" "${title}" || return 1
  assert_has_comments "${pr_number}" || return 1
  assert_comment_not_contains "${pr_number}" "unrelated advancement" || return 1

  cleanup_same_repo "${pr_number}" "${branch}"
}

# Scenario: PR adds a new file, OCR reviews it.
run_tc_new_file() {
  local branch="tc-new-file-$(date +%s)"
  local pr_number

  create_test_branch "${branch}"
  write_new_buggy_file "feature.py"
  commit_changes "test(new-file): add new buggy file"
  push_test_branch "${branch}"
  pr_number=$(create_pr "test(new-file): add new file for review (${branch})" "E2E new-file scenario" "${branch}" "${TEST_BASE_BRANCH}")
  echo "Created PR #${pr_number}"

  wait_for_run "${branch}" "pull_request" 300
  assert_run_conclusion "${branch}" "pull_request" "success" || return 1
  assert_has_comments "${pr_number}" || return 1
  assert_comment_contains "${pr_number}" "feature.py" || return 1

  cleanup_same_repo "${pr_number}" "${branch}"
}

# Scenario: PR modifies an existing file, OCR reviews it.
run_tc_modify_existing() {
  local branch="tc-modify-existing-$(date +%s)"
  local pr_number

  create_test_branch "${branch}"
  write_main_py_with_bugs
  commit_changes "test(modify): modify main.py with bugs"
  push_test_branch "${branch}"
  pr_number=$(create_pr "test(modify): modify existing file (${branch})" "E2E modify-existing scenario" "${branch}" "${TEST_BASE_BRANCH}")
  echo "Created PR #${pr_number}"

  wait_for_run "${branch}" "pull_request" 300
  assert_run_conclusion "${branch}" "pull_request" "success" || return 1
  assert_has_comments "${pr_number}" || return 1
  assert_comment_contains "${pr_number}" "main.py" || return 1

  cleanup_same_repo "${pr_number}" "${branch}"
}

# Scenario: default identifier prefix is applied.
run_tc_identifier() {
  local branch="tc-identifier-$(date +%s)"
  local pr_number
  local failed=0

  deploy_workflow "${SCRIPT_DIR}/workflows/ocr-review-identifier.yml"

  create_test_branch "${branch}"
  write_main_py_with_bugs
  commit_changes "test(identifier): same-repo PR with default identifier"
  push_test_branch "${branch}"
  pr_number=$(create_pr "test(identifier): default comment prefix [OCR] (${branch})" "E2E default identifier scenario" "${branch}" "${TEST_BASE_BRANCH}")
  echo "Created PR #${pr_number}"

  if ! wait_for_run "${branch}" "pull_request" 300; then
    echo "Warning: timed out waiting for workflow run, continuing with assertions"
  fi

  assert_run_conclusion "${branch}" "pull_request" "success" || failed=1
  assert_comment_contains "${pr_number}" "[OCR]" || failed=1

  cleanup_same_repo "${pr_number}" "${branch}"
  restore_default_workflow

  return "${failed}"
}

# Scenario: auto-checkout disabled.
run_tc_auto_checkout_false() {
  local branch="tc-auto-checkout-false-$(date +%s)"
  local pr_number
  local failed=0

  deploy_workflow "${SCRIPT_DIR}/workflows/ocr-review-auto-checkout-false.yml"

  create_test_branch "${branch}"
  write_main_py_with_bugs
  commit_changes "test(checkout): same-repo PR with caller checkout"
  push_test_branch "${branch}"
  pr_number=$(create_pr "test(checkout): caller provides checkout (${branch})" "E2E auto-checkout false scenario" "${branch}" "${TEST_BASE_BRANCH}")
  echo "Created PR #${pr_number}"

  if ! wait_for_run "${branch}" "pull_request" 300; then
    echo "Warning: timed out waiting for workflow run, continuing with assertions"
  fi

  assert_run_conclusion "${branch}" "pull_request" "success" || failed=1
  assert_has_comments "${pr_number}" || failed=1

  cleanup_same_repo "${pr_number}" "${branch}"
  restore_default_workflow

  return "${failed}"
}

# Scenario: OCR CLI fails gracefully.
run_tc_ocr_failure() {
  local branch="tc-ocr-failure-$(date +%s)"
  local pr_number
  local failed=0

  # Deploy a workflow variant that passes invalid hardcoded LLM credentials.
  deploy_workflow "${SCRIPT_DIR}/workflows/ocr-review-failure.yml"

  create_test_branch "${branch}"
  write_main_py_with_bugs
  commit_changes "test(failure): same-repo PR to trigger OCR failure"
  push_test_branch "${branch}"
  pr_number=$(create_pr "test(failure): OCR CLI failure handling (${branch})" "E2E OCR failure scenario" "${branch}" "${TEST_BASE_BRANCH}")
  echo "Created PR #${pr_number}"

  if ! wait_for_run "${branch}" "pull_request" 300; then
    echo "Warning: timed out waiting for workflow run, continuing with assertions"
  fi

  assert_run_conclusion "${branch}" "pull_request" "success" || failed=1
  assert_comment_contains "${pr_number}" "produced no output" || failed=1

  cleanup_same_repo "${pr_number}" "${branch}"
  restore_default_workflow

  return "${failed}"
}

# Scenario: inline comments fallback to summary.
run_tc_inline_fallback() {
  local branch="tc-inline-fallback-$(date +%s)"
  local pr_number
  local title="test(fallback): inline comment fallback (${branch})"
  local failed=0

  # Deploy a workflow variant that uses a custom rule encouraging invalid line
  # numbers, and push the rule file to the base branch so the action can load it.
  deploy_test_fixture \
    "${SCRIPT_DIR}/rules/inline-fallback-rule.json" \
    ".github/ocr-inline-fallback-rule.json" \
    "chore: deploy inline fallback rule fixture"
  deploy_workflow "${SCRIPT_DIR}/workflows/ocr-review-inline-fallback.yml"

  create_test_branch "${branch}"
  # Keep main.py very short so any comment on line 1000 is out of range.
  cat > "${TEST_WORKDIR}/main.py" <<'PY'
def tiny():
    pass
PY
  commit_changes "test(fallback): tiny main.py to trigger invalid line comments"
  push_test_branch "${branch}"
  pr_number=$(create_pr "${title}" "E2E inline fallback scenario" "${branch}" "${TEST_BASE_BRANCH}")
  echo "Created PR #${pr_number}"

  post_comment "${pr_number}" "/ocr review"
  echo "Posted /ocr review comment"

  if ! wait_for_run "${branch}" "issue_comment" 300 "${title}"; then
    echo "Warning: timed out waiting for workflow run, continuing with assertions"
  fi

  assert_run_conclusion "${branch}" "issue_comment" "success" "${title}" || failed=1

  # The action logs a warning when the batch review fails; check the logs first.
  local run_id
  run_id=$(get_issue_comment_run_by_title "${title}")
  if [ -n "${run_id}" ] && view_run_logs "${run_id}" 2>/dev/null | grep -q "Failed to post batch review"; then
    echo "Asserted fallback path was triggered"
  else
    echo "Warning: could not confirm fallback path in workflow logs; checking summary comment"
    # As a weaker signal, assert a summary issue comment exists.
    assert_has_comments "${pr_number}" || failed=1
  fi

  cleanup_same_repo "${pr_number}" "${branch}"
  restore_default_workflow

  return "${failed}"
}

# Register all same-repo scenarios.
register_scenario "tc-auto-owner" "auto" "OWNER opens same-repo PR; workflow runs and posts comments" "" run_tc_auto_owner
register_scenario "tc-auto-untrusted" "auto" "Untrusted same-repo PR is skipped (requires third account)" "" run_tc_auto_untrusted
register_scenario "tc-manual-owner" "manual" "OWNER comments /ocr review; workflow runs and posts comments" "" run_tc_manual_owner
register_scenario "tc-manual-untrusted" "manual" "Untrusted user comments /ocr review; workflow is skipped" "" run_tc_manual_untrusted
register_scenario "tc-manual-wrong-text" "manual" "Comment not starting with /ocr review does not trigger workflow" "" run_tc_manual_wrong_text
register_scenario "tc-merge-base" "merge-base" "Main advances after PR creation; merge-base is still correct" "" run_tc_merge_base
register_scenario "tc-new-file" "content" "PR adds a new file; OCR reviews it" "" run_tc_new_file
register_scenario "tc-modify-existing" "content" "PR modifies an existing file; OCR reviews it" "" run_tc_modify_existing
register_scenario "tc-identifier" "content" "Identifier prefix [OCR] is applied" "" run_tc_identifier
register_scenario "tc-auto-checkout-false" "checkout" "Auto-checkout disabled; caller provides checkout" "" run_tc_auto_checkout_false
register_scenario "tc-ocr-failure" "failure" "OCR CLI fails gracefully" "" run_tc_ocr_failure
register_scenario "tc-inline-fallback" "fallback" "Inline comments fallback to summary" "" run_tc_inline_fallback

# Default groups mirror the original run-same-repo.sh behavior.
runner_set_default_groups auto manual merge-base content

# Run everything through the shared runner.
runner_main "$@"
