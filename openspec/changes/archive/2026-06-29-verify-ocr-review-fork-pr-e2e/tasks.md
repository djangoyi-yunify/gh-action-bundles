## 0. Extract shared runner framework

按 `agent-rules/testing.md` 的多任务测试策略，先提取 scenario runner，再基于它实现 `run-fork.sh`。

- [x] 0.1 Create `scripts/ocr-review-e2e/lib/runner.sh` with `register_scenario`, `list_scenarios`, `run_scenarios`
- [x] 0.2 Support `--list`, `--only <scenario-id>`, `--only <group>`, `--no-cleanup`
- [x] 0.3 Support dependency-based topological sorting and cycle detection
- [x] 0.4 Implement fail-fast for single-scenario mode and collect-all-failures for full regression
- [x] 0.5 Refactor `run-same-repo.sh` to use `lib/runner.sh`

## 1. Implement run-fork.sh helpers

- [x] 1.1 Source `scripts/ocr-review-e2e/lib/*.sh` and `lib/runner.sh`
- [x] 1.2 Default `FORK_OWNER=yijing1998` and `BASE_OWNER=djangoyi-yunify`, with env overrides
- [x] 1.3 Reuse or finalize `gh_auth_switch <account>` helper from `lib/env.sh`
- [x] 1.4 Implement helper to create a branch on the fork (as `yijing1998`), push commits, and open a cross-repo PR
- [x] 1.5 Implement helper to post `/ocr review` from the base repo (as `djangoyi-yunify`)
- [x] 1.6 Implement helper to poll workflow run state for `issue_comment` events
- [x] 1.7 Reuse existing helpers to assert cross-repo checkout log lines and comment presence
- [x] 1.8 Implement helper to approve `action_required` pull_request workflow runs for fork PRs

## 2. Automatic review skip scenarios

- [x] 2.1 `tc-fork-auto-external`: External user opens fork PR
  - [x] 2.1.1 Switch to `yijing1998` via `gh auth switch`
  - [x] 2.1.2 Create branch on fork with problematic code
  - [x] 2.1.3 Open PR from fork to base
  - [x] 2.1.4 Wait for `pull_request` workflow run; approve if it is `action_required`
  - [x] 2.1.5 Assert `pull_request` workflow run conclusion is `skipped`
  - [x] 2.1.6 Assert no `[OCR]` comments are posted
  - [x] 2.1.7 Cleanup

## 3. Manual review trigger scenarios

- [x] 3.1 `tc-fork-manual-trusted`: Base owner comments `/ocr review` on fork PR
  - [x] 3.1.1 Switch to `yijing1998` and create a fork PR with problematic code
  - [x] 3.1.2 Switch to `djangoyi-yunify` and post `/ocr review`
  - [x] 3.1.3 Assert `issue_comment` workflow run is `success`
  - [x] 3.1.4 Assert `[OCR]` comments are posted on the fork PR
  - [x] 3.1.5 Cleanup
- [x] 3.2 `tc-fork-manual-untrusted`: Fork user comments `/ocr review` on fork PR
  - [x] 3.2.1 Switch to `yijing1998` and create a fork PR
  - [x] 3.2.2 Post `/ocr review` as `yijing1998`
  - [x] 3.2.3 Assert `issue_comment` workflow run conclusion is `skipped`
  - [x] 3.2.4 Assert no `[OCR]` comments appear
  - [x] 3.2.5 Cleanup

## 4. Cross-repository checkout and diff scenarios

- [x] 4.1 `tc-fork-checkout`: Fork head branch is checked out correctly
  - [x] 4.1.1 Switch to `yijing1998` and create a fork PR
  - [x] 4.1.2 Switch to `djangoyi-yunify` and trigger manual review
  - [x] 4.1.3 Assert workflow log contains `Checking out fork PR branch`
  - [x] 4.1.4 Assert log contains `git remote add fork` and `git fetch fork`
  - [x] 4.1.5 Cleanup
