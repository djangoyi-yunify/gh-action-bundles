## Why

We need to understand how `opencode github run` works internally — especially how it collects GitHub event/PR/issue data and how it constructs the default prompts — before we can design our own reusable GitHub Action for code review.

## What Changes

This change is a research spike, not an implementation. It will produce reference documentation summarizing:

- The entry point and control flow of `opencode github run`.
- What data is fetched from GitHub (REST vs GraphQL, fields, limits).
- How user prompts are extracted from comments and PR/Issue context.
- How the final system prompt is assembled (default prompt + env + instructions + skills).
- Gaps found in the current implementation (e.g., unused `agent` input).

The detailed research notes will live in two places:

1. `openspec/changes/research-opencode-github-run/research-notes.md` — the original research record attached to this change.
2. `docs/research/opencode-github-run.md` — a public-facing copy for future design and research reference.

## Capabilities

### New Capabilities

- `opencode-github-run-research`: Reference documentation capturing the implementation details of `opencode github run` for future design decisions.

### Modified Capabilities

- None. This is a research-only change.

## Impact

- Adds a reference document under the OpenSpec change directory.
- Adds a public-facing copy at `docs/research/opencode-github-run.md` for ongoing design work.
- Updates `README.md` with a link to the public research document.
- Does not modify application code, workflows, or configuration.
