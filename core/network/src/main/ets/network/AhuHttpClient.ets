import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppErrorKind, AppResult, AppResults } from 'core_common';

export class NetworkDefaults {
  static readonly CONNECT_TIMEOUT_MS: number = 15_000;
  static readonly READ_TIMEOUT_MS: number = 30_000;
}

export enum AhuHttpMethod {
  GET = 'GET',
  POST = 'POST',
  PUT = 'PUT',
  DELETE = 'DELETE'
}

export interface AhuHttpRequest {
  url: string;
  method?: AhuHttpMethod;
  headers?: Record<string, string>;
  body?: string;
  connectTimeout?: number;
  readTimeout?: number;
  useCache?: boolean;
}

export class CookieStore {
  private cookies: Map<string, string> = new Map();

  private host(url: string): string {
    const match = /^https?:\/\/([^/]+)/i.exec(url);
    return match && match.length > 1 ? match[1] : url;
  }

  get(url: string): string | undefined {
    return this.cookies.get(this.host(url));
  }

  save(url: string, cookie: string): void {
    if (cookie.length > 0) {
      this.cookies.set(this.host(url), cookie);
    }
  }

  clear(): void {
    this.cookies.clear();
  }
}

export class AhuHttpClient {
  readonly cookieStore: CookieStore;

  constructor(cookieStore: CookieStore = new CookieStore()) {
    this.cookieStore = cookieStore;
  }

  private requestMethod(method: AhuHttpMethod): http.RequestMethod {
    switch (method) {
      case AhuHttpMethod.POST:
        return http.RequestMethod.POST;
      case AhuHttpMethod.PUT:
        return http.RequestMethod.PUT;
      case AhuHttpMethod.DELETE:
        return http.RequestMethod.DELETE;
      default:
        return http.RequestMethod.GET;
    }
  }

  private requestHeaders(request: AhuHttpRequest): Record<string, string> {
    const headers: Record<string, string> = {};
    if (request.headers) {
      Object.keys(request.headers).forEach((key: string) => headers[key] = request.headers?.[key] ?? '');
    }
    if (!headers['Accept']) {
      headers['Accept'] = 'application/json';
    }
    if (request.body !== undefined && !headers['Content-Type']) {
      headers['Content-Type'] = 'application/json; charset=utf-8';
    }
    const cookie = this.cookieStore.get(request.url);
    if (cookie && !headers['Cookie']) {
      headers['Cookie'] = cookie;
    }
    return headers;
  }

  async request<T>(request: AhuHttpRequest): Promise<AppResult<T>> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(request.url, {
        method: this.requestMethod(request.method ?? AhuHttpMethod.GET),
        header: this.requestHeaders(request),
        extraData: request.body,
        expectDataType: http.HttpDataType.STRING,
        usingCache: request.useCache ?? false,
        connectTimeout: request.connectTimeout ?? NetworkDefaults.CONNECT_TIMEOUT_MS,
        readTimeout: request.readTimeout ?? NetworkDefaults.READ_TIMEOUT_MS
      });

      this.cookieStore.save(request.url, response.cookies);
      const statusCode = response.responseCode as number;
      if (statusCode === 401 || statusCode === 403) {
        return AppResults.failure<T>(AppErrorKind.AUTHENTICATION, '登录状态已失效', statusCode);
      }
      if (statusCode < 200 || statusCode >= 300) {
        return AppResults.failure<T>(AppErrorKind.HTTP, `请求失败（${statusCode}）`, statusCode);
      }

      const body = response.result as string;
      try {
        const data = JSON.parse(body) as T;
        return AppResults.success<T>(data);
      } catch (_) {
        return AppResults.failure<T>(AppErrorKind.PARSE, '服务器数据解析失败');
      }
    } catch (error) {
      const businessError = error as BusinessError;
      const message = businessError.message ?? '网络请求失败';
      const kind = message.toLowerCase().includes('timeout') ? AppErrorKind.TIMEOUT : AppErrorKind.TRANSPORT;
      return AppResults.failure<T>(kind, message, businessError.code);
    } finally {
      httpRequest.destroy();
    }
  }
}
