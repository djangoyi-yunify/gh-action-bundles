## 1. Extend shared GitHub helper

- [x] 1.1 Add a `getPullRequestCheckoutInfo(repo, prNumber, token)` helper to `packages/shared/src/github.ts` that returns `headRefName`, `headRepository`, and `isCrossRepository`
- [x] 1.2 Rebuild `packages/shared/dist/`

## 2. Implement checkout step

- [x] 2.1 Create `actions/ocr-review/src/checkout.ts`
- [x] 2.2 Read `PR_NUMBER`, `GITHUB_REPOSITORY`, `GITHUB_TOKEN`, and `GITHUB_EVENT_NAME`
- [x] 2.3 Skip checkout when `GITHUB_EVENT_NAME` is not `pull_request` or `issue_comment`
- [x] 2.4 Query PR checkout info via the shared helper
- [x] 2.5 For same-repo PRs: `git fetch origin <headRefName>` and `git checkout <headRefName>`
- [x] 2.6 For fork PRs: `git remote add fork https://github.com/<headRepository>.git`, `git fetch fork <headRefName>`, and `git checkout -b <local-branch> fork/<headRefName>`
- [x] 2.7 Log the detected PR source (same-repo vs fork) and the checked-out branch

## 3. Update action definition

- [x] 3.1 Add `auto-checkout` input to `actions/ocr-review/action.yml` with default `true`
- [x] 3.2 Add `actions/checkout@v4` step with `fetch-depth: 0` and `persist-credentials: false`
- [x] 3.3 Add the `Checkout PR` step that runs `dist/checkout.js` after `Configure LLM`
- [x] 3.4 Pass `GH_TOKEN` and `AUTO_CHECKOUT` env vars to the checkout step
- [x] 3.5 Ensure `install`/`configure` steps still run before checkout

## 4. Update example and documentation

- [x] 4.1 Remove the two checkout steps from `examples/ocr-review.yml`
- [x] 4.2 Update `actions/ocr-review/README.md` usage example to match the simplified workflow
- [x] 4.3 Add the `auto-checkout` input to the README inputs table

## 5. Build and verify

- [x] 5.1 Run `pnpm build` in `actions/ocr-review` to generate `dist/checkout.js`
- [x] 5.2 Run `pnpm lint` and confirm type checking passes
- [x] 5.3 Verify the updated example workflow YAML is valid
- [x] 5.3.1 Fix checkout determinism and re-authenticate git after `actions/checkout`
  - [x] Use `git fetch origin <headRefName>:<headRefName>` to create the local branch explicitly
  - [x] Run `gh auth setup-git` so `git fetch` works for private repositories
  - [x] Rebuild `dist/checkout.js`
- [ ] 5.4 Test with a same-repo PR in `gh-action-test-01`
- [ ] 5.5 Test with a fork PR manual `/ocr review` in `gh-action-test-01`
