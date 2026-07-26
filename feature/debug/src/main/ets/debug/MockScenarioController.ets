import { AhuCache } from 'core_datastore';
import { Course, Exam, GpaRankInfo, Grade, GradeItem, LostFoundItem, TermGrade } from 'core_model';

export interface MockScenarioOption {
  id: string;
  title: string;
  subtitle: string;
  badge: string;
}

export class MockScenarioController {
  static readonly scenarios: Array<MockScenarioOption> = [
    { id: 'standard_student', title: '标准在校生', subtitle: '正常课表、成绩、考试、校园卡和失物招领数据', badge: '正常' },
    { id: 'exam_week', title: '考试周', subtitle: '密集考试与少量答疑课程', badge: '考试' },
    { id: 'new_student', title: '新生刚入学', subtitle: '少量课程、暂无成绩，验证首次使用空状态', badge: '新生' },
    { id: 'low_balance', title: '余额不足', subtitle: '校园卡余额较低，验证余额提示', badge: '低余额' },
    { id: 'empty_campus', title: '空数据', subtitle: '课表、成绩、考试和失物招领均为空', badge: '空' },
    { id: 'network_error', title: '接口异常', subtitle: '标记为网络失败场景，供刷新错误态联调', badge: '错误' },
    { id: 'high_performer', title: '高绩点样例', subtitle: '优秀成绩与靠前绩点', badge: '高分' },
    { id: 'retake_student', title: '重修/补考样例', subtitle: '包含不及格、重修和补考课程', badge: '重修' },
    { id: 'busy_lost_found', title: '失物招领活跃', subtitle: '生成多条失物招领记录', badge: '分页' },
    { id: 'longhe_only', title: '龙河校区优先', subtitle: '课程集中在龙河校区', badge: '龙河' },
    { id: 'payment_gateway_issue', title: '支付网关异常', subtitle: '标记支付失败联调场景', badge: '支付' },
    { id: 'expired_login', title: '登录过期', subtitle: '标记登录态失效联调场景', badge: '登录' }
  ];

  private static dateText(date: Date): string {
    return `${date.getFullYear()}-${`${date.getMonth() + 1}`.padStart(2, '0')}-${`${date.getDate()}`.padStart(2, '0')}`;
  }

  private static weeks(): Array<number> {
    return Array.from({ length: 18 }, (_: Object, index: number) => index + 1);
  }

  private static courses(id: string): Array<Course> {
    if (id === 'empty_campus') return [];
    const location = id === 'longhe_only' || id === 'new_student' ? '龙河教学主楼 203' : '博学南楼 E201';
    const courses: Array<Course> = [
      { courseId: 'mock-1', name: '高等数学', teacher: '王老师', location: location, weekday: '1', startTime: '1', length: '2',
        startWeek: '1', endWeek: '18', weekIndexes: MockScenarioController.weeks() },
      { courseId: 'mock-2', name: '程序设计基础', teacher: '李老师', location: location, weekday: '3', startTime: '3', length: '2',
        startWeek: '1', endWeek: '18', weekIndexes: MockScenarioController.weeks() },
      { courseId: 'mock-3', name: id === 'exam_week' ? '考试答疑' : '大学英语', teacher: '陈老师', location: '博学北楼 B305',
        weekday: '5', startTime: '6', length: '2', startWeek: '1', endWeek: '18', weekIndexes: MockScenarioController.weeks() }
    ];
    return id === 'new_student' ? courses.slice(0, 1) : courses;
  }

  private static gradeItem(course: string, grade: string, point: string): GradeItem {
    return { course: course, credit: '3.0', grade: grade, gradePoint: point, courseType: '必修', semesterId: 1 };
  }

  private static grade(id: string): Grade {
    if (id === 'empty_campus' || id === 'new_student') return { termGradeList: [] };
    let items: Array<GradeItem> = [
      MockScenarioController.gradeItem('高等数学', '88', '3.8'),
      MockScenarioController.gradeItem('程序设计基础', '92', '4.2'),
      MockScenarioController.gradeItem('大学英语', '85', '3.5')
    ];
    if (id === 'high_performer') items = items.map((item: GradeItem): GradeItem => ({
      courseNum: item.courseNum, course: item.course, credit: item.credit, gradePoint: '4.6', grade: '96',
      courseType: item.courseType, semesterId: item.semesterId, gradeDetail: item.gradeDetail
    }));
    if (id === 'retake_student') items[0] = { courseNum: items[0].courseNum, course: items[0].course,
      credit: items[0].credit, gradePoint: '0', grade: '55', courseType: items[0].courseType,
      semesterId: items[0].semesterId, gradeDetail: '重修' };
    const term: TermGrade = { schoolYear: '2025-2026', schoolTerm: '2', termGradePoint: '35.1', termTotalCredit: '9',
      termGradePointAverage: id === 'high_performer' ? '4.60' : id === 'retake_student' ? '2.42' : '3.90', termGradeList: items };
    return { totalGradePoint: term.termGradePoint, totalCredit: term.termTotalCredit,
      totalGradePointAverage: term.termGradePointAverage, termGradeList: [term] };
  }

