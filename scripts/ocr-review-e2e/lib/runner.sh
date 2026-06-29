#!/usr/bin/env bash
set -euo pipefail

# Shared scenario runner for multi-task E2E test scripts.
# Provides register_scenario, --list, --only, dependency sorting, and failure handling.
# See agent-rules/testing.md for the testing strategy this runner implements.

# Parallel arrays for registered scenarios.
RUNNER_IDS=()
RUNNER_GROUPS=()
RUNNER_DESCRIPTIONS=()
RUNNER_DEPENDENCIES=()  # comma-separated dependency strings
RUNNER_HANDLERS=()

# Default groups to run when no --only is provided (empty means all scenarios).
RUNNER_DEFAULT_GROUPS=()

# Execution flags.
RUNNER_ONLY_ITEMS=()
RUNNER_NO_CLEANUP=false
RUNNER_FAIL_FAST=false

# Failure tracking for full regression mode.
RUNNER_FAILED_SCENARIOS=()

# Register a scenario with the runner.
# Usage: register_scenario <id> <group> <description> <dependencies> <handler>
#   dependencies: comma-separated list; may include other scenario ids or infrastructure labels like "setup"
register_scenario() {
  if [ "$#" -lt 5 ]; then
    echo "Error: register_scenario requires 5 arguments: id group description dependencies handler" >&2
    return 1
  fi

  local id="$1"
  local group="$2"
  local description="$3"
  local dependencies="$4"
  local handler="$5"

  # Validate unique id.
  local existing
  existing=$(printf '%s\n' "${RUNNER_IDS[@]:-}" | grep -cx "${id}" || true)
  if [ "${existing}" -ne 0 ]; then
    echo "Error: scenario '${id}' is already registered" >&2
    return 1
  fi

  # Validate handler is a callable function.
  if ! declare -f "${handler}" >/dev/null 2>&1; then
    echo "Error: scenario handler '${handler}' is not defined for '${id}'" >&2
    return 1
  fi

  RUNNER_IDS+=("${id}")
  RUNNER_GROUPS+=("${group}")
  RUNNER_DESCRIPTIONS+=("${description}")
  RUNNER_DEPENDENCIES+=("${dependencies}")
  RUNNER_HANDLERS+=("${handler}")
}

# Set the groups that should run by default when no --only is provided.
# Usage: runner_set_default_groups <group> [<group> ...]
runner_set_default_groups() {
  RUNNER_DEFAULT_GROUPS=("$@")
}

# Find the index of a scenario by id.
# Usage: _runner_index_of <id>
_runner_index_of() {
  local id="$1"
  local i
  for i in "${!RUNNER_IDS[@]}"; do
    if [ "${RUNNER_IDS[$i]}" = "${id}" ]; then
      echo "${i}"
      return 0
    fi
  done
  return 1
}

