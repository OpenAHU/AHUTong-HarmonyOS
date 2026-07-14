import { AppResult } from 'core_common';
import { Card, Course, Exam, User } from 'core_model';

export abstract class CampusNativeGateway {
  abstract isNativeLoaded(): boolean;

  abstract initialize(cookiesJson: string): Promise<AppResult<boolean>>;

  abstract dumpCookies(): Promise<AppResult<string>>;

  abstract refreshToken(): Promise<AppResult<string>>;

  abstract login(username: string, password: string): Promise<AppResult<User>>;

  abstract getSchedule(): Promise<AppResult<Array<Course>>>;

  abstract getExamInfo(): Promise<AppResult<Array<Exam>>>;

  abstract getGradeRaw(studentId?: string): Promise<AppResult<string>>;

  abstract getBalance(): Promise<AppResult<Card>>;

  abstract getQrcode(): Promise<AppResult<string>>;

  abstract downloadSchoolCalendar(savePath: string): Promise<AppResult<boolean>>;

  abstract clearSession(): void;
}
