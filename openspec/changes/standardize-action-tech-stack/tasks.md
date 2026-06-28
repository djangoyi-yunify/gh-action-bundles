## 1. Shared Tooling

- [x] 1.1 Create `packages/shared/tsconfig.action.json` preset with Node 24 compiler options
- [x] 1.2 Implement `packages/shared/src/build-action.ts` helper that bundles action step scripts with esbuild
- [x] 1.3 Expose the build helper as a bin script in `packages/shared/package.json`
- [x] 1.4 Update `packages/shared` TypeScript compilation to include the new helper

## 2. Root Workspace Updates

- [x] 2.1 Update root `package.json` `engines.node` to `>=24`
- [x] 2.2 Update root `devDependencies` `@types/node` to a Node 24 aligned version
- [x] 2.3 Ensure root `pnpm build` / `pnpm lint` / `pnpm test` cover all actions uniformly
- [x] 2.4 Rebuild lockfile if dependency versions change

## 3. Documentation

- [x] 3.1 Add an "Action Development Standard" section to `AGENTS.md`
- [x] 3.2 Document required directory structure (`action.yml`, `package.json`, `tsconfig.json`, `README.md`, `src/`, `dist/`)
- [x] 3.3 Document build command conventions and tracked `dist/` requirement
- [x] 3.4 Document Node 24 baseline and shared tooling usage

## 4. Refactor ocr-review

- [x] 4.1 Update `actions/ocr-review/package.json` `engines.node` to `>=24`
- [x] 4.2 Update `actions/ocr-review/tsconfig.json` to extend `packages/shared/tsconfig.action.json`
- [x] 4.3 Replace `actions/ocr-review/build.js` with a build script that invokes the shared helper
- [x] 4.4 Update `actions/ocr-review/package.json` scripts to use the shared helper
- [x] 4.5 Update `actions/ocr-review` esbuild target to `node24`
- [x] 4.6 Rebuild `actions/ocr-review/dist/` and verify outputs are functionally equivalent

## 5. Verification

- [x] 5.1 Run `pnpm install` and confirm workspace resolves cleanly
- [x] 5.2 Run `pnpm build` at root and confirm all packages/actions build
- [x] 5.3 Run `pnpm lint` at root and confirm type checking passes
- [x] 5.4 Diff rebuilt `dist/` against previous version to ensure no unintended behavioral changes
- [x] 5.5 Verify `action.yml` still references `dist/*.js` correctly
