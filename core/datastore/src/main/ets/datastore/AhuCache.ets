import { CampusItem, Course, ElectricityChargeInfo, Exam, GpaRankInfo, Grade, GradeStudentProfile, LostFoundItem, LostFoundType, User, WeatherResponse } from 'core_model';
import { AhuPreferences, PreferencesKeys } from './AhuPreferences';
import { normalizeHomeWidgetSlots } from './HomeWidgetSlots';

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

  static saveNextSchedule(schedule: Array<Course>): void {
    AhuPreferences.putString(AhuCache.userKey(PreferencesKeys.NEXT_SCHEDULE), JSON.stringify(schedule));
  }

  static getNextSchedule(): Array<Course> | undefined {
    const raw = AhuPreferences.getString(AhuCache.userKey(PreferencesKeys.NEXT_SCHEDULE));
    if (raw.length === 0) return undefined;
    try { return JSON.parse(raw) as Array<Course>; } catch (_) { return undefined; }
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
      return normalizeHomeWidgetSlots(slots);
    } catch (_) {
      return ['bathroom', 'electricity', '', '', '', '', '', ''];
    }
  }

  static saveHomeWidgetSlots(slots: Array<string>): void {
    const normalized = normalizeHomeWidgetSlots(slots);
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

  static saveGradeProfiles(profiles: Array<GradeStudentProfile>): void {
    AhuPreferences.putString(AhuCache.userKey(PreferencesKeys.GRADE_PROFILES), JSON.stringify(profiles));
  }
  static getGradeProfiles(): Array<GradeStudentProfile> {
    const raw = AhuPreferences.getString(AhuCache.userKey(PreferencesKeys.GRADE_PROFILES));
    try { return raw.length > 0 ? JSON.parse(raw) as Array<GradeStudentProfile> : []; } catch (_) { return []; }
  }
  static saveGradesPerProfile(grades: Record<string, Grade>): void {
    AhuPreferences.putString(AhuCache.userKey(PreferencesKeys.GRADE_PER_PROFILE), JSON.stringify(grades));
  }
  static getGradesPerProfile(): Record<string, Grade> {
    const raw = AhuPreferences.getString(AhuCache.userKey(PreferencesKeys.GRADE_PER_PROFILE));
    try { return raw.length > 0 ? JSON.parse(raw) as Record<string, Grade> : {}; } catch (_) { return {}; }
  }
  static saveGpaRank(profileId: string, rank: GpaRankInfo): void {
    const values = AhuCache.getGpaRanks(); values[profileId] = rank;
    AhuPreferences.putString(AhuCache.userKey(PreferencesKeys.GPA_RANK_CACHE), JSON.stringify(values));
  }
  static getGpaRank(profileId: string): GpaRankInfo | undefined { return AhuCache.getGpaRanks()[profileId]; }
  private static getGpaRanks(): Record<string, GpaRankInfo> {
    const raw = AhuPreferences.getString(AhuCache.userKey(PreferencesKeys.GPA_RANK_CACHE));
    try { return raw.length > 0 ? JSON.parse(raw) as Record<string, GpaRankInfo> : {}; } catch (_) { return {}; }
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

  static saveWeatherShowLocation(enabled: boolean): void {
    AhuPreferences.putBoolean(PreferencesKeys.WEATHER_SHOW_LOCATION, enabled);
  }
  static getWeatherShowLocation(): boolean {
    return AhuPreferences.getBoolean(PreferencesKeys.WEATHER_SHOW_LOCATION, true);
  }
  static saveWeatherShowTemperature(enabled: boolean): void {
    AhuPreferences.putBoolean(PreferencesKeys.WEATHER_SHOW_TEMPERATURE, enabled);
  }
  static getWeatherShowTemperature(): boolean {
    return AhuPreferences.getBoolean(PreferencesKeys.WEATHER_SHOW_TEMPERATURE, true);
  }
  static saveWeatherShowCondition(enabled: boolean): void {
    AhuPreferences.putBoolean(PreferencesKeys.WEATHER_SHOW_CONDITION, enabled);
  }
  static getWeatherShowCondition(): boolean {
    return AhuPreferences.getBoolean(PreferencesKeys.WEATHER_SHOW_CONDITION, true);
  }
  static saveWeatherShowAqi(enabled: boolean): void {
    AhuPreferences.putBoolean(PreferencesKeys.WEATHER_SHOW_AQI, enabled);
  }
  static getWeatherShowAqi(): boolean {
    return AhuPreferences.getBoolean(PreferencesKeys.WEATHER_SHOW_AQI, true);
  }

  static setUseLiquidGlass(enabled: boolean): void { AhuPreferences.putBoolean(PreferencesKeys.USE_LIQUID_GLASS, enabled); }
  static useLiquidGlass(): boolean { return AhuPreferences.getBoolean(PreferencesKeys.USE_LIQUID_GLASS, true); }
  static setCourseReminderEnabled(enabled: boolean): void {
    AhuPreferences.putBoolean(PreferencesKeys.COURSE_REMINDER_ENABLED, enabled);
  }
  static courseReminderEnabled(): boolean { return AhuPreferences.getBoolean(PreferencesKeys.COURSE_REMINDER_ENABLED); }
  static setLiveCountdownEnabled(enabled: boolean): void {
    AhuPreferences.putBoolean(PreferencesKeys.LIVE_COUNTDOWN_ENABLED, enabled);
  }
  static liveCountdownEnabled(): boolean { return AhuPreferences.getBoolean(PreferencesKeys.LIVE_COUNTDOWN_ENABLED); }
  static setThemeColor(value: string): void { AhuPreferences.putString(PreferencesKeys.THEME_COLOR, value); }
  static themeColor(): string { return AhuPreferences.getString(PreferencesKeys.THEME_COLOR); }
  static saveScheduleWidgetIds(ids: Array<string>): void {
    AhuPreferences.putString(PreferencesKeys.SCHEDULE_WIDGET_IDS, JSON.stringify(ids));
  }
  static getScheduleWidgetIds(): Array<string> {
    const raw = AhuPreferences.getString(PreferencesKeys.SCHEDULE_WIDGET_IDS);
    if (raw.length === 0) return [];
    try { return JSON.parse(raw) as Array<string>; } catch (_) { return []; }
  }
  static saveElectricityRoomHistory(value: string): void {
    AhuPreferences.putString(AhuCache.userKey(PreferencesKeys.ELECTRICITY_ROOM_HISTORY), value);
  }
  static getElectricityRoomHistory(): string {
    return AhuPreferences.getString(AhuCache.userKey(PreferencesKeys.ELECTRICITY_ROOM_HISTORY));
  }

  static saveElectricityChargeInfo(value: ElectricityChargeInfo): void {
    AhuPreferences.putString(AhuCache.userKey(PreferencesKeys.ELECTRICITY_CHARGE_INFO), JSON.stringify(value));
  }
  static getElectricityChargeInfo(): ElectricityChargeInfo | undefined {
    const raw = AhuPreferences.getString(AhuCache.userKey(PreferencesKeys.ELECTRICITY_CHARGE_INFO));
    if (raw.length === 0) return undefined;
    try { return JSON.parse(raw) as ElectricityChargeInfo; } catch (_) { return undefined; }
  }
  static clearElectricityChargeInfo(): void {
    AhuPreferences.remove(AhuCache.userKey(PreferencesKeys.ELECTRICITY_CHARGE_INFO));
  }

  static saveBathroomLastPhone(value: string): void {
    AhuPreferences.putString(AhuCache.userKey(PreferencesKeys.BATHROOM_LAST_PHONE), value);
  }
  static getBathroomLastPhone(): string | undefined {
    const value = AhuPreferences.getString(AhuCache.userKey(PreferencesKeys.BATHROOM_LAST_PHONE));
    return value.length > 0 ? value : undefined;
  }

  static setMockData(enabled: boolean): void { AhuPreferences.putBoolean(PreferencesKeys.MOCK_DATA, enabled); }
  static getMockData(): boolean { return AhuPreferences.getBoolean(PreferencesKeys.MOCK_DATA); }
  static beginMockSession(): void {
    if (AhuCache.getMockData()) return;
    const user = AhuCache.getCurrentUser();
    if (user) AhuPreferences.putString(PreferencesKeys.MOCK_PREVIOUS_USER, JSON.stringify(user));
    else AhuPreferences.remove(PreferencesKeys.MOCK_PREVIOUS_USER);
    AhuCache.setMockData(true);
  }
  static endMockSession(): void {
    const raw = AhuPreferences.getString(PreferencesKeys.MOCK_PREVIOUS_USER);
    if (raw.length > 0) {
      try { AhuCache.saveCurrentUser(JSON.parse(raw) as User); }
      catch (_) { AhuCache.clearCurrentUser(); }
    } else {
      AhuCache.clearCurrentUser();
    }
    AhuPreferences.remove(PreferencesKeys.MOCK_PREVIOUS_USER);
    AhuCache.setMockData(false);
    AhuCache.clearMockCurrentTimeMillis();
  }
  static saveMockScenario(id: string): void { AhuPreferences.putString(PreferencesKeys.MOCK_SCENARIO, id); }
  static getMockScenario(): string { return AhuPreferences.getString(PreferencesKeys.MOCK_SCENARIO, 'standard_student'); }
  static saveMockCurrentTimeMillis(value: number): void {
    AhuPreferences.putNumber(PreferencesKeys.MOCK_CURRENT_TIME, value);
  }
  static getMockCurrentTimeMillis(): number | undefined {
    return AhuPreferences.contains(PreferencesKeys.MOCK_CURRENT_TIME)
      ? AhuPreferences.getNumber(PreferencesKeys.MOCK_CURRENT_TIME) : undefined;
  }
  static clearMockCurrentTimeMillis(): void { AhuPreferences.remove(PreferencesKeys.MOCK_CURRENT_TIME); }
  static now(): Date { return new Date(AhuCache.getMockCurrentTimeMillis() ?? Date.now()); }

  static logout(): void {
    AhuCache.clearCurrentUser();
  }

  static clearAll(): void {
    AhuPreferences.clear();
  }
}
