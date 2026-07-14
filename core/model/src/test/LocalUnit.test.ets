import { describe, it, expect } from '@ohos/hypium';
import {
  Course,
  courseEndWeek,
  courseLength,
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
  });
}
