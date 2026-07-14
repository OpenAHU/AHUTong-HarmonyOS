import { describe, it, expect } from '@ohos/hypium';
import { GrayRollout } from '../main/ets/gray/GrayRollout';

export default function localUnitTest() {
  describe('grayRollout', () => {
    it('createsStableHundredBucket', 0, () => {
      const first = GrayRollout.bucket('feature_a', 'user:1001');
      expect(first).assertEqual(GrayRollout.bucket('feature_a', 'user:1001'));
      expect(first >= 0 && first <= 99).assertTrue();
    });

    it('appliesRolloutBoundaries', 0, () => {
      expect(GrayRollout.isEnabled(0, 0)).assertFalse();
      expect(GrayRollout.isEnabled(1, 0)).assertTrue();
      expect(GrayRollout.isEnabled(100, 99)).assertTrue();
      expect(GrayRollout.isEnabled(50, 50)).assertFalse();
    });
  });
}
