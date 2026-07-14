import { CampusItem, Course, Exam, Grade, LostFoundItem, LostFoundType, User, WeatherResponse } from 'core_model';
import { AhuPreferences, PreferencesKeys } from './AhuPreferences';

export class AhuCache {
  private static sanitize(value: string): string {
    return value.replace(/[^A-Za-z0-9_.-]/g, '_');
  }

  private static currentUserId(): string {
    const user = AhuCache.getCurrentUser();
    return user && user.xh.length > 0 ? AhuCache.sanitize(user.xh) : 'guest';
  }

  private static userKey(key: string): string {
    return `user:${AhuCache.currentUserId()}:${key}`;
  }

  static saveCurrentUser(user: User): void {
    AhuPreferences.putString(PreferencesKeys.CURRENT_USER, JSON.stringify(user));
  }

  static getCurrentUser(): User | undefined {
    const raw = AhuPreferences.getString(PreferencesKeys.CURRENT_USER);
    if (raw.length === 0) {
      return undefined;
    }
    try {
      return JSON.parse(raw) as User;
    } catch (_) {
      return undefined;
    }
  }

  static isLogin(): boolean {
    return AhuCache.getCurrentUser() !== undefined;
  }

  static clearCurrentUser(): void {
    AhuPreferences.remove(PreferencesKeys.CURRENT_USER);
  }

  static setAgreementAccepted(value: boolean = true): void {
    AhuPreferences.putBoolean(PreferencesKeys.AGREEMENT_ACCEPTED, value);
  }

  static isAgreementAccepted(): boolean {
    return AhuPreferences.getBoolean(PreferencesKeys.AGREEMENT_ACCEPTED);
  }

  static setPrivacyAccepted(value: boolean = true): void {
    AhuPreferences.putBoolean(PreferencesKeys.PRIVACY_ACCEPTED, value);
  }

  static isPrivacyAccepted(): boolean {
    return AhuPreferences.getBoolean(PreferencesKeys.PRIVACY_ACCEPTED);
  }

  static setBusinessAccepted(value: boolean = true): void {
    AhuPreferences.putBoolean(PreferencesKeys.BUSINESS_ACCEPTED, value);
  }

  static isBusinessAccepted(): boolean {
    return AhuPreferences.getBoolean(PreferencesKeys.BUSINESS_ACCEPTED);
  }

  static saveSchoolYear(schoolYear: string): void {
    AhuPreferences.putString(AhuCache.userKey(PreferencesKeys.SCHOOL_YEAR), schoolYear);
  }

  static getSchoolYear(): string | undefined {
    const value = AhuPreferences.getString(AhuCache.userKey(PreferencesKeys.SCHOOL_YEAR));
    return value.length > 0 ? value : undefined;
  }

  static saveSchoolTerm(schoolTerm: string): void {
    AhuPreferences.putString(AhuCache.userKey(PreferencesKeys.SCHOOL_TERM), schoolTerm);
  }

  static getSchoolTerm(): string | undefined {
    const value = AhuPreferences.getString(AhuCache.userKey(PreferencesKeys.SCHOOL_TERM));
    return value.length > 0 ? value : undefined;
  }

  static saveSchoolTermStartTime(schoolYear: string, schoolTerm: string, startTime: string): void {
    AhuPreferences.putString(
      AhuCache.userKey(`${PreferencesKeys.SCHOOL_TERM_START_TIME}:${schoolYear}:${schoolTerm}`),
      startTime
    );
  }

  static getSchoolTermStartTime(schoolYear: string, schoolTerm: string): string | undefined {
    const value = AhuPreferences.getString(
      AhuCache.userKey(`${PreferencesKeys.SCHOOL_TERM_START_TIME}:${schoolYear}:${schoolTerm}`)
    );
    return value.length > 0 ? value : undefined;
  }

  static saveSchedule(schoolYear: string, schoolTerm: string, schedule: Array<Course>): void {
    AhuPreferences.putString(AhuCache.userKey(`${schoolYear}-${schoolTerm}.schedule`), JSON.stringify(schedule));
  }

  static getSchedule(schoolYear: string, schoolTerm: string): Array<Course> {
    const raw = AhuPreferences.getString(AhuCache.userKey(`${schoolYear}-${schoolTerm}.schedule`));
    if (raw.length === 0) {
      return [];
    }
    try {
      return JSON.parse(raw) as Array<Course>;
    } catch (_) {
      return [];
    }
  }

  static saveIsShowAllCourse(value: boolean): void {
    AhuPreferences.putBoolean(AhuCache.userKey(PreferencesKeys.SHOW_ALL_COURSE), value);
  }

  static isShowAllCourse(): boolean {
    return AhuPreferences.getBoolean(AhuCache.userKey(PreferencesKeys.SHOW_ALL_COURSE));
  }

