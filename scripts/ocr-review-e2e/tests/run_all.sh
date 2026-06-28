#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FAILED=0

run_test() {
  local script="$1"
  echo ""
  echo "Running ${script}..."
  if bash "${SCRIPT_DIR}/${script}"; then
    echo "  ${script}: PASSED"
  else
    echo "  ${script}: FAILED" >&2
    FAILED=$((FAILED + 1))
  fi
}

run_test "test_env.sh"
run_test "test_repo.sh"

echo ""
if [ "${FAILED}" -eq 0 ]; then
  echo "All unit tests passed"
else
  echo "${FAILED} test script(s) failed" >&2
  exit 1
fi
