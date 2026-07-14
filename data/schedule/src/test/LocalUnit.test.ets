import { describe, expect, it } from '@ohos/hypium';
import { resolveRemoteScheduleConfig } from '../main/ets/schedule/ScheduleSetupRepository';

export default function localUnitTest() {
  describe('remoteScheduleConfig', () => {
    it('resolvesSemesterAndTermMonday', 0, () => {
      const config = resolveRemoteScheduleConfig(
        { currentSemester: '2025-2026-2', weekIndex: 3 },
        new Date(2026, 2, 18, 12)
      );
      expect(config?.schoolYear).assertEqual('2025-2026');
      expect(config?.schoolTerm).assertEqual('2');
      expect(config?.currentWeek).assertEqual(3);
      expect(config?.startDate).assertEqual('2026-03-02');
    });

    it('rejectsMalformedRemoteValues', 0, () => {
      expect(resolveRemoteScheduleConfig(
        { currentSemester: '2025-2026-4', weekIndex: 3 }, new Date(2026, 2, 18))
      ).assertUndefined();
      expect(resolveRemoteScheduleConfig(
        { currentSemester: '2025-2026-2', weekIndex: 0 }, new Date(2026, 2, 18))
      ).assertUndefined();
    });
  });
}
