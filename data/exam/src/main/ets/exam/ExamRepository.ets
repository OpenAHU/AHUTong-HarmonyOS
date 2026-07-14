import { AppErrorKind, AppResult, AppResults } from 'core_common';
import { AhuCache } from 'core_datastore';
import { Exam } from 'core_model';
import { AcademicCrawlerClient } from 'data_crawler';

interface LegacyExamCourse { nameZh?: string; }
interface LegacyExamType { nameZh?: string; }
interface LegacyCampus { nameZh?: string; }
interface LegacyExam {
  course?: LegacyExamCourse; examType?: LegacyExamType; requiredCampus?: LegacyCampus;
  examTime?: string; seatNo?: string | number; room?: string; finished?: boolean;
}

export interface ExamRepository { getExams(refresh?: boolean): Promise<AppResult<Array<Exam>>>; }

export class DefaultExamRepository implements ExamRepository {
  private readonly client: AcademicCrawlerClient;
  constructor(client: AcademicCrawlerClient = new AcademicCrawlerClient()) { this.client = client; }

  private text(html: string): string {
    return html.replace(/<[^>]*>/g, ' ').replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&')
      .replace(/\s+/g, ' ').trim();
  }

  private seats(html: string): Map<string, string> {
    const result = new Map<string, string>();
    const block = html.match(/var\s+studentExamList\s*=\s*(\[[\s\S]*?\]);/);
    if (!block) return result;
    const objectPattern = /\{([\s\S]*?)\}/g;
    let object = objectPattern.exec(block[1]);
    while (object) {
      const id = object[1].match(/["']?id["']?\s*:\s*["']?(\d+)/)?.[1] ?? '';
      const seat = object[1].match(/["']?seatNo["']?\s*:\s*["']?([^,"'}\s]+)/)?.[1] ?? '';
      if (id.length > 0) result.set(id, seat);
      object = objectPattern.exec(block[1]);
    }
    return result;
  }

  private tableExams(html: string): Array<Exam> {
    const result: Array<Exam> = [];
    const seats = this.seats(html);
    const rowPattern = /<tr[^>]*data-finished=["'](true|false)["'][^>]*>([\s\S]*?)<\/tr>/gi;
    let row = rowPattern.exec(html);
    while (row) {
      const body = row[2];
      const time = this.text(body.match(/<div[^>]*class=["'][^"']*time[^"']*["'][^>]*>([\s\S]*?)<\/div>/i)?.[1] ?? '');
      const bold = body.match(/<span[^>]*style=["'][^"']*font-weight[^"']*bold[^"']*["'][^>]*>([\s\S]*?)<\/span>/i);
      const type = body.match(/<span[^>]*class=["'][^"']*tag-span[^"']*["'][^>]*>([\s\S]*?)<\/span>/i);
      const course = this.text(bold?.[1] ?? '');
      const examType = this.text(type?.[1] ?? '');
      const seatId = body.match(/id=["']seat-(\d+)["']/i)?.[1] ?? '';
      const cells = body.match(/<td[^>]*>([\s\S]*?)<\/td>/i);
      const firstCell = cells?.[1] ?? '';
      const location = this.text(firstCell.replace(/<span[^>]*id=["']seat-[^"']+["'][^>]*>[\s\S]*?<\/span>/gi, ''));
      result.push({
        course: examType.length > 0 ? `${course}(${examType})` : course,
        time: time, location: location, seatNum: seats.get(seatId) ?? '', finished: row[1] === 'true'
      });
      row = rowPattern.exec(html);
    }
    return result;
  }

  private legacyExams(html: string): Array<Exam> {
    const block = html.match(/studentExamInfoVms\s*=\s*(\[[\s\S]*?\]);/);
    if (!block) return [];
    try {
      const source = JSON.parse(block[1].replace(/'/g, '"')) as Array<LegacyExam>;
      return source.map((item: LegacyExam): Exam => {
        const name = item.course?.nameZh ?? '';
        const type = item.examType?.nameZh ?? '';
        const campus = item.requiredCampus?.nameZh ?? '';
        const room = item.room ?? '';
        return {
          course: type.length > 0 ? `${name}(${type})` : name, time: item.examTime ?? '',
          seatNum: item.seatNo?.toString() ?? '', location: campus && room ? `${campus}-${room}` : campus + room,
          finished: item.finished ?? false
        };
      });
    } catch (_) { return []; }
  }

  async getExams(refresh: boolean = false): Promise<AppResult<Array<Exam>>> {
    if (AhuCache.getMockData()) {
      const scenario = AhuCache.getMockScenario();
      if (scenario === 'network_error') return AppResults.failure<Array<Exam>>(AppErrorKind.HTTP, 'Mock 场景：接口返回 500', 500);
      if (scenario === 'expired_login') return AppResults.failure<Array<Exam>>(AppErrorKind.AUTHENTICATION, 'Mock 场景：登录状态已过期', 401);
      return AppResults.success<Array<Exam>>(AhuCache.getExams());
    }
    if (!refresh) {
      const cached = AhuCache.getExams();
      if (cached.length > 0) return AppResults.success<Array<Exam>>(cached);
    }
    const page = await this.client.getText('https://jw.ahu.edu.cn/student/for-std/exam-arrange');
    if (!page.isSuccess || page.data === undefined) {
      return AppResults.failure<Array<Exam>>(page.error?.kind ?? AppErrorKind.UNKNOWN,
        page.error?.message ?? '获取考试信息失败', page.error?.code);
    }
    const table = this.tableExams(page.data);
    const exams = table.length > 0 ? table : this.legacyExams(page.data);
    AhuCache.saveExams(exams);
    return AppResults.success<Array<Exam>>(exams);
  }
}

export class ExamRepositoryProvider {
  private static readonly repository: ExamRepository = new DefaultExamRepository();
  static get(): ExamRepository { return ExamRepositoryProvider.repository; }
}
