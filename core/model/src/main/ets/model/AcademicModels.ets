export interface Exam {
  course?: string;
  location?: string;
  time?: string;
  seatNum?: string;
  finished?: boolean;
}

export interface GradeItem {
  courseNum?: string;
  course?: string;
  credit?: string;
  gradePoint?: string;
  grade?: string;
  courseType?: string;
  semesterId: number;
  gradeDetail?: string;
}

export interface TermGrade {
  schoolYear?: string;
  schoolTerm?: string;
  termGradePoint?: string;
  termTotalCredit?: string;
  termGradePointAverage?: string;
  termGradeList?: Array<GradeItem>;
}

export interface Grade {
  totalGradePoint?: string;
  totalCredit?: string;
  totalGradePointAverage?: string;
  termGradeList?: Array<TermGrade>;
}

export interface GradeStudentProfile {
  id: string;
  trainingType: string;
  department: string;
  major: string;
}

export interface GpaSemesterSub {
  gpa: number;
  semesterId: number;
  majorRank: number;
  inPlanCredits: number;
  outPlanCredits: number;
  totalCredits: number;
}

export interface GpaRankInfo {
  id: number;
  gpa: number;
  majorRank: number;
  majorHeadCount: number;
  inPlanCredits: number;
  outPlanCredits: number;
  totalCredits: number;
  gpaSemesterSubs: Array<GpaSemesterSub>;
  updatedDateTimeStr: string;
  studentId?: number;
  bizTypeId?: number;
}

export interface CourseGrade {
  compulsory?: boolean;
  courseCode?: string;
  courseName?: string;
  courseNameEn?: string;
  courseProperty?: string;
  courseTaxon?: string;
  courseType?: string;
  credits?: number;
  gaGrade?: string;
  gp?: number;
  gradeDetail?: string;
  id?: number;
  lessonCode?: string;
  lessonName?: string;
  passed?: boolean;
  published?: boolean;
  semesterId?: number;
  semesterName?: string;
}

export interface GradeResponse {
  semesterId2studentGrades?: Record<string, Array<CourseGrade>>;
}
