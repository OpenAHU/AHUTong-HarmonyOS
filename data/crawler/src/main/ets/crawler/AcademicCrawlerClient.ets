import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppErrorKind, AppResult, AppResults, AppSessionState } from 'core_common';
import { CrawlerSession } from './CrawlerSession';

export class AcademicCrawlerClient {
  private headers(hasBody: boolean = false): Record<string, string> {
    const headers: Record<string, string> = {
      'Accept': '*/*',
      'User-Agent': 'AHUTong/1.0 (HarmonyOS)'
    };
    const cookie = CrawlerSession.academicCookies.header();
    if (cookie.length > 0) {
      headers['Cookie'] = cookie;
    }
    if (hasBody) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }
    return headers;
  }

  private isLoginPage(statusCode: number, body: string): boolean {
    if (statusCode === 401 || statusCode === 403) {
      return true;
    }
    return /name=["']lt["']/i.test(body) && /cas\/login|_eventId/i.test(body);
  }

  private async requestOnce(url: string, method: http.RequestMethod = http.RequestMethod.GET,
    body?: string): Promise<AppResult<string>> {
    const request = http.createHttp();
    try {
      const response = await request.request(url, {
        method: method,
        header: this.headers(body !== undefined),
        extraData: body,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15_000,
        readTimeout: 30_000,
        usingCache: false,
        maxRedirects: 10
      });
      CrawlerSession.academicCookies.save(response.cookies);
      const statusCode = response.responseCode as number;
      const responseBody = response.result as string;
      if (this.isLoginPage(statusCode, responseBody)) {
        return AppResults.failure<string>(AppErrorKind.AUTHENTICATION, '教务登录状态已失效', statusCode);
      }
      if (statusCode < 200 || statusCode >= 300) {
        return AppResults.failure<string>(AppErrorKind.HTTP, `教务请求失败（${statusCode}）`, statusCode);
      }
      return AppResults.success<string>(responseBody);
    } catch (error) {
      const businessError = error as BusinessError;
      const message = businessError.message ?? '教务网络请求失败';
      const kind = message.toLowerCase().includes('timeout') ? AppErrorKind.TIMEOUT : AppErrorKind.TRANSPORT;
      return AppResults.failure<string>(kind, message, businessError.code);
    } finally {
      request.destroy();
    }
  }

  async getText(url: string): Promise<AppResult<string>> {
    const first = await this.requestOnce(url);
    if (first.isSuccess || first.error?.kind !== AppErrorKind.AUTHENTICATION) {
      return first;
    }
    const restored = await CrawlerSession.reauthenticateAcademic();
    if (!restored) {
      AppSessionState.expire();
      return first;
    }
    const retry = await this.requestOnce(url);
    if (!retry.isSuccess && retry.error?.kind === AppErrorKind.AUTHENTICATION) AppSessionState.expire();
    else if (retry.isSuccess) AppSessionState.activate();
    return retry;
  }

  async postText(url: string, body: string): Promise<AppResult<string>> {
    const first = await this.requestOnce(url, http.RequestMethod.POST, body);
    if (first.isSuccess || first.error?.kind !== AppErrorKind.AUTHENTICATION) {
      return first;
    }
    const restored = await CrawlerSession.reauthenticateAcademic();
    if (!restored) {
      AppSessionState.expire();
      return first;
    }
    const retry = await this.requestOnce(url, http.RequestMethod.POST, body);
    if (!retry.isSuccess && retry.error?.kind === AppErrorKind.AUTHENTICATION) AppSessionState.expire();
    else if (retry.isSuccess) AppSessionState.activate();
    return retry;
  }

  async getJson<T>(url: string): Promise<AppResult<T>> {
    const result = await this.getText(url);
    if (!result.isSuccess || result.data === undefined) {
      return AppResults.failure<T>(
        result.error?.kind ?? AppErrorKind.UNKNOWN,
        result.error?.message ?? '教务请求失败',
        result.error?.code
      );
    }
    try {
      return AppResults.success<T>(JSON.parse(result.data) as T);
    } catch (_) {
      return AppResults.failure<T>(AppErrorKind.PARSE, '教务数据解析失败');
    }
  }


  async postJson<T>(url: string, body: string): Promise<AppResult<T>> {
    const result = await this.postText(url, body);
    if (!result.isSuccess || result.data === undefined) {
      return AppResults.failure<T>(result.error?.kind ?? AppErrorKind.UNKNOWN,
        result.error?.message ?? '教务请求失败', result.error?.code);
    }
    try {
      return AppResults.success<T>(JSON.parse(result.data) as T);
    } catch (_) {
      return AppResults.failure<T>(AppErrorKind.PARSE, '教务数据解析失败');
    }
  }
}
