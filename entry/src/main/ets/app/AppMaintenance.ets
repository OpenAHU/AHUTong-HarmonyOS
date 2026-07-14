import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { AhuCache } from 'core_datastore';
import { AuthRepositoryProvider } from 'data_auth';

export class AppMaintenance {
  private static removeDirectory(filesDir: string, directoryName: string): void {
    const root = filesDir.endsWith('/') ? filesDir.substring(0, filesDir.length - 1) : filesDir;
    const target = `${root}/${directoryName}`;
    if (directoryName.length === 0 || directoryName.includes('/') || directoryName.includes('\\')) return;
    try {
      fs.listFileSync(target).forEach((name: string) => {
        const child = `${target}/${name}`;
        try {
          if (fs.statSync(child).isDirectory()) AppMaintenance.removeTree(root, child);
          else fs.unlinkSync(child);
        } catch (_) {}
      });
      fs.rmdirSync(target);
    } catch (_) {}
  }

  private static removeTree(root: string, target: string): void {
    if (!target.startsWith(`${root}/`) || target === root) return;
    try {
      fs.listFileSync(target).forEach((name: string) => {
        const child = `${target}/${name}`;
        try {
          if (fs.statSync(child).isDirectory()) AppMaintenance.removeTree(root, child);
          else fs.unlinkSync(child);
        } catch (_) {}
      });
      fs.rmdirSync(target);
    } catch (_) {}
  }

  static async logout(context: common.Context, clearAll: boolean): Promise<void> {
    await AuthRepositoryProvider.get().logout();
    if (!clearAll) return;
    AppMaintenance.removeDirectory(context.filesDir, 'repository');
    AppMaintenance.removeDirectory(context.filesDir, 'images');
    AhuCache.clearAll();
  }
}
