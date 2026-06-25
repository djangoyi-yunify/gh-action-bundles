## Why

We need to understand how `opencode-pr-reviewer` builds its review prompt — including what PR data it collects, how it structures the user prompt, and how it handles trigger comments — so we can compare it with opencode's official `github run` and make informed design decisions for our own GitHub Action.

## What Changes

This change is a research spike, not an implementation. It will produce reference documentation summarizing:

- The data sources used by `opencode-pr-reviewer` (`gh pr view`, reviews, inline comments).
- How the prompt is composed in `scripts/opencode-review-prompt.sh`.
- How `/oc review` trigger comments are stripped and forwarded as guidance.
- The output format constraints imposed on the model.
- The security model and permission restrictions.
- Differences compared to opencode's official `github run` path.

The detailed research notes will live in two places:

1. `openspec/changes/research-opencode-pr-reviewer/research-notes.md` — the original research record attached to this change.
2. `docs/research/opencode-pr-reviewer.md` — a public-facing copy for future design and research reference.

## Capabilities

### New Capabilities

- `opencode-pr-reviewer-research`: Reference documentation capturing the prompt construction details of `opencode-pr-reviewer` for future design decisions.

### Modified Capabilities

- None. This is a research-only change.

## Impact

- Adds a reference document under the OpenSpec change directory.
- Adds a public-facing copy at `docs/research/opencode-pr-reviewer.md` for ongoing design work.
- Updates `README.md` with a link to the public research document.
- Does not modify application code, workflows, or configuration.
