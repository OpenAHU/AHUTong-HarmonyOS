import { common } from '@kit.AbilityKit';
import { fileIo as fs, fileUri } from '@kit.CoreFileKit';
import { http } from '@kit.NetworkKit';

const CALENDAR_URL: string = 'https://openahu.org/download/xiaoli.jpg';

export interface SchoolCalendarImage {
  path: string;
  uri: string;
  fromCache: boolean;
}

export class SchoolCalendarRepository {
  private static targetPath(context: common.UIAbilityContext): string {
    const directory = `${context.filesDir}/images`;
    try { fs.mkdirSync(directory, true); } catch (_) {}
    return `${directory}/xiaoli.jpg`;
  }

  private static valid(path: string): boolean {
    try { return fs.statSync(path).size > 0; } catch (_) { return false; }
  }

  static async getCalendarImage(context: common.UIAbilityContext, forceRefresh: boolean = false): Promise<SchoolCalendarImage> {
    const path = SchoolCalendarRepository.targetPath(context);
    if (!forceRefresh && SchoolCalendarRepository.valid(path)) {
      return { path: path, uri: fileUri.getUriFromPath(path), fromCache: true };
    }
    const request = http.createHttp();
    const tempPath = `${path}.download`;
    try {
      const response = await request.request(CALENDAR_URL, { method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER, connectTimeout: 10_000, readTimeout: 30_000 });
      const code = response.responseCode as number;
      if (code < 200 || code >= 300) throw new Error(`下载校历失败（${code}）`);
      const file = fs.openSync(tempPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
      try { fs.writeSync(file.fd, response.result as ArrayBuffer); } finally { fs.closeSync(file); }
      if (!SchoolCalendarRepository.valid(tempPath)) throw new Error('下载的校历文件为空');
      try { fs.unlinkSync(path); } catch (_) {}
      fs.renameSync(tempPath, path);
      return { path: path, uri: fileUri.getUriFromPath(path), fromCache: false };
    } catch (error) {
      try { fs.unlinkSync(tempPath); } catch (_) {}
      if (SchoolCalendarRepository.valid(path)) {
        return { path: path, uri: fileUri.getUriFromPath(path), fromCache: true };
      }
      throw new Error((error as Error).message ?? '获取校历失败');
    } finally { request.destroy(); }
  }
}
