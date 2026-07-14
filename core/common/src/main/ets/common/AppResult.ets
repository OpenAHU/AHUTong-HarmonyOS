export enum AppErrorKind {
  TRANSPORT = 'transport',
  TIMEOUT = 'timeout',
  HTTP = 'http',
  AUTHENTICATION = 'authentication',
  PARSE = 'parse',
  UNKNOWN = 'unknown'
}

export interface AppError {
  kind: AppErrorKind;
  message: string;
  code?: number;
}

export interface AppResult<T> {
  isSuccess: boolean;
  data?: T;
  error?: AppError;
}

export class AppResults {
  static success<T>(data: T): AppResult<T> {
    return { isSuccess: true, data: data };
  }

  static failure<T>(kind: AppErrorKind, message: string, code?: number): AppResult<T> {
    return {
      isSuccess: false,
      error: { kind: kind, message: message, code: code }
    };
  }
}

export class AppSessionState {
  private static listeners: Array<() => void> = [];
  static sessionExpired: boolean = false;

  static activate(): void {
    AppSessionState.sessionExpired = false;
  }

  static expire(): void {
    AppSessionState.sessionExpired = true;
    AppSessionState.listeners.slice().forEach((listener: () => void): void => listener());
  }

  static subscribe(listener: () => void): void {
    if (!AppSessionState.listeners.includes(listener)) AppSessionState.listeners.push(listener);
  }

  static unsubscribe(listener: () => void): void {
    AppSessionState.listeners = AppSessionState.listeners.filter((item: () => void): boolean => item !== listener);
  }
}
