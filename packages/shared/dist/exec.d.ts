export interface ExecOptions {
    cwd?: string;
    env?: NodeJS.ProcessEnv;
    ignoreExitCode?: boolean;
}
export interface ExecResult {
    stdout: string;
    stderr: string;
    exitCode: number;
}
export declare function exec(command: string, args?: string[], options?: ExecOptions): Promise<ExecResult>;
export declare function execCapture(command: string, args?: string[], options?: ExecOptions): Promise<ExecResult>;