  private static exams(id: string): Array<Exam> {
    if (id === 'empty_campus' || id === 'new_student') return [];
    const result: Array<Exam> = [
      { course: '高等数学', location: '博学南楼 E201', time: '2026-07-18 09:00-11:00', seatNum: '18', finished: false },
      { course: '程序设计基础', location: '博学北楼 B305', time: '2026-07-20 14:00-16:00', seatNum: '06', finished: false }
    ];
    if (id === 'exam_week') result.push({ course: '大学英语', location: '博学南楼 E101', time: '2026-07-22 09:00-11:00', seatNum: '23', finished: false });
    return result;
  }

  private static lostFound(id: string): Array<LostFoundItem> {
    if (id === 'empty_campus') return [];
    const count = id === 'busy_lost_found' ? 12 : 2;
    return Array.from({ length: count }, (_: Object, index: number): LostFoundItem => ({
      id: `mock-lost-${index}`, title: index % 2 === 0 ? `在博学楼拾到校园卡 ${index + 1}` : `寻找黑色雨伞 ${index + 1}`,
      linkman: 'Mock 同学', phone: '13800000000', state: index % 2 === 0 ? 1 : 2, campusid: '1', campusName: '磬苑校区',
      createtime: '2026-07-15 12:00:00', imgs: [], pubuser: { idNumber: '2022000000', userName: 'Mock 同学' },
      lostType: { typeId: '1', typeName: '其他', typeState: '1' }
    }));
  }

  static apply(id: string): MockScenarioOption {
    const selected = MockScenarioController.scenarios.find((item: MockScenarioOption) => item.id === id)
      ?? MockScenarioController.scenarios[0];
    AhuCache.beginMockSession();
    AhuCache.saveMockScenario(selected.id);
    AhuCache.saveCurrentUser({ name: 'Mock 同学', xh: '2022000000' });
    AhuCache.setAgreementAccepted(); AhuCache.setPrivacyAccepted(); AhuCache.setBusinessAccepted();
    const now = AhuCache.now();
    const monday = new Date(now.getFullYear(), now.getMonth(), now.getDate() - ((now.getDay() + 6) % 7) - 35);
    AhuCache.saveSchoolYear('2025-2026'); AhuCache.saveSchoolTerm('2025-2026-2');
    AhuCache.saveSchoolTermStartTime('2025-2026', '2', MockScenarioController.dateText(monday));
    AhuCache.saveSchedule('2025-2026', '2', MockScenarioController.courses(selected.id));
    const mockGrade = MockScenarioController.grade(selected.id);
    AhuCache.saveGrade(mockGrade);
    AhuCache.saveGradeProfiles([{ id: 'mock-profile', trainingType: '主修', department: '计算机科学与技术学院', major: '软件工程' }]);
    const grades: Record<string, Grade> = {}; grades['mock-profile'] = mockGrade; AhuCache.saveGradesPerProfile(grades);
    const rank: GpaRankInfo = { id: 1, gpa: selected.id === 'high_performer' ? 4.6 : 3.9,
      majorRank: selected.id === 'high_performer' ? 2 : selected.id === 'retake_student' ? 96 : 18,
      majorHeadCount: 120, inPlanCredits: 80, outPlanCredits: 4, totalCredits: 84,
      gpaSemesterSubs: [{ gpa: selected.id === 'high_performer' ? 4.6 : 3.9, semesterId: 1,
        majorRank: selected.id === 'high_performer' ? 1 : 15, inPlanCredits: 20, outPlanCredits: 0, totalCredits: 20 }],
      updatedDateTimeStr: '2026-07-15 12:00' };
    AhuCache.saveGpaRank('mock-profile', rank);
    AhuCache.saveExams(MockScenarioController.exams(selected.id));
    AhuCache.saveCardBalance(selected.id === 'low_balance' ? 1.25 : selected.id === 'high_performer' ? 328.60 : 86.40);
    const lost = MockScenarioController.lostFound(selected.id);
    AhuCache.saveLostFoundList(1, lost.filter((item: LostFoundItem) => item.state === 1));
    AhuCache.saveLostFoundList(2, lost.filter((item: LostFoundItem) => item.state === 2));
    return selected;
  }

  static disable(): void { AhuCache.endMockSession(); }
}
