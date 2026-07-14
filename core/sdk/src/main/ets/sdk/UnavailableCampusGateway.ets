import { AppErrorKind, AppResult, AppResults } from 'core_common';
import { Card, Course, Exam, User } from 'core_model';
import { CampusNativeGateway } from 'core_sdk_api';

export class UnavailableCampusGateway extends CampusNativeGateway {
  private unavailable<T>(): AppResult<T> {
    return AppResults.failure<T>(
      AppErrorKind.UNKNOWN,
      'HarmonyOS 原生校园 SDK 尚未接入'
    );
  }

  isNativeLoaded(): boolean {
    return false;
  }

  async initialize(cookiesJson: string): Promise<AppResult<boolean>> {
    return this.unavailable<boolean>();
  }

  async dumpCookies(): Promise<AppResult<string>> {
    return this.unavailable<string>();
  }

  async refreshToken(): Promise<AppResult<string>> {
    return this.unavailable<string>();
  }

  async login(username: string, password: string): Promise<AppResult<User>> {
    return this.unavailable<User>();
  }

  async getSchedule(): Promise<AppResult<Array<Course>>> {
    return this.unavailable<Array<Course>>();
  }

  async getExamInfo(): Promise<AppResult<Array<Exam>>> {
    return this.unavailable<Array<Exam>>();
  }

  async getGradeRaw(studentId?: string): Promise<AppResult<string>> {
    return this.unavailable<string>();
  }

  async getBalance(): Promise<AppResult<Card>> {
    return this.unavailable<Card>();
  }

  async getQrcode(): Promise<AppResult<string>> {
    return this.unavailable<string>();
  }

  async downloadSchoolCalendar(savePath: string): Promise<AppResult<boolean>> {
    return this.unavailable<boolean>();
  }

  clearSession(): void {}
}
