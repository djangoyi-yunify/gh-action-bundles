"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.buildAction = buildAction;
const esbuild_1 = require("esbuild");
const fs_1 = require("fs");
const path_1 = require("path");
/**
 * Bundles action step scripts from `src/<step>.ts` into `dist/<step>.js`.
 * Each output is a self-contained CommonJS bundle targeting the configured Node version.
 */
function buildAction(options = {}) {
    const actionDir = options.actionDir ?? process.cwd();
    const steps = options.steps ?? readStepsFromPackageJson(actionDir);
    const target = options.target ?? 'node24';
    const minify = options.minify ?? false;
    const sourcemap = options.sourcemap ?? false;
    const external = options.external ?? [];
    const distDir = (0, path_1.join)(actionDir, 'dist');
    if (!(0, fs_1.existsSync)(distDir)) {
        (0, fs_1.mkdirSync)(distDir, { recursive: true });
    }
    for (const step of steps) {
        (0, esbuild_1.buildSync)({
            entryPoints: [(0, path_1.join)(actionDir, 'src', `${step}.ts`)],
            bundle: true,
            platform: 'node',
            target,
            outfile: (0, path_1.join)(distDir, `${step}.js`),
            format: 'cjs',
            external,
            minify,
            sourcemap,
        });
        console.log(`Built dist/${step}.js`);
    }
}
function readStepsFromPackageJson(actionDir) {
    const packageJsonPath = (0, path_1.join)(actionDir, 'package.json');
    try {
        const raw = (0, fs_1.readFileSync)(packageJsonPath, 'utf-8');
        const pkg = JSON.parse(raw);
        if (pkg['action-steps'] && Array.isArray(pkg['action-steps'])) {
            return pkg['action-steps'];
        }
    }
    catch {
        // Fall through to the error below.
    }
    throw new Error(`No steps provided and no "action-steps" field found in ${packageJsonPath}`);
}
if (require.main === module) {
    const args = process.argv.slice(2);
    if (args.length === 0) {
        console.error('Usage: build-action <step1> [step2] ...');
        process.exit(1);
    }
    buildAction({ steps: args });
}
