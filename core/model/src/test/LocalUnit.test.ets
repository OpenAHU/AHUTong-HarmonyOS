import { describe, it, expect } from '@ohos/hypium';
import {
  Course,
  courseEndWeek,
  courseLength,
  courseOccursInWeek,
  courseStartTime,
  courseStartWeek,
  courseWeekday
} from '../main/ets/model/ScheduleModels';

export default function localUnitTest() {
  describe('courseModelConversions', () => {
    it('parsesScheduleCoordinates', 0, () => {
      const course: Course = { weekday: '3', startWeek: '2', endWeek: '16', startTime: '5', length: '2' };
      expect(courseWeekday(course)).assertEqual(3);
      expect(courseStartWeek(course)).assertEqual(2);
      expect(courseEndWeek(course)).assertEqual(16);
      expect(courseStartTime(course)).assertEqual(5);
      expect(courseLength(course)).assertEqual(2);
    });

    it('fallsBackForMalformedCoordinates', 0, () => {
      const course: Course = { weekday: 'not-a-number', startTime: '', length: undefined };
      expect(courseWeekday(course)).assertEqual(0);
      expect(courseStartTime(course)).assertEqual(0);
      expect(courseLength(course)).assertEqual(0);
    });

    it('matchesExplicitAndLegacyParityWeeks', 0, () => {
      const course: Course = { startWeek: '2', endWeek: '8', weekIndexes: [2, 4, 8] };
      expect(courseOccursInWeek(course, 4)).assertTrue();
      expect(courseOccursInWeek(course, 6)).assertTrue();
      expect(courseOccursInWeek(course, 5)).assertFalse();
      expect(courseOccursInWeek(course, 10)).assertFalse();
    });
  });
}
