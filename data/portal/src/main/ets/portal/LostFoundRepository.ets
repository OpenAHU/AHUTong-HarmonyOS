import { AppErrorKind, AppResult, AppResults } from 'core_common';
import { AhuCache } from 'core_datastore';
import { LostFoundItem, LostFoundResponse } from 'core_model';
import { PortalCrawlerClient } from 'data_crawler';

export class LostFoundRepository {
  private readonly client: PortalCrawlerClient = new PortalCrawlerClient();

  async getList(page: number, pageSize: number, state: number): Promise<AppResult<LostFoundResponse>> {
    const url = `https://adwmh.ahu.edu.cn/lostfound/all?pageNo=${page}&pageSize=${pageSize}&state=${state}`;
    const result = await this.client.getJson<LostFoundResponse>(url);
    if (result.isSuccess && result.data) {
      if (page === 1) AhuCache.saveLostFoundList(state, result.data.object.list);
      else AhuCache.saveLostFoundList(state, AhuCache.getLostFoundList(state).concat(result.data.object.list));
      return result;
    }
    const cached: Array<LostFoundItem> = AhuCache.getLostFoundList(state);
    if (page === 1 && cached.length > 0) {
      return AppResults.success<LostFoundResponse>({ code: 0, msg: 'cache', object: {
        pageNum: 1, pageSize: cached.length, size: cached.length, startRow: 1, endRow: cached.length,
        total: cached.length, pages: 1, list: cached
      } });
    }
    return AppResults.failure<LostFoundResponse>(result.error?.kind ?? AppErrorKind.UNKNOWN,
      result.error?.message ?? '获取失物招领失败', result.error?.code);
  }
}

export class LostFoundRepositoryProvider {
  private static readonly repository: LostFoundRepository = new LostFoundRepository();
  static get(): LostFoundRepository { return LostFoundRepositoryProvider.repository; }
}
