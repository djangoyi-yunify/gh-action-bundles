## Context

GitHub pull requests are reviewed against their merge base: the most recent common ancestor of the PR head and the target branch. When a PR is created, its merge base is the commit where the branch diverged. If the target branch receives new commits before the PR is reviewed, the merge base does not change unless the PR is rebased. Therefore, the correct review diff is always:

```
merge-base(head, target-branch) → head
```

The current action uses `origin/<base-ref>` as the starting point. This is only correct if the target branch has not moved. Once it moves, the diff includes unrelated commits and omits or misrepresents the PR's own changes.

## Goals / Non-Goals

**Goals:**
- Compute the merge base for each PR before running OCR.
- Use the merge base SHA as the `--from` argument.
- Keep changes minimal and backward-compatible with existing inputs/outputs.

**Non-Goals:**
- Rebase PRs automatically.
- Change how comments are posted.
- Add new action inputs.

## Decisions

### 1. Use GitHub Compare API to get merge base
**Decision:** Compute the merge base via `gh api repos/{owner}/{repo}/compare/{base-ref}...{head-sha}` and read `.merge_base_commit.sha`.

**Rationale:**
- Does not require a full local clone to run `git merge-base`.
- Works reliably for both same-repo and fork PRs as long as head SHA is known.
- The Compare API is the canonical GitHub way to get the merge base.

**Alternative considered:** Run `git merge-base origin/<base-ref> <head-sha>` locally. Rejected because it requires the local repository to have both refs fetched, which is more fragile especially for fork PRs.

### 2. Add `merge-base` output to resolve-pr
**Decision:** `resolve-pr` outputs both `base-ref` (branch name) and `merge-base` (SHA). `run-review` uses `merge-base` for `--from`.

**Rationale:**
- Preserves `base-ref` for logging and potential future use.
- Makes the change explicit and easy to test.

## Risks / Trade-offs

- [Risk] Compare API could be rate-limited on very large repositories. → Mitigation: A single API call per review is acceptable for typical use.
- [Risk] If the PR is force-pushed, the merge base may change; the action uses the current head SHA at runtime, so it will compute the correct current merge base.
