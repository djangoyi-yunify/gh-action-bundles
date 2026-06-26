export function info(message: string): void {
  console.log(message);
}

export function error(message: string): void {
  console.log(`::error::${message}`);
}

export function warning(message: string): void {
  console.log(`::warning::${message}`);
}

export function debug(message: string): void {
  if (process.env.RUNNER_DEBUG === '1' || process.env.ACTIONS_STEP_DEBUG === 'true') {
    console.log(`::debug::${message}`);
  }
}

export const log = { info, error, warning, debug };
