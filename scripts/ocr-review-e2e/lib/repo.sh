#!/usr/bin/env bash
set -euo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./env.sh
source "${LIB_DIR}/env.sh"

# Directory where the test repo is cloned locally.
: "${TEST_WORKDIR:=/tmp/ocr-review-e2e}"

# Configure git identity for the test repo.
configure_git_identity() {
  git -C "${TEST_WORKDIR}" config user.email "ocr-review-e2e@example.com" || true
  git -C "${TEST_WORKDIR}" config user.name "OCR Review E2E Bot" || true
}

# Clone or refresh the base test repo.
prepare_local_clone() {
  gh_auth_switch "${BASE_OWNER}"
  if [ -d "${TEST_WORKDIR}/.git" ]; then
    echo "Using existing clone at ${TEST_WORKDIR}"
    git -C "${TEST_WORKDIR}" fetch origin
  else
    echo "Cloning ${BASE_REPO} into ${TEST_WORKDIR}..."
    rm -rf "${TEST_WORKDIR}"
    gh repo clone "${BASE_REPO}" "${TEST_WORKDIR}"
  fi
  configure_git_identity
}

# Reset the base branch to a known clean commit.
# If no target commit is provided, use the current origin/main.
reset_base_branch() {
  local target_commit="${1:-origin/${TEST_BASE_BRANCH}}"
  gh_auth_switch "${BASE_OWNER}"
  git -C "${TEST_WORKDIR}" checkout "${TEST_BASE_BRANCH}" || git -C "${TEST_WORKDIR}" checkout -b "${TEST_BASE_BRANCH}" origin/${TEST_BASE_BRANCH}
  git -C "${TEST_WORKDIR}" reset --hard "${target_commit}"
  git -C "${TEST_WORKDIR}" push origin "${TEST_BASE_BRANCH}" --force-with-lease || true
}

# Commit the workflow file from examples/ocr-review.yml to the base branch.
deploy_workflow() {
  local source_file="${1:-examples/ocr-review.yml}"
  if [ ! -f "${source_file}" ]; then
    echo "Error: workflow source file not found: ${source_file}" >&2
    exit 1
  fi
  gh_auth_switch "${BASE_OWNER}"
  git -C "${TEST_WORKDIR}" checkout "${TEST_BASE_BRANCH}"
  git -C "${TEST_WORKDIR}" pull origin "${TEST_BASE_BRANCH}"
  mkdir -p "${TEST_WORKDIR}/.github/workflows"
  # Replace placeholder owner with the actual action repo owner.
  # Remove concurrency config to avoid test runs cancelling each other.
  sed -e "s|your-org/gh-action-bundles|${BASE_OWNER}/gh-action-bundles|g" \
      -e '/^concurrency:/,/^  cancel-in-progress: true$/d' \
      "${source_file}" > "${TEST_WORKDIR}/${WORKFLOW_FILE}"
  git -C "${TEST_WORKDIR}" add "${WORKFLOW_FILE}"
  if git -C "${TEST_WORKDIR}" diff --cached --quiet; then
    echo "Workflow file is already up to date"
  else
    git -C "${TEST_WORKDIR}" commit -m "chore: deploy ocr-review workflow for e2e tests"
    git -C "${TEST_WORKDIR}" push origin "${TEST_BASE_BRANCH}"
  fi
}

# Commit the base main.py file.
deploy_base_code() {
  gh_auth_switch "${BASE_OWNER}"
  cat > "${TEST_WORKDIR}/main.py" <<'PY'
def greet(name: str) -> str:
    return f"Hello, {name}!"


if __name__ == "__main__":
    print(greet("world"))
PY
  git -C "${TEST_WORKDIR}" add main.py
  if git -C "${TEST_WORKDIR}" diff --cached --quiet; then
    echo "Base code is already up to date"
  else
    git -C "${TEST_WORKDIR}" commit -m "chore: add clean base code for e2e tests"
    git -C "${TEST_WORKDIR}" push origin "${TEST_BASE_BRANCH}"
  fi
}

