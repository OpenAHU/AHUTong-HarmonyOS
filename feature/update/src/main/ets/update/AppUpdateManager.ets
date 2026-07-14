import { bundleManager } from '@kit.AbilityKit';
import { common } from '@kit.AbilityKit';
import { AhuHttpClient } from 'core_network';
import { isVersionNewer } from './VersionComparator';

const LATEST_RELEASE_API: string = 'https://api.github.com/repos/OpenAHU/AHUTong-HarmonyOS/releases/latest';
const RELEASES_PAGE: string = 'https://github.com/OpenAHU/AHUTong-HarmonyOS/releases';
const APP_GALLERY_URI: string = 'appmarket://details?id=com.openahu.ahutong';
const FORCE_MARKER: string = '<!-- ahutong-force-update -->';

interface GitHubRelease {
  tag_name?: string;
  name?: string;
  body?: string;
  html_url?: string;
  draft?: boolean;
  prerelease?: boolean;
}

export interface AppUpdateInfo {
  versionName: string;
  title: string;
  changelog: string;
  releaseUrl: string;
  force: boolean;
}

export enum AppUpdateStatus {
  AVAILABLE = 'available',
  CURRENT = 'current',
  FAILED = 'failed'
}

export interface AppUpdateCheckResult {
  status: AppUpdateStatus;
  message: string;
  currentVersion: string;
  update?: AppUpdateInfo;
}

export class AppUpdateManager {
  private static readonly client: AhuHttpClient = new AhuHttpClient();

  static isVersionNewer(remote: string, current: string): boolean {
    return isVersionNewer(remote, current);
  }

  static currentVersion(): string {
    try {
      return bundleManager.getBundleInfoForSelfSync(0).versionName;
    } catch (_) {
      return '1.0.0';
    }
  }

  static async check(): Promise<AppUpdateCheckResult> {
    const currentVersion = AppUpdateManager.currentVersion();
    const response = await AppUpdateManager.client.request<GitHubRelease>({
      url: LATEST_RELEASE_API,
      headers: {
        'Accept': 'application/vnd.github+json',
        'User-Agent': `AHUTong/${currentVersion} (HarmonyOS)`,
        'X-GitHub-Api-Version': '2022-11-28'
      },
      connectTimeout: 10_000,
      readTimeout: 15_000
    });
    if (!response.isSuccess || !response.data) {
      if (response.error?.code === 404) {
        return { status: AppUpdateStatus.CURRENT, message: '已是最新版本', currentVersion: currentVersion };
      }
      return {
        status: AppUpdateStatus.FAILED,
        message: `检查更新失败：${response.error?.message ?? '网络请求失败'}`,
        currentVersion: currentVersion
      };
    }

    const release = response.data;
    const remoteVersion = release.tag_name?.trim() ?? '';
    if (release.draft || release.prerelease || !AppUpdateManager.isVersionNewer(remoteVersion, currentVersion)) {
      return { status: AppUpdateStatus.CURRENT, message: '已是最新版本', currentVersion: currentVersion };
    }
    const releaseUrl = release.html_url?.trim() ?? '';
    if (!releaseUrl.startsWith('https://github.com/OpenAHU/AHUTong-HarmonyOS/releases/')) {
      return { status: AppUpdateStatus.FAILED, message: '更新信息中的发行地址无效', currentVersion: currentVersion };
    }
    const changelog = release.body?.replace(FORCE_MARKER, '').trim() ?? '';
    return {
      status: AppUpdateStatus.AVAILABLE,
      message: `发现新版本 ${remoteVersion.replace(/^[vV]/, '')}`,
      currentVersion: currentVersion,
      update: {
        versionName: remoteVersion.replace(/^[vV]/, ''),
        title: release.name?.trim() || `安大通 ${remoteVersion}`,
        changelog: changelog.length > 0 ? changelog : '本次更新暂无详细说明。',
        releaseUrl: releaseUrl,
        force: (release.body ?? '').includes(FORCE_MARKER)
      }
    };
  }

  static async introduction(): Promise<string> {
    const currentVersion = AppUpdateManager.currentVersion();
    const response = await AppUpdateManager.client.request<GitHubRelease>({
      url: LATEST_RELEASE_API,
      headers: { 'Accept': 'application/vnd.github+json', 'User-Agent': `AHUTong/${currentVersion} (HarmonyOS)`,
        'X-GitHub-Api-Version': '2022-11-28' },
      connectTimeout: 10_000, readTimeout: 15_000
    });
    if (response.error?.code === 404) {
      return `当前版本：${currentVersion}\n\nHarmonyOS 迁移版尚未发布首个 GitHub Release，当前为开发构建。`;
    }
    if (!response.isSuccess || !response.data) {
      throw new Error(response.error?.message ?? '获取更新介绍失败');
    }
    const release = response.data;
    const version = release.tag_name?.replace(/^[vV]/, '') ?? currentVersion;
    const body = release.body?.replace(FORCE_MARKER, '').trim() ?? '';
    return `${release.name?.trim() || `安大通 ${version}`}\n版本：${version}\n\n${body.length > 0 ? body : '本次更新暂无详细说明。'}`;
  }

  static async openAppGallery(context: common.UIAbilityContext): Promise<boolean> {
    try {
      await context.startAbility({ action: 'ohos.want.action.viewData', uri: APP_GALLERY_URI });
      return true;
    } catch (_) {
      return false;
    }
  }

  static async openReleasePage(context: common.UIAbilityContext, info?: AppUpdateInfo): Promise<boolean> {
    const url = info?.releaseUrl ?? RELEASES_PAGE;
    if (!url.startsWith('https://github.com/OpenAHU/AHUTong-HarmonyOS/releases')) return false;
    try {
      await context.startAbility({ action: 'ohos.want.action.viewData', uri: url });
      return true;
    } catch (_) {
      return false;
    }
  }
}
