import { describe, it, expect } from '@ohos/hypium';
import { normalizeHomeWidgetSlots } from '../main/ets/datastore/HomeWidgetSlots';

export default function localUnitTest() {
  describe('homeWidgetSlots', () => {
    it('keepsEightSlotsAndRemovesDuplicates', 0, () => {
      const slots = normalizeHomeWidgetSlots(['bathroom', ' electricity ', 'bathroom', '', 'grade']);
      expect(slots.length).assertEqual(8);
      expect(slots[0]).assertEqual('bathroom');
      expect(slots[1]).assertEqual('electricity');
      expect(slots[2]).assertEqual('');
      expect(slots[4]).assertEqual('grade');
    });

    it('truncatesExtraSlots', 0, () => {
      const slots = normalizeHomeWidgetSlots(['1', '2', '3', '4', '5', '6', '7', '8', '9']);
      expect(slots.length).assertEqual(8);
      expect(slots.includes('9')).assertFalse();
    });
  });
}