# Create a test branch from the current base branch and push it.
# Usage: create_test_branch <branch-name>
create_test_branch() {
  local branch="$1"
  gh_auth_switch "${BASE_OWNER}"
  git -C "${TEST_WORKDIR}" checkout "${TEST_BASE_BRANCH}"
  git -C "${TEST_WORKDIR}" pull origin "${TEST_BASE_BRANCH}"
  git -C "${TEST_WORKDIR}" checkout -b "${branch}"
}

# Push the current test branch to origin.
# Usage: push_test_branch <branch-name>
push_test_branch() {
  local branch="$1"
  gh_auth_switch "${BASE_OWNER}"
  git -C "${TEST_WORKDIR}" push origin "${branch}"
}

# Write problematic code to main.py for testing.
write_main_py_with_bugs() {
  cat > "${TEST_WORKDIR}/main.py" <<'PY'
def process(user_input):
    password = "hardcoded_secret_123"
    result = eval(user_input)
    os.system("echo " + user_input)
    return result, password
PY
}

# Write a new file with problematic code.
# Usage: write_new_buggy_file <filename>
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

# Commit changes in the test repo with a message.
# Usage: commit_changes <message>
commit_changes() {
  local message="$1"
  git -C "${TEST_WORKDIR}" add -A
  git -C "${TEST_WORKDIR}" commit -m "${message}"
}

# Ensure the fork remote is configured in the local clone.
# Usage: prepare_fork_remote
prepare_fork_remote() {
  gh_auth_switch "${BASE_OWNER}"
  git -C "${TEST_WORKDIR}" checkout "${TEST_BASE_BRANCH}"
  git -C "${TEST_WORKDIR}" pull origin "${TEST_BASE_BRANCH}"
  if ! git -C "${TEST_WORKDIR}" remote get-url fork >/dev/null 2>&1; then
    echo "Adding fork remote: ${FORK_REPO}"
    git -C "${TEST_WORKDIR}" remote add fork "https://github.com/${FORK_REPO}.git"
  fi
  git -C "${TEST_WORKDIR}" fetch fork
}

# Create a branch in the local clone that will be pushed to the fork.
# Usage: create_fork_branch <branch-name>
create_fork_branch() {
  local branch="$1"
  gh_auth_switch "${FORK_OWNER}"
  git -C "${TEST_WORKDIR}" checkout "${TEST_BASE_BRANCH}"
  git -C "${TEST_WORKDIR}" pull origin "${TEST_BASE_BRANCH}"
  git -C "${TEST_WORKDIR}" checkout -b "${branch}"
}

# Push the current branch to the fork remote.
# Usage: push_fork_branch <branch-name>
push_fork_branch() {
  local branch="$1"
  gh_auth_switch "${FORK_OWNER}"
  git -C "${TEST_WORKDIR}" push fork "${branch}"
}

# Copy an extra file into the test repo, commit, and push it to the base branch.
# Useful for deploying custom OCR rule files or other test fixtures.
# Usage: deploy_test_fixture <source_file> <dest_path_in_repo> <commit_message>
deploy_test_fixture() {
  local source_file="$1"
  local dest_path="$2"
  local message="$3"
  if [ ! -f "${source_file}" ]; then
    echo "Error: fixture source file not found: ${source_file}" >&2
    exit 1
  fi
  gh_auth_switch "${BASE_OWNER}"
  git -C "${TEST_WORKDIR}" checkout "${TEST_BASE_BRANCH}"
  git -C "${TEST_WORKDIR}" pull origin "${TEST_BASE_BRANCH}"
  mkdir -p "${TEST_WORKDIR}/$(dirname "${dest_path}")"
  cp "${source_file}" "${TEST_WORKDIR}/${dest_path}"
  git -C "${TEST_WORKDIR}" add "${dest_path}"
  if git -C "${TEST_WORKDIR}" diff --cached --quiet; then
    echo "Fixture ${dest_path} is already up to date"
  else
    git -C "${TEST_WORKDIR}" commit -m "${message}"
    git -C "${TEST_WORKDIR}" push origin "${TEST_BASE_BRANCH}"
  fi
}
