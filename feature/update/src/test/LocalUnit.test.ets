import { describe, it, expect } from '@ohos/hypium';
import { isVersionNewer } from '../main/ets/update/VersionComparator';

export default function localUnitTest() {
  describe('versionComparator', () => {
    it('comparesSemanticVersions', 0, () => {
      expect(isVersionNewer('v1.1.0', '1.0.9')).assertTrue();
      expect(isVersionNewer('1.0.0.1', '1.0')).assertTrue();
      expect(isVersionNewer('1.0', '1.0.0')).assertFalse();
      expect(isVersionNewer('0.9.9', '1.0.0')).assertFalse();
    });

    it('rejectsUnsafeReleaseTags', 0, () => {
      expect(isVersionNewer('1.1.0-beta', '1.0.0')).assertFalse();
      expect(isVersionNewer('release-2', '1.0.0')).assertFalse();
      expect(isVersionNewer('', '1.0.0')).assertFalse();
    });
  });
}