  static getHomeWidgetSlots(): Array<string> {
    const raw = AhuPreferences.getString(AhuCache.userKey(PreferencesKeys.HOME_WIDGET_SLOTS));
    if (raw.length === 0) {
      return ['bathroom', 'electricity', '', '', '', '', '', ''];
    }
    try {
      const slots = JSON.parse(raw) as Array<string>;
      return Array.from({ length: 8 }, (_: Object, index: number) => slots[index] ?? '');
    } catch (_) {
      return ['bathroom', 'electricity', '', '', '', '', '', ''];
    }
  }

  static saveHomeWidgetSlots(slots: Array<string>): void {
    const normalized = Array.from({ length: 8 }, (_: Object, index: number) => slots[index] ?? '');
    AhuPreferences.putString(AhuCache.userKey(PreferencesKeys.HOME_WIDGET_SLOTS), JSON.stringify(normalized));
  }

  static saveGrade(grade: Grade): void {
    AhuPreferences.putString(AhuCache.userKey(PreferencesKeys.GRADE_CACHE), JSON.stringify(grade));
  }

  static getGrade(): Grade | undefined {
    const raw = AhuPreferences.getString(AhuCache.userKey(PreferencesKeys.GRADE_CACHE));
    if (raw.length === 0) {
      return undefined;
    }
    try {
      return JSON.parse(raw) as Grade;
    } catch (_) {
      return undefined;
    }
  }

  static saveExams(exams: Array<Exam>): void {
    AhuPreferences.putString(AhuCache.userKey(PreferencesKeys.EXAM_CACHE), JSON.stringify(exams));
  }

  static getExams(): Array<Exam> {
    const raw = AhuPreferences.getString(AhuCache.userKey(PreferencesKeys.EXAM_CACHE));
    if (raw.length === 0) return [];
    try { return JSON.parse(raw) as Array<Exam>; } catch (_) { return []; }
  }

  static saveCardBalance(balance: number): void {
    AhuPreferences.putNumber(AhuCache.userKey(PreferencesKeys.CARD_BALANCE), balance);
  }

  static getCardBalance(): number | undefined {
    const key = AhuCache.userKey(PreferencesKeys.CARD_BALANCE);
    return AhuPreferences.contains(key) ? AhuPreferences.getNumber(key) : undefined;
  }

  static saveLostFoundList(state: number, items: Array<LostFoundItem>): void {
    AhuPreferences.putString(AhuCache.userKey(`${PreferencesKeys.LOST_FOUND_LIST}:${state}`), JSON.stringify(items));
  }

  static getLostFoundList(state: number): Array<LostFoundItem> {
    const raw = AhuPreferences.getString(AhuCache.userKey(`${PreferencesKeys.LOST_FOUND_LIST}:${state}`));
    if (raw.length === 0) return [];
    try { return JSON.parse(raw) as Array<LostFoundItem>; } catch (_) { return []; }
  }

  static saveLostFoundCampuses(items: Array<CampusItem>): void {
    AhuPreferences.putString(PreferencesKeys.LOST_FOUND_CAMPUSES, JSON.stringify(items));
  }

  static getLostFoundCampuses(): Array<CampusItem> {
    const raw = AhuPreferences.getString(PreferencesKeys.LOST_FOUND_CAMPUSES);
    if (raw.length === 0) return [];
    try { return JSON.parse(raw) as Array<CampusItem>; } catch (_) { return []; }
  }

  static saveLostFoundTypes(items: Array<LostFoundType>): void {
    AhuPreferences.putString(PreferencesKeys.LOST_FOUND_TYPES, JSON.stringify(items));
  }

  static getLostFoundTypes(): Array<LostFoundType> {
    const raw = AhuPreferences.getString(PreferencesKeys.LOST_FOUND_TYPES);
    if (raw.length === 0) return [];
    try { return JSON.parse(raw) as Array<LostFoundType>; } catch (_) { return []; }
  }

  static saveWeather(weather: WeatherResponse): void {
    AhuPreferences.putString(PreferencesKeys.WEATHER_CACHE, JSON.stringify(weather));
    if (weather.adcode) AhuPreferences.putString(PreferencesKeys.WEATHER_ADCODE, weather.adcode);
  }

  static getWeather(): WeatherResponse | undefined {
    const raw = AhuPreferences.getString(PreferencesKeys.WEATHER_CACHE);
    if (raw.length === 0) return undefined;
    try { return JSON.parse(raw) as WeatherResponse; } catch (_) { return undefined; }
  }

  static getWeatherAdcode(): string | undefined {
    const value = AhuPreferences.getString(PreferencesKeys.WEATHER_ADCODE);
    return value.length > 0 ? value : undefined;
  }

  static saveWeatherShowOnHome(enabled: boolean): void {
    AhuPreferences.putBoolean(PreferencesKeys.WEATHER_SHOW_ON_HOME, enabled);
  }

  static getWeatherShowOnHome(): boolean {
    return AhuPreferences.getBoolean(PreferencesKeys.WEATHER_SHOW_ON_HOME);
  }

  static logout(): void {
    AhuCache.clearCurrentUser();
  }

  static clearAll(): void {
    AhuPreferences.clear();
  }
}
