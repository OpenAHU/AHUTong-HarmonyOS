import { common } from '@kit.AbilityKit';
import { fileIo as fs, fileUri } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { http } from '@kit.NetworkKit';

export class CalendarImageSaver {
  static async saveLocal(context: common.UIAbilityContext, path: string): Promise<void> {
    try {
      const helper = photoAccessHelper.getPhotoAccessHelper(context);
      const config: photoAccessHelper.PhotoCreationConfig = { title: '安大通校历', fileNameExtension: 'jpg',
        photoType: photoAccessHelper.PhotoType.IMAGE };
      await helper.showAssetsCreationDialog([fileUri.getUriFromPath(path)], [config]);
    } catch (error) { throw new Error((error as Error).message ?? '校历保存失败'); }
  }

  static async save(context: common.UIAbilityContext, url: string): Promise<void> {
    const request = http.createHttp();
    const path = `${context.cacheDir}/ahu_school_calendar.jpg`;
    try {
      const response = await request.request(url, { method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER, connectTimeout: 10_000, readTimeout: 30_000 });
      const code = response.responseCode as number;
      if (code < 200 || code >= 300) throw new Error(`校历下载失败（${code}）`);
      const file = fs.openSync(path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
      try { fs.writeSync(file.fd, response.result as ArrayBuffer); }
      catch (error) { throw new Error((error as Error).message ?? '校历缓存写入失败'); }
      finally { fs.closeSync(file); }
      await CalendarImageSaver.saveLocal(context, path);
    } catch (error) {
      throw new Error((error as Error).message ?? '校历保存失败');
    } finally {
      request.destroy();
    }
  }
}
