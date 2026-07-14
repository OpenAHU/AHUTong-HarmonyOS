import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppErrorKind, AppResult, AppResults } from 'core_common';
import { CrawlerSession } from './CrawlerSession';
import { LegacyCasCipher } from './LegacyCasCipher';

export class CasAuthenticator {
  private static readonly LOGIN_PAGE_URL: string = 'https://jw.ahu.edu.cn/student/sso/login';
  private static readonly DEVICE_URL: string = 'https://one.ahu.edu.cn/cas/device';
  private static readonly LOGIN_URL: string = 'https://one.ahu.edu.cn/cas/login' +
    '?service=https%3A%2F%2Fjw.ahu.edu.cn%2Fstudent%2Fsso%2Flogin';
  private static readonly HOME_URL: string = 'https://jw.ahu.edu.cn/student/home';

  private headers(contentType?: string): Record<string, string> {
    const headers: Record<string, string> = {
      'Accept': '*/*',
      'User-Agent': 'AHUTong/1.0 (HarmonyOS)'
    };
    const cookie = CrawlerSession.academicCookies.header();
    if (cookie.length > 0) {
      headers['Cookie'] = cookie;
    }
    if (contentType) {
      headers['Content-Type'] = contentType;
    }
    return headers;
  }

  private extractLoginToken(html: string): string | undefined {
    const nameFirst = html.match(/name=["']lt["'][^>]*value=["']([^"']+)["']/i);
    if (nameFirst && nameFirst.length > 1) {
      return nameFirst[1];
    }
    const valueFirst = html.match(/value=["']([^"']+)["'][^>]*name=["']lt["']/i);
    return valueFirst && valueFirst.length > 1 ? valueFirst[1] : undefined;
  }

  async login(username: string, password: string): Promise<AppResult<boolean>> {
    const request = http.createHttp();
    try {
      const loginPage = await request.request(CasAuthenticator.LOGIN_PAGE_URL, {
        method: http.RequestMethod.GET,
        header: this.headers(),
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15_000,
        readTimeout: 30_000,
        usingCache: false,
        maxRedirects: 10
      });
      CrawlerSession.academicCookies.save(loginPage.cookies);
      if (loginPage.responseCode < 200 || loginPage.responseCode >= 300) {
        return AppResults.failure<boolean>(AppErrorKind.HTTP, `教务登录页加载失败（${loginPage.responseCode}）`);
      }
      const token = this.extractLoginToken(loginPage.result as string);
      if (!token) {
        return AppResults.success<boolean>(true);
      }

      const cipher = LegacyCasCipher.encrypt(username + password + token);
      const deviceBody = `ul=${username.length}&pl=${password.length}` +
        `&rsa=${encodeURIComponent(cipher)}&method=login`;
      const device = await request.request(CasAuthenticator.DEVICE_URL, {
        method: http.RequestMethod.POST,
        header: this.headers('application/x-www-form-urlencoded; charset=UTF-8'),
        extraData: deviceBody,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15_000,
        readTimeout: 30_000,
        usingCache: false
      });
      CrawlerSession.academicCookies.save(device.cookies);
      if (device.responseCode < 200 || device.responseCode >= 300) {
        return AppResults.failure<boolean>(AppErrorKind.HTTP, `统一认证设备校验失败（${device.responseCode}）`);
      }

      const loginBody = `rsa=${encodeURIComponent(cipher)}` +
        `&ul=${username.length}&pl=${password.length}` +
        `&lt=${encodeURIComponent(token)}&execution=e1s1&_eventId=submit`;
      const login = await request.request(CasAuthenticator.LOGIN_URL, {
        method: http.RequestMethod.POST,
        header: this.headers('application/x-www-form-urlencoded; charset=UTF-8'),
        extraData: loginBody,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15_000,
        readTimeout: 30_000,
        usingCache: false,
        maxRedirects: 10
      });
      CrawlerSession.academicCookies.save(login.cookies);
      if (login.responseCode < 200 || login.responseCode >= 300) {
        return AppResults.failure<boolean>(AppErrorKind.AUTHENTICATION, '智慧安大认证失败');
      }

      const home = await request.request(CasAuthenticator.HOME_URL, {
        method: http.RequestMethod.GET,
        header: this.headers(),
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15_000,
        readTimeout: 30_000,
        usingCache: false,
        maxRedirects: 10
      });
      CrawlerSession.academicCookies.save(home.cookies);
      const body = home.result as string;
      if (home.responseCode < 200 || home.responseCode >= 300 || this.extractLoginToken(body)) {
        return AppResults.failure<boolean>(AppErrorKind.AUTHENTICATION, '智慧安大账号或密码错误');
      }
      return AppResults.success<boolean>(true);
    } catch (error) {
      const businessError = error as BusinessError;
      return AppResults.failure<boolean>(AppErrorKind.TRANSPORT, businessError.message ?? '智慧安大认证失败');
    } finally {
      request.destroy();
    }
  }
}
