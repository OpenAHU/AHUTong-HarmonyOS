import { AhuCache } from 'core_datastore';
import { Course, courseLength, courseStartTime, courseWeekday } from 'core_model';
import { common } from '@kit.AbilityKit';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';

const START_MINUTES: Array<number> = [0, 480, 530, 590, 640, 690, 840, 890, 950, 1000, 1050, 1140, 1190, 1240];

export class CourseReminderManager {
  private static readonly SCAN_DAYS: number = 21;
  private static readonly MINUTES_BEFORE: number = 10;

  static async setEnabled(context: common.UIAbilityContext, enabled: boolean): Promise<boolean> {
    if (!enabled) {
      AhuCache.setCourseReminderEnabled(false);
      await CourseReminderManager.cancelCourseReminders();
      return true;
    }
    try {
      await notificationManager.requestEnableNotification(context);
      AhuCache.setCourseReminderEnabled(true);
      await CourseReminderManager.reschedule();
      return true;
    } catch (_) {
      AhuCache.setCourseReminderEnabled(false);
      return false;
    }
  }

  static async reschedule(): Promise<number> {
    await CourseReminderManager.cancelCourseReminders();
    if (!AhuCache.courseReminderEnabled()) return 0;
    const year = AhuCache.getSchoolYear();
    const rawTerm = AhuCache.getSchoolTerm();
    if (!year || !rawTerm) return 0;
    const term = rawTerm.startsWith(`${year}-`) ? rawTerm.substring(year.length + 1) : rawTerm;
    const startText = AhuCache.getSchoolTermStartTime(year, term);
    if (!startText) return 0;
    const courses = AhuCache.getSchedule(year, term);
    if (courses.length === 0) return 0;
    const termStart = new Date(`${startText}T00:00:00`);
    const now = new Date();
    let count = 0;
    for (let offset = 0; offset <= CourseReminderManager.SCAN_DAYS; offset++) {
      const date = new Date(now.getFullYear(), now.getMonth(), now.getDate() + offset);
      const week = Math.floor((date.getTime() - termStart.getTime()) / 604_800_000) + 1;
      const weekday = ((date.getDay() + 6) % 7) + 1;
      for (let index = 0; index < courses.length; index++) {
        const course = courses[index];
        if (courseWeekday(course) !== weekday || !(course.weekIndexes ?? []).includes(week)) continue;
        const period = courseStartTime(course);
        const startMinutes = START_MINUTES[period] ?? 0;
        if (startMinutes === 0) continue;
        const trigger = new Date(date.getFullYear(), date.getMonth(), date.getDate(),
          Math.floor(startMinutes / 60), startMinutes % 60 - CourseReminderManager.MINUTES_BEFORE);
        if (trigger.getTime() <= now.getTime()) continue;
        const endPeriod = period + Math.max(1, courseLength(course)) - 1;
        const content = `10 分钟后上课 · ${course.location ?? '地点未知'} · 第 ${period}-${endPeriod} 节`;
        const request: reminderAgentManager.ReminderRequestCalendar = {
          reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
          dateTime: { year: trigger.getFullYear(), month: trigger.getMonth() + 1, day: trigger.getDate(),
            hour: trigger.getHours(), minute: trigger.getMinutes(), second: 0 },
          title: course.name ?? '课程提醒', content: content, expiredContent: content,
          notificationId: CourseReminderManager.notificationId(trigger, course), groupId: 'ahu_course_reminder',
          slotType: notificationManager.SlotType.SERVICE_INFORMATION, tapDismissed: true,
          wantAgent: { pkgName: 'com.openahu.ahutong', abilityName: 'EntryAbility',
            parameters: { source: 'course_reminder' } }
        };
        try { await reminderAgentManager.publishReminder(request); count++; } catch (_) {}
      }
    }
    return count;
  }

  static async cancelCourseReminders(): Promise<void> {
    try {
      const reminders = await reminderAgentManager.getAllValidReminders();
      for (let index = 0; index < reminders.length; index++) {
        const reminder = reminders[index];
        if (reminder.reminderReq.groupId !== 'ahu_course_reminder') continue;
        try { await reminderAgentManager.cancelReminder(reminder.reminderId); } catch (_) {}
      }
    } catch (_) {}
    try { await notificationManager.cancelGroup('ahu_course_reminder'); } catch (_) {}
  }

  static async scheduleDebug(context: common.UIAbilityContext, seconds: number): Promise<boolean> {
    try {
      await notificationManager.requestEnableNotification(context);
      const request: reminderAgentManager.ReminderRequestTimer = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
        triggerTimeInSeconds: Math.max(1, seconds),
        title: '安大通测试提醒', content: 'Debug 通知链路工作正常', expiredContent: 'Debug 通知链路工作正常',
        notificationId: 2_000_000_001 + Math.max(1, seconds), groupId: 'ahu_debug_reminder',
        slotType: notificationManager.SlotType.SERVICE_INFORMATION, tapDismissed: true,
        wantAgent: { pkgName: 'com.openahu.ahutong', abilityName: 'EntryAbility', parameters: { source: 'debug_reminder' } }
      };
      await reminderAgentManager.publishReminder(request);
      return true;
    } catch (_) { return false; }
  }

  private static notificationId(trigger: Date, course: Course): number {
    const value = `${trigger.getTime()}-${course.courseId ?? course.name ?? ''}`;
    let hash = 0;
    for (let index = 0; index < value.length; index++) hash = ((hash << 5) - hash + value.charCodeAt(index)) | 0;
    return Math.abs(hash % 2_000_000_000) + 10_000;
  }
}
