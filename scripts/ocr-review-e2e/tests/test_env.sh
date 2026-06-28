#!/usr/bin/env bash
set -euo pipefail

# Extract the active account username from a gh auth status --active string.
# Only returns the username when the status contains "Active account: true".
extract_active_account() {
  awk '/Active account: true/ { active=1 }
       /account [^ ]+/ { match($0, /account [^ ]+/); user=substr($0, RSTART+7, RLENGTH-7); gsub(/^[ \t]+|[ \t]+$/, "", user) }
       END { if (active) print user }'
}

test_extract_active_account() {
  local output="github.com
  ✓ Logged in to github.com account test-user (/root/.config/gh/hosts.yml)
  - Active account: true
"
  local result
  result=$(echo "$output" | extract_active_account)
  if [ "${result}" != "test-user" ]; then
    echo "FAIL: expected 'test-user', got '${result}'" >&2
    return 1
  fi
  echo "PASS: extract_active_account extracts username"
}

test_extract_active_account_empty_when_inactive() {
  local output="github.com
  ✓ Logged in to github.com account test-user (/root/.config/gh/hosts.yml)
  - Active account: false
"
  local result
  result=$(echo "$output" | extract_active_account)
  if [ -n "${result}" ]; then
    echo "FAIL: expected empty result, got '${result}'" >&2
    return 1
  fi
  echo "PASS: extract_active_account returns empty when inactive"
}

echo "Running test_env.sh..."
test_extract_active_account
test_extract_active_account_empty_when_inactive
echo "test_env.sh complete"
