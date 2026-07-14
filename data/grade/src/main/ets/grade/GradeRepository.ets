import { AppErrorKind, AppResult, AppResults } from 'core_common';
import { AhuCache } from 'core_datastore';
import { CourseGrade, Grade, GradeItem, GradeResponse, TermGrade } from 'core_model';
import { AcademicCrawlerClient } from 'data_crawler';

export interface GradeRepository {
  getGrade(refresh?: boolean): Promise<AppResult<Grade>>;
}

export class DefaultGradeRepository implements GradeRepository {
  private static readonly BASE_URL: string = 'https://jw.ahu.edu.cn';
  private readonly client: AcademicCrawlerClient;

  constructor(client: AcademicCrawlerClient = new AcademicCrawlerClient()) {
    this.client = client;
  }

  private profileIds(html: string): Array<string> {
    const ids: Array<string> = [];
    const buttonPattern = /<button[^>]*(?:onclick=["'][^"']*myFunction[^"']*["'][^>]*)?value=["'](\d+)["'][^>]*>/gi;
    let match = buttonPattern.exec(html);
    while (match) {
      if (!ids.includes(match[1])) {
        ids.push(match[1]);
      }
      match = buttonPattern.exec(html);
    }
    const infoPattern = /grade\/sheet\/info\/(\d+)/gi;
    match = infoPattern.exec(html);
    while (match) {
      if (!ids.includes(match[1])) {
        ids.push(match[1]);
      }
      match = infoPattern.exec(html);
    }
    return ids;
  }

  private item(source: CourseGrade): GradeItem {
    return {
      course: source.courseName ?? '',
      courseNum: source.courseCode ?? '',
      credit: (source.credits ?? 0).toString(),
      grade: source.gaGrade ?? '',
      gradePoint: (source.gp ?? 0).toString(),
      courseType: source.courseType ?? '',
      semesterId: source.semesterId ?? 0,
      gradeDetail: source.gradeDetail ?? ''
    };
  }

  private terms(response: GradeResponse): Array<TermGrade> {
    const values = response.semesterId2studentGrades ?? {};
    const terms: Array<TermGrade> = [];
    Object.keys(values).forEach((key: string) => {
      const source = values[key] ?? [];
      if (source.length === 0) {
        return;
      }
      const name = source[0].semesterName ?? '';
      const pieces = name.split('-');
      if (pieces.length < 3) {
        return;
      }
      const items = source.map((course: CourseGrade): GradeItem => this.item(course));
      const credits = items.reduce((sum: number, grade: GradeItem): number => sum + Number(grade.credit ?? 0), 0);
      const weighted = items.reduce((sum: number, grade: GradeItem): number =>
        sum + Number(grade.gradePoint ?? 0) * Number(grade.credit ?? 0), 0);
      terms.push({
        schoolYear: `${pieces[0]}-${pieces[1]}`,
        schoolTerm: pieces[2],
        termGradePoint: weighted.toString(),
        termTotalCredit: credits.toString(),
        termGradePointAverage: credits > 0 ? (weighted / credits).toFixed(2) : '0.00',
        termGradeList: items
      });
    });
    return terms;
  }

  private aggregate(terms: Array<TermGrade>): Grade {
    const credits = terms.reduce((sum: number, term: TermGrade): number => sum + Number(term.termTotalCredit ?? 0), 0);
    const weighted = terms.reduce((sum: number, term: TermGrade): number =>
      sum + Number(term.termGradePointAverage ?? 0) * Number(term.termTotalCredit ?? 0), 0);
    return {
      totalCredit: credits.toString(),
      totalGradePoint: weighted.toString(),
      totalGradePointAverage: credits > 0 ? (weighted / credits).toFixed(2) : '0.00',
      termGradeList: terms.sort((left: TermGrade, right: TermGrade): number =>
        `${right.schoolYear}-${right.schoolTerm}`.localeCompare(`${left.schoolYear}-${left.schoolTerm}`))
    };
  }

  private async fetchRemote(): Promise<AppResult<Grade>> {
    const page = await this.client.getText(`${DefaultGradeRepository.BASE_URL}/student/for-std/grade/sheet`);
    if (!page.isSuccess || page.data === undefined) {
      return AppResults.failure<Grade>(page.error?.kind ?? AppErrorKind.UNKNOWN,
        page.error?.message ?? '获取成绩入口失败', page.error?.code);
    }
    let ids = this.profileIds(page.data);
    if (ids.length === 0 && page.data.trim().startsWith('{')) {
      try {
        const direct = JSON.parse(page.data) as GradeResponse;
        const directTerms = this.terms(direct);
        if (directTerms.length > 0) {
          return AppResults.success<Grade>(this.aggregate(directTerms));
        }
      } catch (_) {
      }
    }
    if (ids.length === 0) {
      return AppResults.failure<Grade>(AppErrorKind.PARSE, '无法识别教务成绩学籍');
    }
    const terms: Array<TermGrade> = [];
    for (let index = 0; index < ids.length; index++) {
      const result = await this.client.getJson<GradeResponse>(
        `${DefaultGradeRepository.BASE_URL}/student/for-std/grade/sheet/info/${ids[index]}`);
      if (result.isSuccess && result.data) {
        terms.push(...this.terms(result.data));
      }
    }
    if (terms.length === 0) {
      return AppResults.failure<Grade>(AppErrorKind.PARSE, '未获取到成绩数据');
    }
    return AppResults.success<Grade>(this.aggregate(terms));
  }

  async getGrade(refresh: boolean = false): Promise<AppResult<Grade>> {
    if (!refresh) {
      const cached = AhuCache.getGrade();
      if (cached) {
        return AppResults.success<Grade>(cached);
      }
    }
    const result = await this.fetchRemote();
    if (result.isSuccess && result.data) {
      AhuCache.saveGrade(result.data);
    }
    return result;
  }
}

export class GradeRepositoryProvider {
  private static readonly repository: GradeRepository = new DefaultGradeRepository();
  static get(): GradeRepository {
    return GradeRepositoryProvider.repository;
  }
}
