export const CORE_MODEL_VERSION: string = '1';

export interface LicenseInfo {
  name: string;
  author: string;
  url: string;
  license: string;
}

export interface ApkUpdateInfo {
  update?: boolean;
  force: boolean;
  versionCode: number;
  versionName?: string;
  changelog?: string;
  url?: string;
  sha256?: string;
  signature?: string;
  alg?: string;
  note?: string;
}
