#!/usr/bin/env bash
set -euo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./env.sh
source "${LIB_DIR}/env.sh"

# Assert that a workflow run reached a given conclusion.
# Usage: assert_run_conclusion <pr_number> <event> <expected>
assert_run_conclusion() {
  local pr_number="$1"
  local event="$2"
  local expected="$3"
  gh_auth_switch "${BASE_OWNER}"
  local run_id
  run_id=$(gh run list --repo "${BASE_REPO}" --event "${event}" --branch "refs/pull/${pr_number}/merge" --json databaseId --jq '.[0].databaseId' 2>/dev/null || true)
  if [ -z "${run_id}" ]; then
    echo "Error: no ${event} workflow run found for PR #${pr_number}" >&2
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

# Placeholder: poll workflow run to completion.
# Usage: wait_for_run <pr_number> <event> <timeout_seconds>
wait_for_run() {
  local pr_number="$1"
  local event="$2"
  local timeout="${3:-300}"
  local elapsed=0
  echo "Waiting for ${event} workflow run for PR #${pr_number}..."
  while [ "${elapsed}" -lt "${timeout}" ]; do
    local run_id
    run_id=$(gh run list --repo "${BASE_REPO}" --event "${event}" --branch "refs/pull/${pr_number}/merge" --json databaseId,conclusion --jq '.[0] | select(.conclusion != null) | .databaseId' 2>/dev/null || true)
    if [ -n "${run_id}" ]; then
      echo "Workflow run ${run_id} completed"
      return 0
    fi
    sleep 5
    elapsed=$((elapsed + 5))
  done
  echo "Error: timed out waiting for ${event} workflow run" >&2
  return 1
}
