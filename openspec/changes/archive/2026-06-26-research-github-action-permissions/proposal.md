## Why

We need to understand how reference actions handle GitHub permissions at the composite-action level — specifically how they obtain tokens and what permissions they require from the calling workflow — so we can design the permission model for our own code-review action.

## What Changes

This change is a research spike, not an implementation. It will produce reference documentation summarizing:

- How opencode's official `github/action.yml` handles token acquisition (OIDC vs GITHUB_TOKEN).
- How `opencode-pr-reviewer/action.yml` handles token acquisition (GH_TOKEN).
- What permissions each action requires from the calling workflow.
- The differences in their permission models.

The detailed research notes will live in two places:

1. `openspec/changes/research-github-action-permissions/research-notes.md` — the original research record attached to this change.
2. `docs/research/github-action-permissions.md` — a public-facing copy for future design and research reference.

## Capabilities

### New Capabilities

- `github-action-permissions-research`: Reference documentation comparing GitHub permission handling in opencode's official action and opencode-pr-reviewer.

### Modified Capabilities

- None. This is a research-only change.

## Impact

- Adds a reference document under the OpenSpec change directory.
- Adds a public-facing copy at `docs/research/github-action-permissions.md` for ongoing design work.
- Updates `README.md` with a link to the public research document.
- Does not modify application code, workflows, or configuration.
