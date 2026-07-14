import { AppErrorKind, AppResult, AppResults } from 'core_common';
import { AhuCache } from 'core_datastore';
import { Card } from 'core_model';
import { PortalCrawlerClient } from 'data_crawler';

interface BalanceResponse { code: number; msg?: string; object?: number; }
interface QrcodeResponse { code: number; msg?: string; object?: string; }
export interface CampusCardRepository {
  getBalance(refresh?: boolean): Promise<AppResult<Card>>;
  getQrcode(): Promise<AppResult<string>>;
}
export class DefaultCampusCardRepository implements CampusCardRepository {
  private readonly client: PortalCrawlerClient;
  constructor(client: PortalCrawlerClient = new PortalCrawlerClient()) { this.client = client; }
  async getBalance(refresh: boolean = false): Promise<AppResult<Card>> {
    if (AhuCache.getMockData()) {
      const scenario = AhuCache.getMockScenario();
      if (scenario === 'network_error') return AppResults.failure<Card>(AppErrorKind.HTTP, 'Mock 场景：接口返回 500', 500);
      if (scenario === 'expired_login') return AppResults.failure<Card>(AppErrorKind.AUTHENTICATION, 'Mock 场景：登录状态已过期', 401);
      return AppResults.success<Card>({ balance: AhuCache.getCardBalance() ?? 0, transitionBalance: 0 });
    }
    if (!refresh) {
      const cached = AhuCache.getCardBalance();
      if (cached !== undefined) return AppResults.success<Card>({ balance: cached, transitionBalance: 0 });
    }
    const result = await this.client.getJson<BalanceResponse>('https://adwmh.ahu.edu.cn/xzxcard/yue');
    if (!result.isSuccess || !result.data)
      return AppResults.failure<Card>(result.error?.kind ?? AppErrorKind.UNKNOWN, result.error?.message ?? '获取校园卡余额失败', result.error?.code);
    if (result.data.object === undefined)
      return AppResults.failure<Card>(AppErrorKind.AUTHENTICATION, result.data.msg ?? '校园卡余额不可用', result.data.code);
    AhuCache.saveCardBalance(result.data.object);
    return AppResults.success<Card>({ balance: result.data.object, transitionBalance: 0 });
  }

  async getQrcode(): Promise<AppResult<string>> {
    if (AhuCache.getMockData()) {
      const scenario = AhuCache.getMockScenario();
      if (scenario === 'network_error') return AppResults.failure<string>(AppErrorKind.HTTP, 'Mock 场景：接口返回 500', 500);
      if (scenario === 'expired_login') return AppResults.failure<string>(AppErrorKind.AUTHENTICATION, 'Mock 场景：登录状态已过期', 401);
      return AppResults.success<string>('AHUTONG-MOCK-CAMPUS-CODE-2022000000');
    }
    const result = await this.client.getJson<QrcodeResponse>('https://adwmh.ahu.edu.cn/xzxcard/qrcode');
    if (!result.isSuccess || !result.data) {
      return AppResults.failure<string>(result.error?.kind ?? AppErrorKind.UNKNOWN,
        result.error?.message ?? '获取校园码失败', result.error?.code);
    }
    const payload = result.data.object ?? '';
    if (result.data.code !== 10000 || payload.length === 0) {
      return AppResults.failure<string>(AppErrorKind.HTTP, result.data.msg ?? '校园码不可用', result.data.code);
    }
    return AppResults.success<string>(payload);
  }
}
export class CampusCardRepositoryProvider {
  private static readonly repository: CampusCardRepository = new DefaultCampusCardRepository();
  static get(): CampusCardRepository { return CampusCardRepositoryProvider.repository; }
}
