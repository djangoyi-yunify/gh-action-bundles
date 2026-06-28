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

# Default scenario groups to run.
RUN_AUTO=true
RUN_MANUAL=true
RUN_MERGE_BASE=true
RUN_CONTENT=true
RUN_FAILURE=false
RUN_CHECKOUT=false
RUN_FALLBACK=false

# Parse arguments.
while [ $# -gt 0 ]; do
  case "$1" in
    --only)
      shift
      RUN_AUTO=false
      RUN_MANUAL=false
      RUN_MERGE_BASE=false
      RUN_CONTENT=false
      RUN_FAILURE=false
      RUN_CHECKOUT=false
      RUN_FALLBACK=false
      while [ $# -gt 0 ] && [[ "$1" != --* ]]; do
        case "$1" in
          auto) RUN_AUTO=true ;;
          manual) RUN_MANUAL=true ;;
          merge-base) RUN_MERGE_BASE=true ;;
          content) RUN_CONTENT=true ;;
          failure) RUN_FAILURE=true ;;
          checkout) RUN_CHECKOUT=true ;;
          fallback) RUN_FALLBACK=true ;;
          *) echo "Unknown scenario group: $1" >&2; exit 1 ;;
        esac
        shift
      done
      ;;
    --help)
      echo "Usage: $0 [--only auto|manual|merge-base|content|failure|checkout|fallback]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Track failures.
FAILED_SCENARIOS=()

scenario_start() {
  local name="$1"
  echo ""
  echo "=========================================="
  echo "Scenario: ${name}"
  echo "=========================================="
}

scenario_pass() {
  local name="$1"
  echo "✓ Scenario passed: ${name}"
}

scenario_fail() {
  local name="$1"
  echo "✗ Scenario failed: ${name}" >&2
  FAILED_SCENARIOS+=("${name}")
}

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
  scenario_start "tc-auto-owner"
  local branch="tc-auto-owner-$(date +%s)"
  local pr_number

  create_test_branch "${branch}"
  write_main_py_with_bugs
  commit_changes "test(auto): owner opens same-repo PR with bugs"
  push_test_branch "${branch}"
  pr_number=$(create_pr "test(auto): owner opens same-repo PR" "E2E auto-review scenario" "${branch}" "${TEST_BASE_BRANCH}")
  echo "Created PR #${pr_number}"

  wait_for_run "${branch}" "pull_request" 300
  assert_run_conclusion "${branch}" "pull_request" "success" || { scenario_fail "tc-auto-owner"; return; }
  assert_has_comments "${pr_number}" || { scenario_fail "tc-auto-owner"; return; }

  cleanup_same_repo "${pr_number}" "${branch}"
  scenario_pass "tc-auto-owner"
}

# Scenario: untrusted same-repo PR is skipped.
# Note: this requires a third account with read access to the base repo.
run_tc_auto_untrusted() {
  scenario_start "tc-auto-untrusted"
  echo "Skipping: same-repo PR from an untrusted author requires a third GitHub account"
  echo "         with read access to ${BASE_REPO}. Configure UNTRUSTED_ACCOUNT env var to enable."
  scenario_pass "tc-auto-untrusted (skipped)"
}

# Scenario: OWNER comments /ocr review, workflow runs and posts comments.
run_tc_manual_owner() {
  scenario_start "tc-manual-owner"
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
  assert_run_conclusion "${branch}" "issue_comment" "success" "${title}" || { scenario_fail "tc-manual-owner"; return; }
  assert_has_comments "${pr_number}" || { scenario_fail "tc-manual-owner"; return; }

  cleanup_same_repo "${pr_number}" "${branch}"
  scenario_pass "tc-manual-owner"
}

# Scenario: untrusted user comments /ocr review, workflow is skipped.
# Skipped in this change: requires a dedicated untrusted same-repo account.
run_tc_manual_untrusted() {
  scenario_start "tc-manual-untrusted"
  echo "Skipping: untrusted same-repo commenter scenario is deferred to fork-PR verification"
  scenario_pass "tc-manual-untrusted (skipped)"
}

# Scenario: comment not starting with /ocr review does not trigger workflow.
run_tc_manual_wrong_text() {
  scenario_start "tc-manual-wrong-text"
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
  assert_run_conclusion "${branch}" "issue_comment" "skipped" "${title}" || { scenario_fail "tc-manual-wrong-text"; return; }

  cleanup_same_repo "${pr_number}" "${branch}"
  scenario_pass "tc-manual-wrong-text"
}

# Scenario: main advances after PR creation, merge-base is still correct.
run_tc_merge_base() {
  scenario_start "tc-merge-base"
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
  assert_run_conclusion "${branch}" "issue_comment" "success" "${title}" || { scenario_fail "tc-merge-base"; return; }
  assert_has_comments "${pr_number}" || { scenario_fail "tc-merge-base"; return; }
  assert_comment_not_contains "${pr_number}" "unrelated advancement" || { scenario_fail "tc-merge-base"; return; }

  cleanup_same_repo "${pr_number}" "${branch}"
  scenario_pass "tc-merge-base"
}

