import { AhuCache } from 'core_datastore';
import { Course, courseLength, courseOccursInWeek, courseStartTime, courseWeekday } from 'core_model';
import { formBindingData, formProvider } from '@kit.FormKit';

const START_MINUTES: Array<number> = [0, 480, 530, 590, 640, 690, 840, 890, 950, 1000, 1050, 1140, 1190, 1240];
const END_MINUTES: Array<number> = [0, 525, 575, 635, 685, 735, 885, 935, 995, 1045, 1095, 1185, 1235, 1285];
const WEEKDAYS: Array<string> = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];

export class ScheduleWidgetData {
  remainingText: string = '暂无课程';
  dateText: string = '';
  emptyText: string = '点击打开安大通查看完整课表';
  course1Name: string = '';
  course1Detail: string = '';
  course1State: string = '';
  course2Name: string = '';
  course2Detail: string = '';
  course2State: string = '';
  course3Name: string = '';
  course3Detail: string = '';
  course3State: string = '';
  themeColor: string = '#FF4A90E2';
}

export class ScheduleWidgetDataBuilder {
  static build(now: Date = AhuCache.now()): ScheduleWidgetData {
    const data = new ScheduleWidgetData();
    data.dateText = `${ScheduleWidgetDataBuilder.two(now.getMonth() + 1)}-${ScheduleWidgetDataBuilder.two(now.getDate())} / ${WEEKDAYS[now.getDay()]}`;
    const theme = AhuCache.themeColor();
    if (theme.length > 0) data.themeColor = theme;
    const year = AhuCache.getSchoolYear();
    const rawTerm = AhuCache.getSchoolTerm();
    if (!year || !rawTerm) return data;
    const term = rawTerm.startsWith(`${year}-`) ? rawTerm.substring(year.length + 1) : rawTerm;
    const startText = AhuCache.getSchoolTermStartTime(year, term);
    if (!startText) return data;
    const termStart = new Date(`${startText}T00:00:00`);
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const week = Math.floor((today.getTime() - termStart.getTime()) / 604_800_000) + 1;
    const weekday = ((now.getDay() + 6) % 7) + 1;
    const minutes = now.getHours() * 60 + now.getMinutes();
    const remaining = AhuCache.getSchedule(year, term)
      .filter((course: Course) => courseWeekday(course) === weekday && courseOccursInWeek(course, week))
      .filter((course: Course) => ScheduleWidgetDataBuilder.endMinutes(course) >= minutes)
      .sort((left: Course, right: Course) => courseStartTime(left) - courseStartTime(right));
    data.remainingText = remaining.length === 0 ? '暂无课程' : `还剩 ${remaining.length} 节`;
    if (remaining.length > 0) ScheduleWidgetDataBuilder.putCourse(data, remaining[0], 1, minutes);
    if (remaining.length > 1) ScheduleWidgetDataBuilder.putCourse(data, remaining[1], 2, minutes);
    if (remaining.length > 2) ScheduleWidgetDataBuilder.putCourse(data, remaining[2], 3, minutes);
    return data;
  }

  static bindingData(): formBindingData.FormBindingData {
    return formBindingData.createFormBindingData(ScheduleWidgetDataBuilder.build());
  }

  private static putCourse(data: ScheduleWidgetData, course: Course, slot: number, minutes: number): void {
    const start = courseStartTime(course);
    const end = start + Math.max(1, courseLength(course)) - 1;
    const detail = `${start}-${end}节 · ${ScheduleWidgetDataBuilder.shorten(course.location ?? '')}`;
    const state = minutes >= (START_MINUTES[start] ?? 0) && minutes <= ScheduleWidgetDataBuilder.endMinutes(course) ? '正在上课' : '待上课';
    if (slot === 1) { data.course1Name = course.name ?? ''; data.course1Detail = detail; data.course1State = state; }
    if (slot === 2) { data.course2Name = course.name ?? ''; data.course2Detail = detail; data.course2State = state; }
    if (slot === 3) { data.course3Name = course.name ?? ''; data.course3Detail = detail; data.course3State = state; }
  }

  private static endMinutes(course: Course): number {
    const end = courseStartTime(course) + Math.max(1, courseLength(course)) - 1;
    return END_MINUTES[end] ?? 0;
  }

  private static shorten(location: string): string {
    return location.replace('博学北楼', '博北').replace('博学南楼', '博南').replace('笃行北楼', '笃北')
      .replace('笃行南楼', '笃南').replace('互联大楼', '互楼').replace('体育场', '体');
  }

  private static two(value: number): string { return value < 10 ? `0${value}` : `${value}`; }
}

export class ScheduleWidgetManager {
  static async updateAll(ids: Array<string> = AhuCache.getScheduleWidgetIds()): Promise<void> {
    const data = ScheduleWidgetDataBuilder.bindingData();
    for (let index = 0; index < ids.length; index++) {
      try { await formProvider.updateForm(ids[index], data); } catch (_) {}
    }
  }
}
