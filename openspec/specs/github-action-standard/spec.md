# GitHub Action Development Standard

## Purpose

Define the standardized development stack, directory structure, build tooling, and documentation requirements for all GitHub Composite Actions in the repository.

## Requirements

### Requirement: All actions use the documented development stack
Every GitHub Composite Action in the repository SHALL use the same technology stack and conventions defined by the project standard.

#### Scenario: New action scaffolding
- **WHEN** a contributor creates a new action under `actions/<name>`
- **THEN** the action follows the directory structure, tooling, build scripts, and documentation conventions documented in `AGENTS.md`

### Requirement: All actions target Node 24
Every action SHALL be developed, bundled, and documented for Node 24.

#### Scenario: Build target
- **WHEN** an action is built
- **THEN** the esbuild target is `node24`

#### Scenario: Type definitions
- **WHEN** an action declares TypeScript dependencies
- **THEN** it uses `@types/node` aligned with Node 24

#### Scenario: Engine declaration
- **WHEN** a `package.json` declares an `engines` field
- **THEN** `node` is `>=24`

### Requirement: All actions share common TypeScript configuration
Every action SHALL extend the shared TypeScript preset provided by `packages/shared`.

#### Scenario: tsconfig extends preset
- **WHEN** an action defines `tsconfig.json`
- **THEN** it extends the shared preset and only overrides `rootDir`, `outDir`, and `include`

### Requirement: All actions use the shared build helper
Every action SHALL bundle its step scripts using the shared build helper from `packages/shared`.

#### Scenario: Build script uses shared helper
- **WHEN** an action runs `pnpm build`
- **THEN** it invokes the shared build helper, which bundles each step script in `src/` into a self-contained `dist/<step>.js` file

#### Scenario: Build helper configuration
- **WHEN** an action invokes the shared build helper
- **THEN** it passes the list of step entry points and receives CommonJS outputs targeting Node 24

### Requirement: All actions track build artifacts
Every action SHALL commit its `dist/` directory to version control so consumers can use the action without building from source.

#### Scenario: Action checkout
- **WHEN** a workflow references `uses: owner/repo/actions/<name>@<ref>`
- **THEN** the referenced `dist/` files are present in the repository at that ref

### Requirement: All actions document inputs, outputs, and usage
Every action SHALL provide a `README.md` with inputs, outputs, and a usage example.

#### Scenario: README completeness
- **WHEN** a new action is added
- **THEN** its `README.md` includes a description, usage workflow, input/output tables, and any required secrets

### Requirement: Root workspace scripts cover all actions uniformly
Root-level scripts SHALL build, lint, and test every action in the workspace consistently.

#### Scenario: Root build
- **WHEN** a developer runs `pnpm build` at the repository root
- **THEN** all shared packages and actions are built in dependency order

#### Scenario: Root lint
- **WHEN** a developer runs `pnpm lint` at the repository root
- **THEN** every action runs `tsc --noEmit` or an equivalent type check

### Requirement: Shared package exposes reusable tooling
The `packages/shared` package SHALL expose the build helper and TypeScript preset used by all actions.

#### Scenario: Build helper export
- **WHEN** an action imports or invokes the shared build helper
- **THEN** the helper is available from `packages/shared` without duplicating bundling logic

#### Scenario: tsconfig preset export
- **WHEN** an action extends the shared tsconfig preset
- **THEN** the preset file is located in `packages/shared`
