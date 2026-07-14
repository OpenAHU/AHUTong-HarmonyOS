import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppErrorKind, AppResult, AppResults } from 'core_common';
import { CrawlerSession } from './CrawlerSession';

export class PortalCrawlerClient {
  private async requestOnce(url: string, method: http.RequestMethod = http.RequestMethod.GET,
    body?: string, contentType?: string): Promise<AppResult<string>> {
    const request = http.createHttp();
    try {
      const headers: Record<string, string> = { 'Accept': 'application/json', 'User-Agent': 'AHUTong/1.0 (HarmonyOS)', 'X-Requested-With': 'XMLHttpRequest' };
      const cookie = CrawlerSession.portalCookies.header();
      if (cookie.length > 0) headers['Cookie'] = cookie;
      if (contentType) headers['Content-Type'] = contentType;
      const response = await request.request(url, { method: method, header: headers, extraData: body,
        expectDataType: http.HttpDataType.STRING, connectTimeout: 15_000, readTimeout: 30_000, usingCache: false, maxRedirects: 10 });
      CrawlerSession.portalCookies.save(response.cookies);
      const status = response.responseCode as number;
      const responseBody = response.result as string;
      if (status === 401 || status === 403 || /\/user\/login|name=["']imgcode["']/i.test(responseBody))
        return AppResults.failure<string>(AppErrorKind.AUTHENTICATION, '门户登录状态已失效', status);
      if (status < 200 || status >= 300) return AppResults.failure<string>(AppErrorKind.HTTP, `门户请求失败（${status}）`, status);
      return AppResults.success<string>(responseBody);
    } catch (error) {
      const failure = error as BusinessError;
      return AppResults.failure<string>(AppErrorKind.TRANSPORT, failure.message ?? '门户网络请求失败', failure.code);
    } finally { request.destroy(); }
  }

  async getJson<T>(url: string): Promise<AppResult<T>> {
    let result = await this.requestOnce(url);
    if (!result.isSuccess && result.error?.kind === AppErrorKind.AUTHENTICATION && await CrawlerSession.reauthenticatePortal())
      result = await this.requestOnce(url);
    if (!result.isSuccess || result.data === undefined)
      return AppResults.failure<T>(result.error?.kind ?? AppErrorKind.UNKNOWN, result.error?.message ?? '门户请求失败', result.error?.code);
    try { return AppResults.success<T>(JSON.parse(result.data) as T); }
    catch (_) { return AppResults.failure<T>(AppErrorKind.PARSE, '门户数据解析失败'); }
  }

  async postJson<T>(url: string, body: string): Promise<AppResult<T>> {
    let result = await this.requestOnce(url, http.RequestMethod.POST, body, 'application/json; charset=UTF-8');
    if (!result.isSuccess && result.error?.kind === AppErrorKind.AUTHENTICATION && await CrawlerSession.reauthenticatePortal())
      result = await this.requestOnce(url, http.RequestMethod.POST, body, 'application/json; charset=UTF-8');
    if (!result.isSuccess || result.data === undefined)
      return AppResults.failure<T>(result.error?.kind ?? AppErrorKind.UNKNOWN, result.error?.message ?? '门户请求失败', result.error?.code);
    try { return AppResults.success<T>(JSON.parse(result.data) as T); }
    catch (_) { return AppResults.failure<T>(AppErrorKind.PARSE, '门户数据解析失败'); }
  }
}
