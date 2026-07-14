import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';

export class GrayRollout {
  static isEnabled(rolloutPercentage: number, bucket: number): boolean {
    const percentage = Math.max(0, Math.min(100, rolloutPercentage));
    const normalizedBucket = Math.max(0, Math.min(99, bucket));
    return normalizedBucket < percentage;
  }

  static sha256(value: string): Uint8Array {
    try {
      const md = cryptoFramework.createMd('SHA256');
      md.updateSync({ data: new util.TextEncoder().encodeInto(value) });
      return md.digestSync().data;
    } catch (_) {
      return new Uint8Array(32);
    }
  }

  static sha256Hex(value: string): string {
    const bytes = GrayRollout.sha256(value);
    let result = '';
    for (let index = 0; index < bytes.length; index++) result += bytes[index].toString(16).padStart(2, '0');
    return result;
  }

  static bucket(featureKey: string, subjectKey: string): number {
    const digest = GrayRollout.sha256(`${featureKey}:${subjectKey}`);
    let value = 0;
    for (let index = 0; index < 4; index++) value = (value << 8) | digest[index];
    return ((value % 100) + 100) % 100;
  }
}
