import { buildSync } from 'esbuild';
import { existsSync, mkdirSync, readFileSync } from 'fs';
import { join } from 'path';

export interface BuildActionOptions {
  /** Directory containing the action's package.json, src/, and dist/. Defaults to process.cwd(). */
  actionDir?: string;
  /** Step names to build. Defaults to the `action-steps` field in package.json. */
  steps?: string[];
  /** esbuild target. Defaults to `node24`. */
  target?: string;
  /** Minify output. Defaults to false. */
  minify?: boolean;
  /** Emit sourcemaps. Defaults to false. */
  sourcemap?: boolean;
  /** Packages to mark as external. Defaults to []. */
  external?: string[];
}

/**
 * Bundles action step scripts from `src/<step>.ts` into `dist/<step>.js`.
 * Each output is a self-contained CommonJS bundle targeting the configured Node version.
 */
export function buildAction(options: BuildActionOptions = {}): void {
  const actionDir = options.actionDir ?? process.cwd();
  const steps = options.steps ?? readStepsFromPackageJson(actionDir);
  const target = options.target ?? 'node24';
  const minify = options.minify ?? false;
  const sourcemap = options.sourcemap ?? false;
  const external = options.external ?? [];

  const distDir = join(actionDir, 'dist');
  if (!existsSync(distDir)) {
    mkdirSync(distDir, { recursive: true });
  }

  for (const step of steps) {
    buildSync({
      entryPoints: [join(actionDir, 'src', `${step}.ts`)],
      bundle: true,
      platform: 'node',
      target,
      outfile: join(distDir, `${step}.js`),
      format: 'cjs',
      external,
      minify,
      sourcemap,
    });
    console.log(`Built dist/${step}.js`);
  }
}

function readStepsFromPackageJson(actionDir: string): string[] {
  const packageJsonPath = join(actionDir, 'package.json');
  try {
    const raw = readFileSync(packageJsonPath, 'utf-8');
    const pkg = JSON.parse(raw);
    if (pkg['action-steps'] && Array.isArray(pkg['action-steps'])) {
      return pkg['action-steps'];
    }
  } catch {
    // Fall through to the error below.
  }
  throw new Error(
    `No steps provided and no "action-steps" field found in ${packageJsonPath}`
  );
}

if (require.main === module) {
  const args = process.argv.slice(2);
  if (args.length === 0) {
    console.error('Usage: build-action <step1> [step2] ...');
    process.exit(1);
  }
  buildAction({ steps: args });
}
