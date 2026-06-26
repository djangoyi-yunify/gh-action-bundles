## Why

We have researched both opencode's official `github` action and the `opencode-pr-reviewer` action. We need a consolidated comparison of their GitHub Action configurations and implementation patterns to guide the design of our own reusable code-review action.

## What Changes

This change is a research spike, not an implementation. It will produce reference documentation summarizing:

- How opencode's official `github/action.yml` is structured and configured.
- How `opencode-pr-reviewer/action.yml` is structured and configured.
- The workflow files that consume each action.
- The common composite-action pattern shared by both.
- Key differences in authentication, permission control, prompt construction, and output handling.

The detailed research notes will live in two places:

1. `openspec/changes/research-github-action-patterns/research-notes.md` — the original research record attached to this change.
2. `docs/research/github-action-patterns.md` — a public-facing copy for future design and research reference.

## Capabilities

### New Capabilities

- `github-action-patterns-research`: Reference documentation comparing GitHub Action implementation patterns across opencode's official action and opencode-pr-reviewer.

### Modified Capabilities

- None. This is a research-only change.

## Impact

- Adds a reference document under the OpenSpec change directory.
- Adds a public-facing copy at `docs/research/github-action-patterns.md` for ongoing design work.
- Updates `README.md` with a link to the public research document.
- Does not modify application code, workflows, or configuration.
