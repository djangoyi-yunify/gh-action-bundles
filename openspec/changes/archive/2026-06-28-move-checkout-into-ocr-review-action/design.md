## Context

Currently `examples/ocr-review.yml` duplicates a common pattern:

1. `actions/checkout@v4` with `fetch-depth: 0`.
2. Conditional `gh pr checkout` for `issue_comment` triggers.

This is the same pattern shown in `Barmore-Genc/opencode-pr-reviewer`, but it still requires every consumer to understand when to checkout the PR head and how fork PRs differ from same-repo PRs. `anomalyco/opencode/github` hides this entirely: its action fetches PR metadata, compares `headRepository.nameWithOwner` to `baseRepository.nameWithOwner`, and checks out the correct branch internally.

We want to move the same capability into `actions/ocr-review` so the example workflow only needs event triggers, access controls, and the action call.

## Goals / Non-Goals

**Goals:**
- Move repository/PR checkout into the `ocr-review` composite action.
- Support both same-repo PRs and fork PRs without the caller writing conditional checkout logic.
- Follow the same fork-vs-local detection strategy used by `anomalyco/opencode/github`.
- Keep the action backward-compatible for callers that already manage checkout themselves.

**Non-Goals:**
- Change the security model (`pull_request` + `author_association` gate stays in the workflow).
- Change how OCR is invoked or how review comments are posted.
- Support `pull_request_target` as a first-class event.

## Decisions

### 1. Implement checkout as a dedicated `checkout` step
**Decision:** Add a new `checkout.ts` source file and corresponding `dist/checkout.js` step, placed after `configure` and before `resolve-pr` in `action.yml`.

**Rationale:**
- Keeps the action's step boundaries clear.
- Allows independent logging and error handling for checkout failures.
- Matches the existing modular step design (`install`, `configure`, `resolve-pr`, `run-review`, `post-review`).

### 2. Detect same-repo vs fork by comparing `headRepository` and `baseRepository`
**Decision:** Query `gh pr view` with `--json headRefName,headRepository,baseRepository,commits` and compare `headRepository.nameWithOwner === baseRepository.nameWithOwner`.

**Rationale:**
- This is exactly the detection logic used by `anomalyco/opencode/github/index.ts`.
- It is more explicit than relying on `gh pr checkout`'s internal behavior.
- It lets us control fetch depth and remote naming.

### 3. Fetch base branch plus head branch
**Decision:** First run `actions/checkout@v4` with `fetch-depth: 0`, then in `checkout.ts` fetch/checkout only the head branch. For fork PRs, add a `fork` remote and fetch from there.

**Rationale:**
- `fetch-depth: 0` guarantees the merge base and all base-branch history are present for OCR's `--from <merge-base>` argument.
- The explicit head-branch fetch/checkout then puts the working directory on the PR head, matching the behavior of `anomalyco/opencode`.

### 4. Add `auto-checkout` input defaulting to `true`
**Decision:** Add an optional boolean-ish string input `auto-checkout` with default `"true"`. When `"false"`, the action skips its own checkout steps.

**Rationale:**
- Existing callers who already do their own checkout can opt out without breaking.
- The example workflow will use the default `true`.
- `auto-checkout` is clearer than `checkout` for a boolean: it explicitly means "the action should automatically check out the repository".

### 5. Skip checkout for non-PR events
**Decision:** The `checkout` step checks `GITHUB_EVENT_NAME`. If it is not `pull_request` or `issue_comment`, the step does nothing.

**Rationale:**
- The action is currently only designed for PR review.
- Avoids accidental side effects if the action is ever invoked from another event.

### 6. Re-authenticate git after `actions/checkout` with `persist-credentials: false`
**Decision:** Run `gh auth setup-git --hostname github.com` at the start of `checkout.ts` so subsequent `git fetch`/`git checkout` operations can access private repositories.

**Rationale:**
- `actions/checkout` is intentionally configured with `persist-credentials: false` to avoid leaking credentials outside the action.
- `persist-credentials: false` also removes the git credential helper that `actions/checkout` would normally leave behind, so `git fetch origin` in a private repository fails without re-authentication.
- `gh auth setup-git` configures the local repository to use the GitHub CLI as a credential helper, authenticated via the `GH_TOKEN`/`GITHUB_TOKEN` already passed to the step.
- This supports both same-repo private PRs and private fork PRs without hard-coding tokens into remote URLs.

### 7. Create the local same-repo branch explicitly during fetch
**Decision:** For same-repo PRs, fetch with `git fetch origin <headRefName>:<headRefName>` and then `git checkout <headRefName>`.

**Rationale:**
- `git fetch origin <headRefName>` only updates `refs/remotes/origin/<headRefName>` and does not create a local branch.
- A bare `git checkout <headRefName>` relies on Git's DWIM behavior to auto-create a tracking branch, which is version-dependent and can fail in edge cases.
- Fetching with the `<refspec>:<refspec>` form creates or updates the local branch atomically, making the subsequent `git checkout` deterministic.

## Risks / Trade-offs

- [Risk] Duplicate checkout if a caller already checked out before calling the action. → Mitigation: `checkout` input defaults to `true`; callers can set `checkout: false`. Document this clearly.
- [Risk] `actions/checkout` inside a composite action uses the caller's `github.token` by default; if the caller restricted `contents: read`, it still works. → Mitigation: keep `permissions: contents: read` in the example.
- [Risk] Fork PR manual trigger via `issue_comment` needs `gh` authenticated to fetch from the fork. → Mitigation: pass `inputs.github-token` as `GH_TOKEN` to the checkout step, and rely on `actions/checkout` already having fetched the base repo.
- [Risk] Self-hosted runners without `gh` CLI. → Mitigation: the action already depends on `gh` for `resolve-pr` and posting comments, so this is not a new dependency.

## Migration Plan

1. Implement `checkout.ts`, update `action.yml`, and add the `checkout` input.
2. Update the example workflow to remove its checkout steps.
3. Update `README.md` usage example and input table.
4. Build `dist/` and run lint.
5. Verify with a same-repo PR and a fork PR (manual `/ocr review`) in `gh-action-test-01`.

## Open Questions

- Should the `checkout` step also set up `git config user.name/email` for potential future auto-fix features? → No, keep it minimal; OCR is currently read-only.
