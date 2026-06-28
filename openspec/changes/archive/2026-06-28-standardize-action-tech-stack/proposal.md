## Why

The repository currently has only one action (`ocr-review`) but plans to host multiple GitHub Composite Actions for code review, code fix, and Q&A. Without a standardized development stack, each new action will accumulate slightly different tooling, build scripts, and documentation, increasing maintenance cost and making contributions harder. We need to formalize the existing `ocr-review` stack as the project standard and extract reusable tooling so future actions are consistent by default.

## What Changes

- Add a documented standard to `AGENTS.md` describing the required structure, tooling, and conventions for every action.
- Upgrade the Node target from 20 to 24 across root tooling, shared package, and existing action.
- Extract the ad-hoc `build.js` from `actions/ocr-review` into a reusable build helper in `packages/shared` (or a shared build package).
- Introduce a shared `tsconfig.json` preset that all actions extend.
- Refactor `actions/ocr-review` to use the shared build helper and shared tsconfig.
- Add root-level lint/test scripts that cover all actions uniformly.
- Ensure `dist/` build artifacts remain tracked and reproducible.

## Capabilities

### New Capabilities
- `github-action-standard`: Defines the standardized development stack, directory structure, build tooling, and documentation requirements for all GitHub Composite Actions in the repository.

### Modified Capabilities
- None. `ocr-review` will be refactored to conform to the new standard, but its public behavior and existing requirements remain unchanged.

## Impact

- `AGENTS.md` gains a new "Action Development Standard" section.
- `packages/shared` gains a build helper and/or tsconfig preset.
- `actions/ocr-review/package.json`, `tsconfig.json`, and `build.js` are refactored.
- Root `package.json` and workspace scripts are extended.
- No public Action inputs/outputs change.
