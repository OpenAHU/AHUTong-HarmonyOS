import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { AhuCache } from 'core_datastore';
import { AuthRepositoryProvider } from 'data_auth';

export class AppMaintenance {
  static async logout(context: common.Context, clearAll: boolean): Promise<void> {
    await AuthRepositoryProvider.get().logout();
    if (!clearAll) return;
    const downloadDir = `${context.filesDir}/repository`;
    try {
      fs.listFileSync(downloadDir).forEach((name: string) => {
        try { fs.unlinkSync(`${downloadDir}/${name}`); } catch (_) {}
      });
      fs.rmdirSync(downloadDir);
    } catch (_) {}
    AhuCache.clearAll();
  }
}
