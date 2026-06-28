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
export declare function buildAction(options?: BuildActionOptions): void;
