"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.exec = exec;
exports.execCapture = execCapture;
const child_process_1 = require("child_process");
const log_1 = require("./log");
function exec(command, args = [], options = {}) {
    return new Promise((resolve, reject) => {
        log_1.log.info(`$ ${command} ${args.map(a => (a.includes(' ') ? `"${a}"` : a)).join(' ')}`);
        const child = (0, child_process_1.spawn)(command, args, {
            cwd: options.cwd,
            env: { ...process.env, ...options.env },
            stdio: ['ignore', 'pipe', 'pipe'],
        });
        let stdout = '';
        let stderr = '';
        child.stdout.on('data', (data) => {
            const chunk = data.toString();
            stdout += chunk;
            process.stdout.write(chunk);
        });
        child.stderr.on('data', (data) => {
            const chunk = data.toString();
            stderr += chunk;
            process.stderr.write(chunk);
        });
        child.on('error', reject);
        child.on('close', (exitCode) => {
            const result = { stdout, stderr, exitCode: exitCode ?? 0 };
            if (exitCode !== 0 && !options.ignoreExitCode) {
                reject(new Error(`Command failed with exit code ${exitCode}: ${stderr || stdout}`));
            }
            else {
                resolve(result);
            }
        });
    });
}
function execCapture(command, args = [], options = {}) {
    return new Promise((resolve, reject) => {
        log_1.log.info(`$ ${command} ${args.map(a => (a.includes(' ') ? `"${a}"` : a)).join(' ')}`);
        const child = (0, child_process_1.spawn)(command, args, {
            cwd: options.cwd,
            env: { ...process.env, ...options.env },
            stdio: ['ignore', 'pipe', 'pipe'],
        });
        let stdout = '';
        let stderr = '';
        child.stdout.on('data', (data) => {
            stdout += data.toString();
        });
        child.stderr.on('data', (data) => {
            stderr += data.toString();
        });
        child.on('error', reject);
        child.on('close', (exitCode) => {
            const result = { stdout: stdout.trim(), stderr: stderr.trim(), exitCode: exitCode ?? 0 };
            if (exitCode !== 0 && !options.ignoreExitCode) {
                reject(new Error(`Command failed with exit code ${exitCode}: ${stderr || stdout}`));
            }
            else {
                resolve(result);
            }
        });
    });
}
