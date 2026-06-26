"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setOutput = setOutput;
exports.setEnv = setEnv;
exports.getEnv = getEnv;
exports.getEnvBool = getEnvBool;
const fs_1 = require("fs");
function setOutput(name, value) {
    const file = process.env.GITHUB_OUTPUT;
    if (!file) {
        throw new Error('GITHUB_OUTPUT is not defined');
    }
    (0, fs_1.appendFileSync)(file, `${name}=${value}\n`);
}
function setEnv(name, value) {
    const file = process.env.GITHUB_ENV;
    if (!file) {
        throw new Error('GITHUB_ENV is not defined');
    }
    (0, fs_1.appendFileSync)(file, `${name}=${value}\n`);
}
function getEnv(name, required = true) {
    const value = process.env[name] || '';
    if (required && value === '') {
        throw new Error(`Environment variable ${name} is required`);
    }
    return value;
}
function getEnvBool(name, defaultValue = false) {
    const value = process.env[name];
    if (value === undefined)
        return defaultValue;
    return value === 'true' || value === '1';
}
