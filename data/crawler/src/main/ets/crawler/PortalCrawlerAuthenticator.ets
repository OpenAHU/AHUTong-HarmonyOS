import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppErrorKind, AppResult, AppResults } from 'core_common';
import { User } from 'core_model';
import { CasAuthenticator } from './CasAuthenticator';
import { CrawlerSession } from './CrawlerSession';

interface OcrResponse {
  result: string;
  error?: string;
}

interface PortalUser {
  userName: string;
  idNumber: string;
}

interface PortalLoginObject {
  user: PortalUser;
}

interface PortalLoginResponse {
  code: number;
  msg: string;
  object?: PortalLoginObject;
}

export interface CrawlerAuthenticator {
  login(username: string, password: string): Promise<AppResult<User>>;
  clearSession(): void;
}

export class PortalCrawlerAuthenticator implements CrawlerAuthenticator {
  private static readonly CAPTCHA_URL: string = 'https://adwmh.ahu.edu.cn/remind/authcode';
  private static readonly OCR_URL: string = 'https://openahu.org/ocr/captcha';
  private static readonly LOGIN_URL: string = 'https://adwmh.ahu.edu.cn/user/login';
  private readonly casAuthenticator: CasAuthenticator = new CasAuthenticator();

  private mergeCookie(responseCookies: string): void {
    CrawlerSession.portalCookies.save(responseCookies);
  }

  private headers(contentType?: string): Record<string, string> {
    const headers: Record<string, string> = {
      'Accept': '*/*',
      'User-Agent': 'AHUTong/1.0 (HarmonyOS)',
      'X-Requested-With': 'XMLHttpRequest'
    };
    if (contentType) {
      headers['Content-Type'] = contentType;
    }
    const cookie = CrawlerSession.portalCookies.header();
    if (cookie.length > 0) {
      headers['Cookie'] = cookie;
    }
    return headers;
  }

  private async fetchCaptcha(): Promise<AppResult<ArrayBuffer>> {
    const request = http.createHttp();
    try {
      const response = await request.request(PortalCrawlerAuthenticator.CAPTCHA_URL, {
        method: http.RequestMethod.GET,
        header: this.headers(),
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 15_000,
        readTimeout: 30_000,
        usingCache: false
      });
      this.mergeCookie(response.cookies);
      if (response.responseCode !== 200 || !(response.result instanceof ArrayBuffer)) {
        return AppResults.failure<ArrayBuffer>(AppErrorKind.HTTP, `验证码获取失败（${response.responseCode}）`);
      }
      return AppResults.success<ArrayBuffer>(response.result);
    } catch (error) {
      const businessError = error as BusinessError;
      return AppResults.failure<ArrayBuffer>(AppErrorKind.TRANSPORT, businessError.message ?? '验证码获取失败');
    } finally {
      request.destroy();
    }
  }

  private async recognizeCaptcha(image: ArrayBuffer): Promise<AppResult<string>> {
    const request = http.createHttp();
    try {
      const response = await request.request(PortalCrawlerAuthenticator.OCR_URL, {
        method: http.RequestMethod.POST,
        header: {
          'Accept': 'application/json',
          'User-Agent': 'AHUTong/1.0 (HarmonyOS)'
        },
        multiFormDataList: [{
          name: 'captcha',
          contentType: 'image/jpeg',
          remoteFileName: 'img.jpg',
          data: image
        }],
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 20_000,
        readTimeout: 30_000,
        usingCache: false
      });
      if (response.responseCode !== 200) {
        return AppResults.failure<string>(AppErrorKind.HTTP, `验证码识别失败（${response.responseCode}）`);
      }
      const parsed = JSON.parse(response.result as string) as OcrResponse;
      if (!parsed.result || parsed.result.trim().length === 0) {
        return AppResults.failure<string>(AppErrorKind.PARSE, parsed.error ?? '验证码识别失败');
      }
      return AppResults.success<string>(parsed.result.trim());
    } catch (error) {
      const businessError = error as BusinessError;
      return AppResults.failure<string>(AppErrorKind.TRANSPORT, businessError.message ?? '验证码识别失败');
    } finally {
      request.destroy();
    }
  }

  private async portalLogin(username: string, password: string, captcha: string): Promise<AppResult<User>> {
    const request = http.createHttp();
    const body = `username=${encodeURIComponent(username)}` +
      `&pwd=${encodeURIComponent(password)}` +
      `&flag=0&imgcode=${encodeURIComponent(captcha)}`;
    try {
      const response = await request.request(PortalCrawlerAuthenticator.LOGIN_URL, {
        method: http.RequestMethod.POST,
        header: this.headers('application/x-www-form-urlencoded; charset=UTF-8'),
        extraData: body,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15_000,
        readTimeout: 30_000,
        usingCache: false
      });
      this.mergeCookie(response.cookies);
      if (response.responseCode < 200 || response.responseCode >= 300) {
        return AppResults.failure<User>(AppErrorKind.HTTP, `登录请求失败（${response.responseCode}）`);
      }
      const parsed = JSON.parse(response.result as string) as PortalLoginResponse;
      if (parsed.code !== 10000 || !parsed.object) {
        return AppResults.failure<User>(AppErrorKind.AUTHENTICATION, parsed.msg || '账号、密码或验证码错误');
      }
      return AppResults.success<User>({
        name: parsed.object.user.userName,
        xh: parsed.object.user.idNumber
      });
    } catch (error) {
      const businessError = error as BusinessError;
      return AppResults.failure<User>(AppErrorKind.TRANSPORT, businessError.message ?? '登录请求失败');
    } finally {
      request.destroy();
    }
  }

  async login(username: string, password: string): Promise<AppResult<User>> {
    let lastError: AppResult<User> = AppResults.failure<User>(AppErrorKind.AUTHENTICATION, '登录失败');
    for (let attempt = 0; attempt < 5; attempt++) {
      const image = await this.fetchCaptcha();
      if (!image.isSuccess || !image.data) {
        return AppResults.failure<User>(image.error?.kind ?? AppErrorKind.UNKNOWN,
          image.error?.message ?? '验证码获取失败', image.error?.code);
      }
      const captcha = await this.recognizeCaptcha(image.data);
      if (!captcha.isSuccess || !captcha.data) {
        lastError = AppResults.failure<User>(captcha.error?.kind ?? AppErrorKind.UNKNOWN,
          captcha.error?.message ?? '验证码识别失败', captcha.error?.code);
        continue;
      }
      const result = await this.portalLogin(username, password, captcha.data);
      if (result.isSuccess) {
        const casResult = await this.casAuthenticator.login(username, password);
        if (casResult.isSuccess) {
          return result;
        }
        return AppResults.failure<User>(casResult.error?.kind ?? AppErrorKind.AUTHENTICATION,
          casResult.error?.message ?? '智慧安大认证失败', casResult.error?.code);
      }
      lastError = result;
    }
    return lastError;
  }

  clearSession(): void {
    CrawlerSession.clearAll();
  }
}
