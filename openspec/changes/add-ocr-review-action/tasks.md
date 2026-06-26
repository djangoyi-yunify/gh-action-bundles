## 1. Monorepo Setup

- [x] 1.1 Initialize root `package.json` with pnpm workspace configuration
- [x] 1.2 Create `pnpm-workspace.yaml` including `packages/*` and `actions/*`
- [x] 1.3 Add root-level build/test scripts and shared dev dependencies (typescript, esbuild)

## 2. Shared Package

- [x] 2.1 Create `packages/shared/package.json` and `tsconfig.json`
- [x] 2.2 Implement `packages/shared/src/exec.ts` for safe shell command execution
- [x] 2.3 Implement `packages/shared/src/env.ts` for GITHUB_ENV and GITHUB_OUTPUT helpers
- [x] 2.4 Implement `packages/shared/src/github.ts` for PR metadata and comment APIs
- [x] 2.5 Implement `packages/shared/src/review.ts` for OCR JSON parsing and comment formatting
- [x] 2.6 Implement `packages/shared/src/log.ts` for GitHub Actions style logging

## 3. OCR Review Action Scaffolding

- [x] 3.1 Create `actions/ocr-review/package.json` and `tsconfig.json`
- [x] 3.2 Create `actions/ocr-review/action.yml` with all defined inputs and outputs
- [x] 3.3 Create `actions/ocr-review/build.js` to bundle each step script with esbuild
- [x] 3.4 Add `.gitignore` rules for `node_modules` but ensure `dist/` is tracked

## 4. Step Scripts

- [x] 4.1 Implement `actions/ocr-review/src/install.ts` to install OCR via npm
- [x] 4.2 Implement `actions/ocr-review/src/configure.ts` to run `ocr config set`
- [x] 4.3 Implement `actions/ocr-review/src/resolve-pr.ts` to infer base-ref and head-sha
- [x] 4.4 Implement `actions/ocr-review/src/run-review.ts` to execute `ocr review --format json`
- [x] 4.5 Implement `actions/ocr-review/src/post-review.ts` to parse JSON and publish PR comments

## 5. Build and Artifacts

- [x] 5.1 Build all shared package and action step scripts
- [x] 5.2 Verify `dist/*.js` files are self-contained and runnable in Node 20
- [x] 5.3 Commit `dist/` build artifacts to the repository

## 6. Documentation

- [x] 6.1 Write `actions/ocr-review/README.md` with usage example and input/output reference
- [x] 6.2 Provide example calling workflow in README or `examples/ocr-review.yml`

## 7. Verification

- [x] 7.1 Validate `action.yml` syntax with `actionlint` or GitHub Actions schema
- [x] 7.2 Run a test workflow against a sample PR (if environment permits)
- [x] 7.3 Review and finalize all generated artifacts
