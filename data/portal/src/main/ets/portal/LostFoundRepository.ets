import { AppErrorKind, AppResult, AppResults } from 'core_common';
import { AhuCache } from 'core_datastore';
import { CampusItem, LostFoundItem, LostFoundPublishRequest, LostFoundResponse, LostFoundType } from 'core_model';
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

  async getCampuses(): Promise<AppResult<Array<CampusItem>>> {
    const result = await this.client.getJson<PortalListResponse<CampusItem>>('https://adwmh.ahu.edu.cn/lostfound/campus/all');
    if (result.isSuccess && result.data && result.data.code === 0) {
      AhuCache.saveLostFoundCampuses(result.data.object);
      return AppResults.success<Array<CampusItem>>(result.data.object);
    }
    const cached = AhuCache.getLostFoundCampuses();
    if (cached.length > 0) return AppResults.success<Array<CampusItem>>(cached);
    return AppResults.failure<Array<CampusItem>>(result.error?.kind ?? AppErrorKind.HTTP,
      result.data?.msg ?? result.error?.message ?? '获取校区失败', result.data?.code ?? result.error?.code);
  }

  async getTypes(): Promise<AppResult<Array<LostFoundType>>> {
    const result = await this.client.getJson<PortalListResponse<LostFoundType>>('https://adwmh.ahu.edu.cn/lostfound/type/all');
    if (result.isSuccess && result.data && result.data.code === 0) {
      AhuCache.saveLostFoundTypes(result.data.object);
      return AppResults.success<Array<LostFoundType>>(result.data.object);
    }
    const cached = AhuCache.getLostFoundTypes();
    if (cached.length > 0) return AppResults.success<Array<LostFoundType>>(cached);
    return AppResults.failure<Array<LostFoundType>>(result.error?.kind ?? AppErrorKind.HTTP,
      result.data?.msg ?? result.error?.message ?? '获取物品类型失败', result.data?.code ?? result.error?.code);
  }

  async publish(request: LostFoundPublishRequest): Promise<AppResult<boolean>> {
    const result = await this.client.postJson<PortalActionResponse>('https://adwmh.ahu.edu.cn/lostfound/saveupdate',
      JSON.stringify(request));
    if (result.isSuccess && result.data && result.data.code === 0) return AppResults.success<boolean>(true);
    return AppResults.failure<boolean>(result.error?.kind ?? AppErrorKind.HTTP,
      result.data?.msg ?? result.error?.message ?? '发布失败', result.data?.code ?? result.error?.code);
  }
}

interface PortalListResponse<T> { code: number; msg: string; object: Array<T>; }
interface PortalActionResponse { code: number; msg?: string; data?: Object; }

export class LostFoundRepositoryProvider {
  private static readonly repository: LostFoundRepository = new LostFoundRepository();
  static get(): LostFoundRepository { return LostFoundRepositoryProvider.repository; }
}
