import { AppErrorKind, AppResult, AppResults } from 'core_common';
import { AhuCache } from 'core_datastore';
import { CourseGrade, GpaRankInfo, Grade, GradeItem, GradeResponse, GradeStudentProfile, TermGrade } from 'core_model';
import { AcademicCrawlerClient } from 'data_crawler';

export interface GradeRepository {
  getGrade(refresh?: boolean): Promise<AppResult<Grade>>;
  getProfiles(): Array<GradeStudentProfile>;
  getGradeForProfile(profileId: string): Grade | undefined;
  getGpaRank(profileId: string, refresh?: boolean): Promise<AppResult<GpaRankInfo>>;
}

export class DefaultGradeRepository implements GradeRepository {
  private static readonly BASE_URL: string = 'https://jw.ahu.edu.cn';
  private readonly client: AcademicCrawlerClient;

  constructor(client: AcademicCrawlerClient = new AcademicCrawlerClient()) {
    this.client = client;
  }

  private profiles(html: string): Array<GradeStudentProfile> {
    const profiles: Array<GradeStudentProfile> = [];
    const buttonPattern = /<button[^>]*(?:onclick=["'][^"']*myFunction[^"']*["'][^>]*)?value=["'](\d+)["'][^>]*>/gi;
    let match = buttonPattern.exec(html);
    while (match) {
      const profileId = match[1];
      if (!profiles.some((item: GradeStudentProfile) => item.id === profileId)) {
        const start = Math.max(0, match.index - 800); const end = Math.min(html.length, match.index + 1_500);
        const block = html.substring(start, end); const values: Array<string> = [];
        const ddPattern = /<dd[^>]*>([\s\S]*?)<\/dd>/gi; let dd = ddPattern.exec(block);
        while (dd && values.length < 3) { values.push(dd[1].replace(/<[^>]*>/g, '').replace(/&nbsp;/g, ' ').trim()); dd = ddPattern.exec(block); }
        profiles.push({ id: profileId, trainingType: values[0] || `学籍 ${profiles.length + 1}`,
          department: values[1] ?? '', major: values[2] ?? '' });
      }
      match = buttonPattern.exec(html);
    }
    const infoPattern = /grade\/sheet\/info\/(\d+)/gi;
    match = infoPattern.exec(html);
    while (match) {
      const profileId = match[1];
      if (!profiles.some((item: GradeStudentProfile) => item.id === profileId)) {
        profiles.push({ id: profileId, trainingType: profiles.length === 0 ? '主修' : `学籍 ${profiles.length + 1}`,
          department: '', major: '' });
      }
      match = infoPattern.exec(html);
    }
    return profiles;
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
    const profiles = this.profiles(page.data);
    if (profiles.length === 0 && page.data.trim().startsWith('{')) {
      try {
        const direct = JSON.parse(page.data) as GradeResponse;
        const directTerms = this.terms(direct);
        if (directTerms.length > 0) {
          return AppResults.success<Grade>(this.aggregate(directTerms));
        }
      } catch (_) {
      }
    }
    if (profiles.length === 0) {
      return AppResults.failure<Grade>(AppErrorKind.PARSE, '无法识别教务成绩学籍');
    }
    const perProfile: Record<string, Grade> = {};
    for (let index = 0; index < profiles.length; index++) {
      const result = await this.client.getJson<GradeResponse>(
        `${DefaultGradeRepository.BASE_URL}/student/for-std/grade/sheet/info/${profiles[index].id}`);
      if (result.isSuccess && result.data) {
        const terms = this.terms(result.data);
        if (terms.length > 0) perProfile[profiles[index].id] = this.aggregate(terms);
      }
    }
    const availableProfiles = profiles.filter((profile: GradeStudentProfile) => perProfile[profile.id] !== undefined);
    if (availableProfiles.length === 0) {
      return AppResults.failure<Grade>(AppErrorKind.PARSE, '未获取到成绩数据');
    }
    AhuCache.saveGradeProfiles(profiles); AhuCache.saveGradesPerProfile(perProfile);
    return AppResults.success<Grade>(perProfile[availableProfiles[0].id]);
  }

  async getGrade(refresh: boolean = false): Promise<AppResult<Grade>> {
    if (AhuCache.getMockData()) {
      const scenario = AhuCache.getMockScenario();
      if (scenario === 'network_error') return AppResults.failure<Grade>(AppErrorKind.HTTP, 'Mock 场景：接口返回 500', 500);
      if (scenario === 'expired_login') return AppResults.failure<Grade>(AppErrorKind.AUTHENTICATION, 'Mock 场景：登录状态已过期', 401);
      return AppResults.success<Grade>(AhuCache.getGrade() ?? { termGradeList: [] });
    }
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

  getProfiles(): Array<GradeStudentProfile> { return AhuCache.getGradeProfiles(); }
  getGradeForProfile(profileId: string): Grade | undefined { return AhuCache.getGradesPerProfile()[profileId]; }

  private rankObject(html: string): string | undefined {
    const assignment = /(?:var|let|const)?\s*(?:window\s*\.\s*)?gpasemestermodel\s*=/i.exec(html);
    if (!assignment) return undefined;
    const start = html.indexOf('{', assignment.index + assignment[0].length); if (start < 0) return undefined;
    let depth = 0; let quote = ''; let escaped = false;
    for (let index = start; index < html.length; index++) {
      const char = html[index];
      if (quote.length > 0) { if (escaped) escaped = false; else if (char === '\\') escaped = true;
        else if (char === quote) quote = ''; continue; }
      if (char === '"' || char === "'") quote = char;
      else if (char === '{') depth++;
      else if (char === '}' && --depth === 0) return html.substring(start, index + 1);
    }
    return undefined;
  }

  async getGpaRank(profileId: string, refresh: boolean = false): Promise<AppResult<GpaRankInfo>> {
    if (AhuCache.getMockData()) {
      const scenario = AhuCache.getMockScenario();
      if (scenario === 'network_error') return AppResults.failure<GpaRankInfo>(AppErrorKind.HTTP, 'Mock 场景：接口返回 500', 500);
      if (scenario === 'expired_login') return AppResults.failure<GpaRankInfo>(AppErrorKind.AUTHENTICATION, 'Mock 场景：登录状态已过期', 401);
      const rank = AhuCache.getGpaRank(profileId);
      return rank ? AppResults.success<GpaRankInfo>(rank) :
        AppResults.failure<GpaRankInfo>(AppErrorKind.PARSE, 'Mock 场景：暂无专业排名');
    }
    if (!refresh) { const cached = AhuCache.getGpaRank(profileId); if (cached) return AppResults.success<GpaRankInfo>(cached); }
    const result = await this.client.getText(
      `${DefaultGradeRepository.BASE_URL}/student/for-std/grade/sheet/semester-index/${profileId}`);
    if (result.isSuccess && result.data) {
      try {
        const objectText = this.rankObject(result.data);
        if (!objectText) throw new Error('未找到排名数据');
        const rank = JSON.parse(objectText.replace(/'/g, '"')) as GpaRankInfo;
        AhuCache.saveGpaRank(profileId, rank); return AppResults.success<GpaRankInfo>(rank);
      } catch (_) {}
    }
    const cached = AhuCache.getGpaRank(profileId);
    if (cached) return AppResults.success<GpaRankInfo>(cached);
    return AppResults.failure<GpaRankInfo>(result.error?.kind ?? AppErrorKind.PARSE,
      result.error?.message ?? '当前学籍暂无专业排名', result.error?.code);
  }
}

export class GradeRepositoryProvider {
  private static readonly repository: GradeRepository = new DefaultGradeRepository();
  static get(): GradeRepository {
    return GradeRepositoryProvider.repository;
  }
}
