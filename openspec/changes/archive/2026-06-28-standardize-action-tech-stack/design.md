## Context

The project currently contains one composite action, `actions/ocr-review`, built with TypeScript, esbuild, pnpm workspaces, and a hand-written `build.js`. This stack works, but it is not documented or reusable. Future actions (code fix, Q&A, etc.) risk diverging unless we extract common tooling and write down the conventions. GitHub Actions runners already support Node 24, so we will align the project with the current LTS line.

## Goals / Non-Goals

**Goals:**
- Establish a single, documented development stack for every composite action.
- Move Node target and runtime baseline to 24.
- Extract reusable build and TypeScript configuration from `actions/ocr-review`.
- Refactor `actions/ocr-review` to prove the shared tooling works end-to-end.
- Keep all build artifacts (`dist/`) tracked and reproducible.

**Non-Goals:**
- Changing `ocr-review` inputs, outputs, or runtime behavior.
- Adding new actions in this change.
- Migrating to a different bundler or package manager.
- Publishing packages to a registry.

## Decisions

### 1. Shared build helper in `packages/shared`
**Decision:** Move the esbuild step logic into `packages/shared/src/build-action.ts` and expose a small CLI (`build-action`) that each action calls from its `package.json` `build` script.

**Rationale:**
- Eliminates copy-pasted `build.js` files across actions.
- Keeps the convention that each action still owns its `package.json` scripts and entry-point configuration.
- Easier to update target, format, or bundler options in one place.

**Alternative considered:** Keep a `build.js` in every action and symlink a shared template. Rejected because symlinks are fragile on Windows and updates still require touching each file.

### 2. Shared tsconfig preset in `packages/shared`
**Decision:** Create `packages/shared/tsconfig.action.json` (or `tsconfig.base.json`) that each action extends.

**Rationale:**
- Guarantees consistent compiler options (`strict`, `esModuleInterop`, `moduleResolution`, etc.).
- Actions only override `rootDir`, `outDir`, and `include`.

### 3. Node 24 everywhere
**Decision:** Update `engines.node` in root `package.json`, esbuild `target`, `@types/node`, and GitHub Action runner assumptions to Node 24.

**Rationale:**
- Node 20 enters maintenance in late 2024/2025; Node 24 is the current LTS path.
- The user explicitly requested Node 24.

### 4. Document the standard in `AGENTS.md`
**Decision:** Add an "Action Development Standard" section to `AGENTS.md` rather than creating a separate `CONTRIBUTING.md`.

**Rationale:**
- `AGENTS.md` is the agent-focused source of truth; conventions that affect code generation belong there.
- A separate `CONTRIBUTING.md` can be added later for human contributors.

### 5. Root scripts cover all actions uniformly
**Decision:** Root `package.json` keeps `build`, `lint`, and `test` using `pnpm -r` plus per-action filters when useful.

**Rationale:**
- pnpm workspace recursion already handles this; we only need to ensure scripts exist and are consistent.

## Risks / Trade-offs

- [Risk] Refactoring `ocr-review` build could accidentally change `dist/` output and break the action. → Mitigation: rebuild and diff `dist/` before committing; keep minify/sourcemap settings identical.
- [Risk] Node 24 is not available on all self-hosted runners. → Mitigation: This is a composite action, so Node version is determined by the runner's installed Node; documenting Node 24 as the baseline does not force consumers to upgrade if their runner lacks it, but new development targets 24.
- [Risk] Shared tooling couples all actions. → Mitigation: Shared package is versioned internally via `workspace:*`; actions can pin an older shared version if they need to diverge.
