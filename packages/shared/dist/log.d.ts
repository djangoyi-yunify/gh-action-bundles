export declare function info(message: string): void;
export declare function error(message: string): void;
export declare function warning(message: string): void;
export declare function debug(message: string): void;
export declare const log: {
    info: typeof info;
    error: typeof error;
    warning: typeof warning;
    debug: typeof debug;
};
