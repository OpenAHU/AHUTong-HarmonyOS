import { http } from '@kit.NetworkKit';
import { bundleManager } from '@kit.AbilityKit';
import { AhuCache, AhuPreferences } from 'core_datastore';
import { GrayRollout } from './GrayRollout';

const HOME_EDIT_KEY: string = 'home_edit';
const HOME_EDIT_FALLBACK: number = 0;

interface GrayDecision {
  enabled?: boolean;
  rolloutPercentage?: number;
  bucket?: number;
}

interface AppVersionInfo {
  code: number;
  name: string;
}

export enum GrayOverride {
  FOLLOW = 'follow',
  ENABLED = 'enabled',
  DISABLED = 'disabled'
}

export interface GrayFeatureState {
  key: string;
  title: string;
  description: string;
  override: GrayOverride;
  bucket: number;
  rolloutPercentage: number;
  enabled: boolean;
  source: string;
}

export class GrayReleaseManager {
  private static overrideKey(feature: string): string { return `gray_override:${feature}`; }

  private static subject(): string {
    const userId = AhuCache.getCurrentUser()?.xh.trim() ?? '';
    return GrayRollout.sha256Hex(userId.length > 0 ? `user:${userId}` : 'guest');
  }

  private static version(): AppVersionInfo {
    try {
      const info = bundleManager.getBundleInfoForSelfSync(0);
      return { code: info.versionCode, name: info.versionName };
    } catch (_) { return { code: 1_000_000, name: '1.0.0' }; }
  }

  static getOverride(): GrayOverride {
    const value = AhuPreferences.getString(GrayReleaseManager.overrideKey(HOME_EDIT_KEY));
    if (value === GrayOverride.ENABLED) return GrayOverride.ENABLED;
    if (value === GrayOverride.DISABLED) return GrayOverride.DISABLED;
    return GrayOverride.FOLLOW;
  }

  static setOverride(value: GrayOverride): void {
    const key = GrayReleaseManager.overrideKey(HOME_EDIT_KEY);
    if (value === GrayOverride.FOLLOW) AhuPreferences.remove(key);
    else AhuPreferences.putString(key, value);
  }

  static localState(): GrayFeatureState {
    const override = GrayReleaseManager.getOverride();
    const bucket = GrayRollout.bucket(HOME_EDIT_KEY, GrayReleaseManager.subject());
    const enabled = override === GrayOverride.ENABLED ||
      (override === GrayOverride.FOLLOW && GrayRollout.isEnabled(HOME_EDIT_FALLBACK, bucket));
    return { key: HOME_EDIT_KEY, title: '首页编辑', description: '允许长按首页进入编辑态，并在工具页显示编辑入口。',
      override: override, bucket: bucket, rolloutPercentage: HOME_EDIT_FALLBACK, enabled: enabled,
      source: override === GrayOverride.FOLLOW ? 'local' : 'debug' };
  }

  static async state(): Promise<GrayFeatureState> {
    const local = GrayReleaseManager.localState();
    if (local.override !== GrayOverride.FOLLOW) return local;
    const version = GrayReleaseManager.version();
    const url = 'https://openahu.org/api/gray/check?' +
      `feature=${HOME_EDIT_KEY}&subject=${encodeURIComponent(GrayReleaseManager.subject())}` +
      `&versionCode=${version.code}&versionName=${encodeURIComponent(version.name)}`;
    const request = http.createHttp();
    try {
      const response = await request.request(url, { method: http.RequestMethod.GET,
        header: { 'Accept': 'application/json', 'User-Agent': `AHUTong/${version.name} (HarmonyOS)` },
        expectDataType: http.HttpDataType.STRING, connectTimeout: 2_000, readTimeout: 3_000, usingCache: false });
      if ((response.responseCode as number) < 200 || (response.responseCode as number) >= 300) return local;
      const decision = JSON.parse(response.result as string) as GrayDecision;
      if (decision.enabled === undefined) return local;
      return { key: local.key, title: local.title, description: local.description, override: local.override,
        enabled: decision.enabled,
        rolloutPercentage: Math.max(0, Math.min(100, decision.rolloutPercentage ?? HOME_EDIT_FALLBACK)),
        bucket: Math.max(0, Math.min(99, decision.bucket ?? local.bucket)), source: 'remote' };
    } catch (_) { return local; }
    finally { request.destroy(); }
  }
}
