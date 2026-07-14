import { asset } from '@kit.AssetStoreKit';
import { util } from '@kit.ArkTS';

export interface StoredCredential {
  username: string;
  password: string;
}

export class SecureCredentialStore {
  private static readonly ALIAS: Uint8Array = new util.TextEncoder().encodeInto('ahutong_wisdom_credential');

  private static encode(value: string): Uint8Array {
    return new util.TextEncoder().encodeInto(value);
  }

  private static decode(value: Uint8Array): string {
    return new util.TextDecoder().decodeToString(value);
  }

  async save(username: string, password: string): Promise<void> {
    const credential: StoredCredential = { username: username, password: password };
    const attributes: asset.AssetMap = new Map<asset.Tag, asset.Value>();
    attributes.set(asset.Tag.ALIAS, SecureCredentialStore.ALIAS);
    attributes.set(asset.Tag.SECRET, SecureCredentialStore.encode(JSON.stringify(credential)));
    attributes.set(asset.Tag.ACCESSIBILITY, asset.Accessibility.DEVICE_FIRST_UNLOCKED);
    attributes.set(asset.Tag.SYNC_TYPE, asset.SyncType.NEVER);
    attributes.set(asset.Tag.CONFLICT_RESOLUTION, asset.ConflictResolution.OVERWRITE);
    try {
      await asset.add(attributes);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to save secure credential';
      throw new Error(message);
    }
  }

  async load(): Promise<StoredCredential | undefined> {
    const query: asset.AssetMap = new Map<asset.Tag, asset.Value>();
    query.set(asset.Tag.ALIAS, SecureCredentialStore.ALIAS);
    query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL);
    try {
      const results = await asset.query(query);
      if (results.length === 0) {
        return undefined;
      }
      const secret = results[0].get(asset.Tag.SECRET) as Uint8Array;
      return JSON.parse(SecureCredentialStore.decode(secret)) as StoredCredential;
    } catch (_) {
      return undefined;
    }
  }

  async remove(): Promise<void> {
    const query: asset.AssetMap = new Map<asset.Tag, asset.Value>();
    query.set(asset.Tag.ALIAS, SecureCredentialStore.ALIAS);
    try {
      await asset.remove(query);
    } catch (_) {
    }
  }
}
