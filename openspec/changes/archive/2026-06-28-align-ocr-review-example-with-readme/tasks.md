## 1. Update example workflow

- [x] 1.1 Change `on: pull_request_target` to `on: pull_request` in `examples/ocr-review.yml`
- [x] 1.2 Replace the job `if` condition with the `author_association` gate from README for both `pull_request` and `issue_comment` events
- [x] 1.3 Change the manual trigger phrase from `/ocr` to `/ocr review`
- [x] 1.4 Replace the `actions/github-script` + explicit `ref` checkout with the README pattern (default checkout + `gh pr checkout` for comment triggers)
- [x] 1.5 Remove the `pr-context` step and any `steps.pr-context.outputs.head_sha` references
- [x] 1.6 Verify `permissions` block remains `contents: read` and `pull-requests: write`
- [x] 1.7 Keep `concurrency`, `ready_for_review`, and `background` inputs as-is

## 2. Verify the example

- [x] 2.1 Validate `examples/ocr-review.yml` YAML syntax
- [x] 2.2 Compare the updated example against the README sample to confirm event model and access controls match
- [x] 2.3 Confirm no other `pull_request_target` references remain in `examples/ocr-review.yml`
