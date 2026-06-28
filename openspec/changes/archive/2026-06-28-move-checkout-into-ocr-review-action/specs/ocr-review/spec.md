## ADDED Requirements

### Requirement: Action checks out the repository and the correct PR head branch
The action SHALL fetch the repository and check out the head branch of the pull request before running OCR, supporting both same-repo and fork PRs.

#### Scenario: Same-repo PR is checked out automatically
- **WHEN** the action is invoked for a same-repo PR
- **THEN** it fetches `origin/<head-ref-name>` and checks out the head branch

#### Scenario: Fork PR is checked out automatically
- **WHEN** the action is invoked for a fork PR
- **THEN** it adds the fork repository as a remote, fetches the head branch from the fork, and checks it out locally

#### Scenario: Caller can disable automatic checkout
- **WHEN** the action is invoked with `auto-checkout: false`
- **THEN** the action does not perform any checkout and relies on the caller's existing workspace

#### Scenario: Checkout is skipped for non-PR events
- **WHEN** the action is triggered by an event other than `pull_request` or `issue_comment`
- **THEN** the checkout step completes without modifying the workspace
