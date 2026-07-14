import { AppErrorKind, AppResult, AppResults } from 'core_common';
import { AhuCache } from 'core_datastore';
import { CampusItem, LostFoundItem, LostFoundPublishRequest, LostFoundResponse, LostFoundType } from 'core_model';
import { PortalCrawlerClient } from 'data_crawler';

export class LostFoundRepository {
  private readonly client: PortalCrawlerClient = new PortalCrawlerClient();

  currentUserId(): string { return AhuCache.getCurrentUser()?.xh ?? ''; }

  private mockFailure<T>(): AppResult<T> | undefined {
    if (!AhuCache.getMockData()) return undefined;
    if (AhuCache.getMockScenario() === 'network_error')
      return AppResults.failure<T>(AppErrorKind.HTTP, 'Mock 场景：接口返回 500', 500);
    if (AhuCache.getMockScenario() === 'expired_login')
      return AppResults.failure<T>(AppErrorKind.AUTHENTICATION, 'Mock 场景：登录状态已过期', 401);
    return undefined;
  }

  private mockPage(page: number, pageSize: number, state: number): LostFoundResponse {
    const all = AhuCache.getLostFoundList(state);
    const start = Math.max(0, (page - 1) * pageSize);
    const list = all.slice(start, start + pageSize);
    return { code: 0, msg: 'mock', object: { pageNum: page, pageSize: pageSize, size: list.length,
      startRow: list.length > 0 ? start + 1 : 0, endRow: start + list.length, total: all.length,
      pages: Math.max(1, Math.ceil(all.length / pageSize)), list: list } };
  }

  async getList(page: number, pageSize: number, state: number): Promise<AppResult<LostFoundResponse>> {
    const failure = this.mockFailure<LostFoundResponse>(); if (failure) return failure;
    if (AhuCache.getMockData()) return AppResults.success<LostFoundResponse>(this.mockPage(page, pageSize, state));
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
    const failure = this.mockFailure<Array<CampusItem>>(); if (failure) return failure;
    if (AhuCache.getMockData()) return AppResults.success<Array<CampusItem>>([
      { id: '1', campusName: '磬苑校区', campusOrder: 1, createTime: '', createUser: 'mock' },
      { id: '2', campusName: '龙河校区', campusOrder: 2, createTime: '', createUser: 'mock' }
    ]);
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
    const failure = this.mockFailure<Array<LostFoundType>>(); if (failure) return failure;
    if (AhuCache.getMockData()) return AppResults.success<Array<LostFoundType>>([
      { typeId: '1', typeName: '其他', typeState: '1' },
      { typeId: '2', typeName: '校园卡', typeState: '1' },
      { typeId: '3', typeName: '电子产品', typeState: '1' }
    ]);
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
    const failure = this.mockFailure<boolean>(); if (failure) return failure;
    if (AhuCache.getMockData()) {
      const state = Number.parseInt(request.state, 10);
      const item: LostFoundItem = { id: `mock-published-${Date.now()}`, title: request.title,
        phone: request.phone, linkman: request.linkman, state: state, typeid: request.typeid,
        campusid: request.campusid, num1: request.num1, campusName: request.campusid === '2' ? '龙河校区' : '磬苑校区',
        createtime: new Date().toISOString(), imgs: [], pubuser: { idNumber: this.currentUserId(), userName: 'Mock 同学' },
        lostType: { typeId: request.typeid, typeName: 'Mock 分类', typeState: '1' } };
      AhuCache.saveLostFoundList(state, [item].concat(AhuCache.getLostFoundList(state)));
      return AppResults.success<boolean>(true);
    }
    const result = await this.client.postJson<PortalActionResponse>('https://adwmh.ahu.edu.cn/lostfound/saveupdate',
      JSON.stringify(request));
    if (result.isSuccess && result.data && result.data.code === 0) return AppResults.success<boolean>(true);
    return AppResults.failure<boolean>(result.error?.kind ?? AppErrorKind.HTTP,
      result.data?.msg ?? result.error?.message ?? '发布失败', result.data?.code ?? result.error?.code);
  }

  async delete(id: string): Promise<AppResult<boolean>> {
    const failure = this.mockFailure<boolean>(); if (failure) return failure;
    if (AhuCache.getMockData()) {
      AhuCache.saveLostFoundList(1, AhuCache.getLostFoundList(1).filter((item: LostFoundItem) => item.id !== id));
      AhuCache.saveLostFoundList(2, AhuCache.getLostFoundList(2).filter((item: LostFoundItem) => item.id !== id));
      return AppResults.success<boolean>(true);
    }
    const result = await this.client.postForm<PortalActionResponse>('https://adwmh.ahu.edu.cn/lostfound/delete',
      `id=${encodeURIComponent(id)}`);
    if (result.isSuccess && result.data && result.data.code === 0) {
      AhuCache.saveLostFoundList(1, AhuCache.getLostFoundList(1).filter((item: LostFoundItem) => item.id !== id));
      AhuCache.saveLostFoundList(2, AhuCache.getLostFoundList(2).filter((item: LostFoundItem) => item.id !== id));
      return AppResults.success<boolean>(true);
    }
    return AppResults.failure<boolean>(result.error?.kind ?? AppErrorKind.HTTP,
      result.data?.msg ?? result.error?.message ?? '删除失败', result.data?.code ?? result.error?.code);
  }
}

interface PortalListResponse<T> { code: number; msg: string; object: Array<T>; }
interface PortalActionResponse { code: number; msg?: string; data?: Object; }

export class LostFoundRepositoryProvider {
  private static readonly repository: LostFoundRepository = new LostFoundRepository();
  static get(): LostFoundRepository { return LostFoundRepositoryProvider.repository; }
}