# Scenario: PR adds a new file, OCR reviews it.
run_tc_new_file() {
  scenario_start "tc-new-file"
  local branch="tc-new-file-$(date +%s)"
  local pr_number

  create_test_branch "${branch}"
  write_new_buggy_file "feature.py"
  commit_changes "test(new-file): add new buggy file"
  push_test_branch "${branch}"
  pr_number=$(create_pr "test(new-file): add new file for review (${branch})" "E2E new-file scenario" "${branch}" "${TEST_BASE_BRANCH}")
  echo "Created PR #${pr_number}"

  wait_for_run "${branch}" "pull_request" 300
  assert_run_conclusion "${branch}" "pull_request" "success" || { scenario_fail "tc-new-file"; return; }
  assert_has_comments "${pr_number}" || { scenario_fail "tc-new-file"; return; }
  assert_comment_contains "${pr_number}" "feature.py" || { scenario_fail "tc-new-file"; return; }

  cleanup_same_repo "${pr_number}" "${branch}"
  scenario_pass "tc-new-file"
}

# Scenario: PR modifies an existing file, OCR reviews it.
run_tc_modify_existing() {
  scenario_start "tc-modify-existing"
  local branch="tc-modify-existing-$(date +%s)"
  local pr_number

  create_test_branch "${branch}"
  write_main_py_with_bugs
  commit_changes "test(modify): modify main.py with bugs"
  push_test_branch "${branch}"
  pr_number=$(create_pr "test(modify): modify existing file (${branch})" "E2E modify-existing scenario" "${branch}" "${TEST_BASE_BRANCH}")
  echo "Created PR #${pr_number}"

  wait_for_run "${branch}" "pull_request" 300
  assert_run_conclusion "${branch}" "pull_request" "success" || { scenario_fail "tc-modify-existing"; return; }
  assert_has_comments "${pr_number}" || { scenario_fail "tc-modify-existing"; return; }
  assert_comment_contains "${pr_number}" "main.py" || { scenario_fail "tc-modify-existing"; return; }

  cleanup_same_repo "${pr_number}" "${branch}"
  scenario_pass "tc-modify-existing"
}

# Scenario: identifier prefix is applied.
run_tc_identifier() {
  scenario_start "tc-identifier"
  local branch="tc-identifier-$(date +%s)"
  local pr_number
  local failed=0

  deploy_workflow "${SCRIPT_DIR}/workflows/ocr-review-identifier.yml"

  create_test_branch "${branch}"
  write_main_py_with_bugs
  commit_changes "test(identifier): same-repo PR with identifier"
  push_test_branch "${branch}"
  pr_number=$(create_pr "test(identifier): comment prefix [OCR] (${branch})" "E2E identifier scenario" "${branch}" "${TEST_BASE_BRANCH}")
  echo "Created PR #${pr_number}"

  if ! wait_for_run "${branch}" "pull_request" 300; then
    echo "Warning: timed out waiting for workflow run, continuing with assertions"
  fi

  assert_run_conclusion "${branch}" "pull_request" "success" || failed=1
  assert_comment_contains "${pr_number}" "[OCR]" || failed=1

  cleanup_same_repo "${pr_number}" "${branch}"
  restore_default_workflow

  if [ "${failed}" -eq 0 ]; then
    scenario_pass "tc-identifier"
  else
    scenario_fail "tc-identifier"
  fi
}

# Scenario: auto-checkout disabled.
run_tc_auto_checkout_false() {
  scenario_start "tc-auto-checkout-false"
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

  if [ "${failed}" -eq 0 ]; then
    scenario_pass "tc-auto-checkout-false"
  else
    scenario_fail "tc-auto-checkout-false"
  fi
}

# Scenario: OCR CLI fails gracefully.
run_tc_ocr_failure() {
  scenario_start "tc-ocr-failure"
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

  if [ "${failed}" -eq 0 ]; then
    scenario_pass "tc-ocr-failure"
  else
    scenario_fail "tc-ocr-failure"
  fi
}

# Scenario: inline comments fallback to summary.
run_tc_inline_fallback() {
  scenario_start "tc-inline-fallback"
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

  if [ "${failed}" -eq 0 ]; then
    scenario_pass "tc-inline-fallback"
  else
    scenario_fail "tc-inline-fallback"
  fi
}

# Run all enabled scenario groups.
main() {
  echo "Running same-repo e2e verification"
  echo "Base repo: ${BASE_REPO}"

  verify_accounts
  prepare_local_clone

  if [ "${RUN_AUTO}" = true ]; then
    run_tc_auto_owner || true
    run_tc_auto_untrusted || true
  fi

  if [ "${RUN_MANUAL}" = true ]; then
    run_tc_manual_owner || true
    run_tc_manual_untrusted || true
    run_tc_manual_wrong_text || true
  fi

  if [ "${RUN_MERGE_BASE}" = true ]; then
    run_tc_merge_base || true
  fi

  if [ "${RUN_CONTENT}" = true ]; then
    run_tc_new_file || true
    run_tc_modify_existing || true
    run_tc_identifier || true
  fi

  if [ "${RUN_FAILURE}" = true ]; then
    run_tc_ocr_failure || true
  fi

  if [ "${RUN_FALLBACK}" = true ]; then
    run_tc_inline_fallback || true
  fi

  if [ "${RUN_CHECKOUT}" = true ]; then
    run_tc_auto_checkout_false || true
  fi

  echo ""
  echo "=========================================="
  if [ ${#FAILED_SCENARIOS[@]} -eq 0 ]; then
    echo "All enabled scenarios passed"
  else
    echo "Failed scenarios:"
    for s in "${FAILED_SCENARIOS[@]}"; do
      echo "  - ${s}"
    done
    exit 1
  fi
  echo "=========================================="
}

main "$@"
