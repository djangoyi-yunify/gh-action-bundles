#!/usr/bin/env bash
set -euo pipefail

TEST_WORKDIR="$(mktemp -d)"
trap 'rm -rf "${TEST_WORKDIR}"' EXIT

write_main_py_with_bugs() {
  cat > "${TEST_WORKDIR}/main.py" <<'PY'
def process(user_input):
    password = "hardcoded_secret_123"
    result = eval(user_input)
    os.system("echo " + user_input)
    return result, password
PY
}

write_new_buggy_file() {
  local filename="$1"
  cat > "${TEST_WORKDIR}/${filename}" <<'PY'
def new_feature(user_input):
    admin_password = "admin123456"
    result = eval(user_input)
    os.system("rm -rf " + user_input)
    return result, admin_password
PY
}

test_write_main_py_with_bugs() {
  write_main_py_with_bugs
  if [ ! -f "${TEST_WORKDIR}/main.py" ]; then
    echo "FAIL: main.py was not created" >&2
    return 1
  fi
  for pattern in eval hardcoded_secret os.system; do
    if ! grep -q "${pattern}" "${TEST_WORKDIR}/main.py"; then
      echo "FAIL: main.py does not contain '${pattern}'" >&2
      return 1
    fi
  done
  echo "PASS: write_main_py_with_bugs"
}

test_write_new_buggy_file() {
  write_new_buggy_file "feature.py"
  if [ ! -f "${TEST_WORKDIR}/feature.py" ]; then
    echo "FAIL: feature.py was not created" >&2
    return 1
  fi
  for pattern in admin123456 eval os.system; do
    if ! grep -q "${pattern}" "${TEST_WORKDIR}/feature.py"; then
      echo "FAIL: feature.py does not contain '${pattern}'" >&2
      return 1
    fi
  done
  echo "PASS: write_new_buggy_file"
}

echo "Running test_repo.sh..."
test_write_main_py_with_bugs
test_write_new_buggy_file
echo "test_repo.sh complete"
