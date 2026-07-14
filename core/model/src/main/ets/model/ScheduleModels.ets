export interface Course {
  weekday?: string;
  startWeek?: string;
  endWeek?: string;
  extra?: string;
  location?: string;
  name?: string;
  teacher?: string;
  length?: string;
  startTime?: string;
  singleDouble?: string;
  courseId?: string;
  weekIndexes?: Array<number>;
}

export interface ScheduleConfig {
  startTime: number;
  week: number;
  weekDay: number;
  isShowAll: boolean;
}

function parseCourseNumber(value?: string): number {
  if (!value || value.length === 0) {
    return 0;
  }
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) ? parsed : 0;
}

export function courseWeekday(course: Course): number {
  return parseCourseNumber(course.weekday);
}

export function courseStartWeek(course: Course): number {
  return parseCourseNumber(course.startWeek);
}

export function courseEndWeek(course: Course): number {
  return parseCourseNumber(course.endWeek);
}

export function courseOccursInWeek(course: Course, week: number): boolean {
  const startWeek = courseStartWeek(course);
  const endWeek = courseEndWeek(course);
  if (week < startWeek || week > endWeek) return false;
  if ((course.weekIndexes ?? []).includes(week)) return true;
  return week % 2 === startWeek % 2;
}

export function courseLength(course: Course): number {
  return parseCourseNumber(course.length);
}

export function courseStartTime(course: Course): number {
  return parseCourseNumber(course.startTime);
}