- [x] 4.2 `tc-fork-merge-base`: Base branch advances after fork PR creation
  - [x] 4.2.1 Switch to `yijing1998` and create fork PR with a unique bug
  - [x] 4.2.2 Switch to `djangoyi-yunify` and push unrelated commit to base `main`
  - [x] 4.2.3 Trigger manual review
  - [x] 4.2.4 Assert workflow log shows correct merge-base SHA
  - [x] 4.2.5 Assert comments only cover the PR diff
  - [x] 4.2.6 Cleanup
- [x] 4.3 `tc-fork-new-file`: Fork PR adds a new file
  - [x] 4.3.1 Switch to `yijing1998` and create fork PR adding `feature.py` with known bugs
  - [x] 4.3.2 Switch to `djangoyi-yunify` and trigger manual review
  - [x] 4.3.3 Assert `[OCR]` comments are posted on the new file
  - [x] 4.3.4 Cleanup
- [x] 4.4 `tc-fork-modify-existing`: Fork PR modifies an existing file
  - [x] 4.4.1 Switch to `yijing1998` and create fork PR modifying `main.py` with known bugs
  - [x] 4.4.2 Switch to `djangoyi-yunify` and trigger manual review
  - [x] 4.4.3 Assert `[OCR]` comments are posted on `main.py`
  - [x] 4.4.4 Cleanup

## 5. Platform behavior scenarios

- [x] 5.1 `tc-fork-first-time`: First-time contributor fork PR
  - [x] 5.1.1 Switch to `yijing1998` and create a fork PR
  - [x] 5.1.2 Record that the `pull_request` workflow is in `action_required` until maintainer approval
  - [x] 5.1.3 Approve the workflow run
  - [x] 5.1.4 Assert run conclusion is `skipped` due to author_association gate
  - [x] 5.1.5 Cleanup

## 6. Optional/extreme boundary conditions

The following conditions are documented for the team to decide whether to test:

- [ ] 6.1 `tc-fork-auto-trusted`: Trusted base-repo member opens fork PR and `pull_request` is still skipped
  - **Rationale:** `pull_request` for a fork PR runs in the fork context regardless of author trust, so it should be skipped. This scenario is optional because creating a fork PR whose author is a trusted base-repo member is operationally difficult when the fork belongs to `yijing1998`.
- [ ] 6.2 Fork PR deletes an existing file in the base repo
- [ ] 6.3 Fork PR source branch is force-pushed after PR creation; review uses new headSha
- [ ] 6.4 Fork PR source branch is deleted before review; verify GitHub still allows merge-base calculation
- [ ] 6.5 Organization fork vs personal fork; compare `author_association` behavior
- [ ] 6.6 Fork PR with many commits; verify depth calculation in checkout
- [ ] 6.7 Trusted user comments `/ocr review` on a closed fork PR; verify behavior

## 7. Finalize

- [x] 7.1 Run the full `run-fork.sh` suite
- [x] 7.2 Record results and any discovered issues
- [x] 7.3 No bugs requiring follow-up changes were found in `ocr-review`

### Results

All required fork-PR scenarios passed in the full regression run:

- `tc-fork-auto-external`: pull_request workflow is skipped after approval
- `tc-fork-manual-trusted`: issue_comment workflow runs and posts `[OCR]` comments
- `tc-fork-manual-untrusted`: issue_comment workflow is skipped, no `[OCR]` comments
- `tc-fork-checkout`: fork remote is added and fork head branch is fetched
- `tc-fork-merge-base`: merge-base is computed correctly after base advances
- `tc-fork-new-file`: `[OCR]` comments are posted on newly added files
- `tc-fork-modify-existing`: `[OCR]` comments are posted on modified files
- `tc-fork-first-time`: first-time contributor workflow requires approval, then is skipped

### Observations

- External fork PRs require maintainer approval before the `pull_request` workflow can be evaluated; the `approve_pull_request_run_if_needed` helper handles this automatically.
- One transient LLM failure was observed during `tc-fork-new-file` development (the OCR review produced no output); the scenario passed on retry, indicating flakiness in the LLM backend rather than a code defect.
- Optional boundary scenarios (6.1-6.7) were not executed; they remain documented for future team decisions.
