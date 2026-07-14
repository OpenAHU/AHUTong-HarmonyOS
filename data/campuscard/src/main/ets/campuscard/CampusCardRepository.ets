import { AppErrorKind, AppResult, AppResults } from 'core_common';
import { AhuCache } from 'core_datastore';
import { Card } from 'core_model';
import { PortalCrawlerClient } from 'data_crawler';

interface BalanceResponse { code: number; msg?: string; object?: number; }
export interface CampusCardRepository { getBalance(refresh?: boolean): Promise<AppResult<Card>>; }
export class DefaultCampusCardRepository implements CampusCardRepository {
  private readonly client: PortalCrawlerClient;
  constructor(client: PortalCrawlerClient = new PortalCrawlerClient()) { this.client = client; }
  async getBalance(refresh: boolean = false): Promise<AppResult<Card>> {
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
}
export class CampusCardRepositoryProvider {
  private static readonly repository: CampusCardRepository = new DefaultCampusCardRepository();
  static get(): CampusCardRepository { return CampusCardRepositoryProvider.repository; }
}
