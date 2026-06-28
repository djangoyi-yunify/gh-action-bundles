## 1. Update ocr-review Action

- [x] 1.1 Add optional `identifier` input to `actions/ocr-review/action.yml`
- [x] 1.2 Pass `IDENTIFIER` env var through action steps
- [x] 1.3 Update `actions/ocr-review/src/post-review.ts` to prefix comment bodies with `[{identifier}] ` when identifier is provided
- [x] 1.4 Rebuild `actions/ocr-review/dist/` and verify changes

## 2. Update ocr-review README

- [x] 2.1 Replace `pull_request_target` example with `pull_request` + `issue_comment` workflow
- [x] 2.2 Add `author_association` gate to the workflow example
- [x] 2.3 Add `/ocr review` comment trigger matching
- [x] 2.4 Add checkout step for comment triggers (`gh pr checkout`)
- [x] 2.5 Add `identifier` to the inputs table
- [x] 2.6 Add example showing two coexisting review actions with different identifiers
- [x] 2.7 Add security model section explaining fork PR limitations

## 3. Update AGENTS.md Standard

- [x] 3.1 Add a note that the recommended workflow pattern uses `pull_request` + `issue_comment` with author gating
- [x] 3.2 Mention that `pull_request_target` is an alternative for those who need automatic fork PR review

## 4. Update Test Repository Workflow

- [x] 4.1 Update `gh-action-test-01/.github/workflows/ocr-review.yml` to use `pull_request` + `issue_comment`
- [x] 4.2 Add author association gate and `/ocr review` trigger
- [x] 4.3 Push the updated workflow to `main`

## 5. Verify Same-Repo PR Auto-Review

- [x] 5.1 Open or update a same-repo PR
- [x] 5.2 Confirm workflow runs and posts review comments with identifier prefix

## 6. Verify Comment Trigger

- [x] 6.1 Comment `/ocr review` on a PR
- [x] 6.2 Confirm workflow runs and posts review comments with identifier prefix
