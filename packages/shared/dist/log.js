"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.log = void 0;
exports.info = info;
exports.error = error;
exports.warning = warning;
exports.debug = debug;
function info(message) {
    console.log(message);
}
function error(message) {
    console.log(`::error::${message}`);
}
function warning(message) {
    console.log(`::warning::${message}`);
}
function debug(message) {
    if (process.env.RUNNER_DEBUG === '1' || process.env.ACTIONS_STEP_DEBUG === 'true') {
        console.log(`::debug::${message}`);
    }
}
exports.log = { info, error, warning, debug };