# Topological sort of scenarios based on scenario-to-scenario dependencies.
# Prints scenario ids in execution order.
# Usage: _runner_sort_scenarios <selected_indices...>
_runner_sort_scenarios() {
  local selected=("$@")
  local n=${#RUNNER_IDS[@]}

  # Build in-degree map and adjacency list for selected scenarios.
  local -A in_degree
  local -A adjacency
  local -A selected_set
  local idx

  for idx in "${selected[@]}"; do
    selected_set["${idx}"]=1
    in_degree["${idx}"]=0
  done

  for idx in "${selected[@]}"; do
    local deps
    IFS=',' read -ra deps <<< "${RUNNER_DEPENDENCIES[$idx]}"
    local dep
    for dep in "${deps[@]}"; do
      dep=$(echo "${dep}" | xargs)  # trim whitespace
      [ -z "${dep}" ] && continue
      # Only treat dependency as a scenario id if it is registered.
      local dep_idx
      if dep_idx=$(_runner_index_of "${dep}" 2>/dev/null); then
        if [ -n "${selected_set[$dep_idx]:-}" ]; then
          in_degree["${idx}"]=$((in_degree["${idx}"] + 1))
          adjacency["${dep_idx}"]+=" ${idx}"
        fi
      fi
    done
  done

  # Kahn's algorithm.
  local queue=()
  local sorted=()

  for idx in "${selected[@]}"; do
    if [ "${in_degree[$idx]}" -eq 0 ]; then
      queue+=("${idx}")
    fi
  done

  while [ ${#queue[@]} -gt 0 ]; do
    local current="${queue[0]}"
    queue=("${queue[@]:1}")
    sorted+=("${current}")

    local neighbors="${adjacency[$current]:-}"
    local neighbor
    for neighbor in ${neighbors}; do
      in_degree["${neighbor}"]=$((in_degree["${neighbor}"] - 1))
      if [ "${in_degree[$neighbor]}" -eq 0 ]; then
        queue+=("${neighbor}")
      fi
    done
  done

  if [ ${#sorted[@]} -ne ${#selected[@]} ]; then
    echo "Error: cyclic dependency detected among selected scenarios" >&2
    return 1
  fi

  for idx in "${sorted[@]}"; do
    echo "${RUNNER_IDS[$idx]}"
  done
}

# List all registered scenarios in a readable table.
runner_list_scenarios() {
  printf '%-30s %-15s %-30s %s\n' "ID" "GROUP" "DEPENDENCIES" "DESCRIPTION"
  local i
  for i in "${!RUNNER_IDS[@]}"; do
    printf '%-30s %-15s %-30s %s\n' \
      "${RUNNER_IDS[$i]}" \
      "${RUNNER_GROUPS[$i]}" \
      "${RUNNER_DEPENDENCIES[$i]}" \
      "${RUNNER_DESCRIPTIONS[$i]}"
  done
}

# Print usage information.
runner_show_usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --list                  List all registered scenarios
  --only <id|group> ...   Run only the specified scenarios or groups
  --no-cleanup            Do not cleanup on failure (for debugging)
  --help                  Show this help message

If no --only is provided, runs scenarios in the default groups (or all if none are set).
EOF
}

# Parse command-line arguments and set runner flags.
runner_parse_args() {
  RUNNER_ONLY_ITEMS=()
  RUNNER_NO_CLEANUP=false

  while [ $# -gt 0 ]; do
    case "$1" in
      --list)
        runner_list_scenarios
        exit 0
        ;;
      --only)
        shift
        if [ $# -eq 0 ]; then
          echo "Error: --only requires an argument" >&2
          exit 1
        fi
        while [ $# -gt 0 ] && [[ "$1" != --* ]]; do
          RUNNER_ONLY_ITEMS+=("$1")
          shift
        done
        ;;
      --no-cleanup)
        RUNNER_NO_CLEANUP=true
        shift
        ;;
      --help)
        runner_show_usage
        exit 0
        ;;
      *)
        echo "Error: unknown option '$1'" >&2
        runner_show_usage
        exit 1
        ;;
    esac
  done
}

# Resolve which scenarios to run.
# Outputs indices of selected scenarios, one per line.
# Usage: _runner_resolve_selected
_runner_resolve_selected() {
  local only_count=${#RUNNER_ONLY_ITEMS[@]}
  local -A selected
  local i

  if [ "${only_count}" -eq 0 ]; then
    # No --only: use default groups if set, otherwise all scenarios.
    if [ ${#RUNNER_DEFAULT_GROUPS[@]} -gt 0 ]; then
      local -A default_group_set
      local g
      for g in "${RUNNER_DEFAULT_GROUPS[@]}"; do
        default_group_set["${g}"]=1
      done
      for i in "${!RUNNER_IDS[@]}"; do
        if [ -n "${default_group_set[${RUNNER_GROUPS[$i]}]:-}" ]; then
          selected["${i}"]=1
        fi
      done
    else
      for i in "${!RUNNER_IDS[@]}"; do
        selected["${i}"]=1
      done
    fi
  else
    # --only provided: resolve each item as scenario id or group.
    local item
    local -A item_set
    for item in "${RUNNER_ONLY_ITEMS[@]}"; do
      item_set["${item}"]=1
    done

    local matched=false
    for item in "${RUNNER_ONLY_ITEMS[@]}"; do
      local found=false
      for i in "${!RUNNER_IDS[@]}"; do
        if [ "${RUNNER_IDS[$i]}" = "${item}" ]; then
          selected["${i}"]=1
          found=true
          matched=true
        elif [ "${RUNNER_GROUPS[$i]}" = "${item}" ]; then
          selected["${i}"]=1
          found=true
          matched=true
        fi
      done
      if [ "${found}" = false ]; then
        echo "Error: unknown scenario or group '${item}'" >&2
        exit 1
      fi
    done
  fi

  for i in "${!selected[@]}"; do
    echo "${i}"
  done | sort -n
}

# Run a single scenario by index.
# Usage: _runner_run_scenario <index>
_runner_run_scenario() {
  local idx="$1"
  local id="${RUNNER_IDS[$idx]}"
  local handler="${RUNNER_HANDLERS[$idx]}"

  echo ""
  echo "=========================================="
  echo "Scenario: ${id}"
  echo "=========================================="

  if "${handler}"; then
    echo "✓ Scenario passed: ${id}"
    return 0
  else
    echo "✗ Scenario failed: ${id}" >&2
    return 1
  fi
}

# Main entry point for the runner.
# Scripts should call this after registering all scenarios.
# Usage: runner_main "$@"
runner_main() {
  runner_parse_args "$@"

  if [ ${#RUNNER_IDS[@]} -eq 0 ]; then
    echo "Error: no scenarios registered" >&2
    exit 1
  fi

  # Export cleanup flag so scenario handlers can check it.
  if [ "${RUNNER_NO_CLEANUP}" = true ]; then
    export RUNNER_NO_CLEANUP=true
  fi

  # Determine selected scenario indices.
  local selected_indices
  selected_indices=$(_runner_resolve_selected)
  if [ -z "${selected_indices}" ]; then
    echo "No scenarios selected to run"
    exit 0
  fi

  # Sort selected scenarios by dependencies.
  local sorted_ids
  sorted_ids=$(_runner_sort_scenarios ${selected_indices})

  RUNNER_FAILED_SCENARIOS=()
  local single_mode=false
  [ ${#RUNNER_ONLY_ITEMS[@]} -gt 0 ] && single_mode=true

  local id
  for id in ${sorted_ids}; do
    local idx
    idx=$(_runner_index_of "${id}")
    if _runner_run_scenario "${idx}"; then
      continue
    else
      RUNNER_FAILED_SCENARIOS+=("${id}")
      if [ "${single_mode}" = true ]; then
        exit 1
      fi
    fi
  done

  echo ""
  echo "=========================================="
  if [ ${#RUNNER_FAILED_SCENARIOS[@]} -eq 0 ]; then
    echo "All selected scenarios passed"
    echo "=========================================="
    exit 0
  else
    echo "Failed scenarios:"
    local failed
    for failed in "${RUNNER_FAILED_SCENARIOS[@]}"; do
      echo "  - ${failed}"
    done
    echo "=========================================="
    exit 1
  fi
}
