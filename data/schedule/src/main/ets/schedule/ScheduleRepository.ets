import { AppErrorKind, AppResult, AppResults } from 'core_common';
import { AhuCache } from 'core_datastore';
import { Course } from 'core_model';
import { AcademicCrawlerClient } from 'data_crawler';
import { ScheduleReminderCoordinatorProvider } from './ScheduleReminderCoordinator';
import { ScheduleWidgetCoordinatorProvider } from './ScheduleWidgetCoordinator';

interface CurrentSemester {
  id: number;
  name: string;
  schoolYear?: string;
}

interface CourseActivity {
  courseName?: string;
  lessonId?: number;
  room?: string;
  teacherNames?: Array<string>;
  weekIndexes?: Array<number>;
  weekday?: number;
  startUnit?: number;
  endUnit?: number;
}

interface StudentTable {
  activities?: Array<CourseActivity>;
}

interface CourseTableResponse {
  studentTableVms?: Array<StudentTable>;
}

export interface ScheduleRepository {
  getSchedule(refresh?: boolean): Promise<AppResult<Array<Course>>>;
  getNextSchedule(refresh?: boolean): Promise<AppResult<Array<Course>>>;
}

export class CrawlerScheduleSource {
  private static readonly BASE_URL: string = 'https://jw.ahu.edu.cn';
  private readonly client: AcademicCrawlerClient;

  constructor(client: AcademicCrawlerClient = new AcademicCrawlerClient()) {
    this.client = client;
  }

  private parseCurrentSemester(html: string): AppResult<CurrentSemester> {
    const script = html.match(/var\s+currentSemester\s*=\s*(\{[\s\S]*?\});/);
    if (!script || script.length < 2) {
      return AppResults.failure<CurrentSemester>(AppErrorKind.PARSE, '无法解析当前学期');
    }
    try {
      const raw = script[1].replace(/\\"/g, '"');
      return AppResults.success<CurrentSemester>(JSON.parse(raw) as CurrentSemester);
    } catch (_) {
      return AppResults.failure<CurrentSemester>(AppErrorKind.PARSE, '当前学期数据格式异常');
    }
  }

  private mapCourses(response: CourseTableResponse): Array<Course> {
    const tables = response.studentTableVms ?? [];
    const activities = tables.length > 0 ? tables[0].activities ?? [] : [];
    const courses: Array<Course> = [];
    for (let index = 0; index < activities.length; index++) {
      const activity = activities[index];
      const weeks = (activity.weekIndexes ?? []).slice().sort((left: number, right: number) => left - right);
      if (weeks.length === 0) {
        continue;
      }
      const startUnit = activity.startUnit ?? 0;
      const endUnit = activity.endUnit ?? startUnit;
      courses.push({
        name: activity.courseName ?? '',
        courseId: activity.lessonId?.toString() ?? '',
        location: activity.room ?? '未知',
        teacher: (activity.teacherNames ?? []).join(', '),
        weekday: (activity.weekday ?? 0).toString(),
        startWeek: weeks[0].toString(),
        endWeek: weeks[weeks.length - 1].toString(),
        startTime: startUnit.toString(),
        length: Math.max(0, endUnit - startUnit + 1).toString(),
        weekIndexes: weeks
      });
    }
    return courses;
  }

  private async fetchScheduleOffset(offset: number): Promise<AppResult<Array<Course>>> {
    const page = await this.client.getText(`${CrawlerScheduleSource.BASE_URL}/student/for-std/course-table`);
    if (!page.isSuccess || page.data === undefined) {
      return AppResults.failure<Array<Course>>(
        page.error?.kind ?? AppErrorKind.UNKNOWN,
        page.error?.message ?? '获取课表学期失败',
        page.error?.code
      );
    }
    const semester = this.parseCurrentSemester(page.data);
    if (!semester.isSuccess || !semester.data) {
      return AppResults.failure<Array<Course>>(
        semester.error?.kind ?? AppErrorKind.PARSE,
        semester.error?.message ?? '无法解析当前学期'
      );
    }
    const id = semester.data.id;
    const pathId = id + offset;
    const url = `${CrawlerScheduleSource.BASE_URL}/student/for-std/course-table/semester/${pathId}/print-data` +
      `?semesterId=${id}&hasExperiment=false`;
    const response = await this.client.getJson<CourseTableResponse>(url);
    if (!response.isSuccess || !response.data) {
      return AppResults.failure<Array<Course>>(
        response.error?.kind ?? AppErrorKind.UNKNOWN,
        response.error?.message ?? '获取课表失败',
        response.error?.code
      );
    }
    return AppResults.success<Array<Course>>(this.mapCourses(response.data));
  }

  async fetchSchedule(): Promise<AppResult<Array<Course>>> { return this.fetchScheduleOffset(0); }
  async fetchNextSchedule(): Promise<AppResult<Array<Course>>> { return this.fetchScheduleOffset(20); }
}

export class DefaultScheduleRepository implements ScheduleRepository {
  private readonly source: CrawlerScheduleSource;

  constructor(source: CrawlerScheduleSource = new CrawlerScheduleSource()) {
    this.source = source;
  }

  async getSchedule(refresh: boolean = false): Promise<AppResult<Array<Course>>> {
    const schoolYear = AhuCache.getSchoolYear();
    const rawTerm = AhuCache.getSchoolTerm();
    if (!AhuCache.isLogin() || !schoolYear || !rawTerm) {
      return AppResults.failure<Array<Course>>(AppErrorKind.AUTHENTICATION, '请先登录并完成学期设置');
    }
    const schoolTerm = rawTerm.startsWith(`${schoolYear}-`)
      ? rawTerm.substring(schoolYear.length + 1)
      : rawTerm;
    if (!refresh) {
      const cached = AhuCache.getSchedule(schoolYear, schoolTerm);
      if (cached.length > 0) {
        return AppResults.success<Array<Course>>(cached);
      }
    }
    const remote = await this.source.fetchSchedule();
    if (remote.isSuccess && remote.data) {
      AhuCache.saveSchedule(schoolYear, schoolTerm, remote.data);
      ScheduleReminderCoordinatorProvider.get().reschedule();
      ScheduleWidgetCoordinatorProvider.get().update();
    }
    return remote;
  }

  async getNextSchedule(refresh: boolean = false): Promise<AppResult<Array<Course>>> {
    if (!AhuCache.isLogin()) {
      return AppResults.failure<Array<Course>>(AppErrorKind.AUTHENTICATION, '请先登录');
    }
    if (!refresh) {
      const cached = AhuCache.getNextSchedule();
      if (cached !== undefined) return AppResults.success<Array<Course>>(cached);
    }
    const remote = await this.source.fetchNextSchedule();
    if (remote.isSuccess && remote.data) AhuCache.saveNextSchedule(remote.data);
    return remote;
  }
}

export class ScheduleRepositoryProvider {
  private static readonly repository: ScheduleRepository = new DefaultScheduleRepository();

  static get(): ScheduleRepository {
    return ScheduleRepositoryProvider.repository;
  }
}
