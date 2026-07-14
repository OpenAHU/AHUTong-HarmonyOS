import { preferences } from '@kit.ArkData';

export class PreferencesKeys {
  static readonly CURRENT_USER: string = 'current_user';
  static readonly AGREEMENT_ACCEPTED: string = 'agreement_accepted';
  static readonly PRIVACY_ACCEPTED: string = 'privacy_accepted';
  static readonly BUSINESS_ACCEPTED: string = 'business_accepted';
  static readonly SCHOOL_YEAR: string = 'default_school_year';
  static readonly SCHOOL_TERM: string = 'default_school_term';
  static readonly SCHOOL_TERM_START_TIME: string = 'school_term_start_time';
  static readonly SHOW_ALL_COURSE: string = 'is_show_all_course';
  static readonly SHOW_QR_CODE: string = 'show_qr_code';
  static readonly USE_LIQUID_GLASS: string = 'use_liquid_glass';
  static readonly COURSE_REMINDER_ENABLED: string = 'course_reminder_enabled';
  static readonly LIVE_COUNTDOWN_ENABLED: string = 'course_reminder_live_countdown_enabled';
  static readonly THEME_COLOR: string = 'theme_color_hex';
  static readonly MOCK_CURRENT_TIME: string = 'mock_current_time';
  static readonly HOME_WIDGET_SLOTS: string = 'home_widget_slots';
  static readonly GRADE_CACHE: string = 'grade_cache';
  static readonly EXAM_CACHE: string = 'exam_cache';
  static readonly CARD_BALANCE: string = 'card_balance';
  static readonly LOST_FOUND_LIST: string = 'lost_found_list';
}

export class AhuPreferences {
  private static store?: preferences.Preferences;

  static initialize(context: Context): void {
    if (AhuPreferences.store) {
      return;
    }
    try {
      AhuPreferences.store = preferences.getPreferencesSync(context, { name: 'ahu_preferences' });
    } catch (_) {
      throw new Error('Failed to initialize AHUTong preferences');
    }
  }

  private static requireStore(): preferences.Preferences {
    if (!AhuPreferences.store) {
      throw new Error('AhuPreferences is not initialized');
    }
    return AhuPreferences.store;
  }

  static contains(key: string): boolean {
    try {
      return AhuPreferences.requireStore().hasSync(key);
    } catch (_) {
      return false;
    }
  }

  static getString(key: string, defaultValue: string = ''): string {
    try {
      return AhuPreferences.requireStore().getSync(key, defaultValue) as string;
    } catch (_) {
      return defaultValue;
    }
  }

  static getBoolean(key: string, defaultValue: boolean = false): boolean {
    try {
      return AhuPreferences.requireStore().getSync(key, defaultValue) as boolean;
    } catch (_) {
      return defaultValue;
    }
  }

  static getNumber(key: string, defaultValue: number = 0): number {
    try {
      return AhuPreferences.requireStore().getSync(key, defaultValue) as number;
    } catch (_) {
      return defaultValue;
    }
  }

  static putString(key: string, value: string): void {
    try {
      const store = AhuPreferences.requireStore();
      store.putSync(key, value);
      store.flushSync();
    } catch (_) {
      throw new Error(`Failed to persist preference: ${key}`);
    }
  }

  static putBoolean(key: string, value: boolean): void {
    try {
      const store = AhuPreferences.requireStore();
      store.putSync(key, value);
      store.flushSync();
    } catch (_) {
      throw new Error(`Failed to persist preference: ${key}`);
    }
  }

  static putNumber(key: string, value: number): void {
    try {
      const store = AhuPreferences.requireStore();
      store.putSync(key, value);
      store.flushSync();
    } catch (_) {
      throw new Error(`Failed to persist preference: ${key}`);
    }
  }

  static remove(key: string): void {
    try {
      const store = AhuPreferences.requireStore();
      store.deleteSync(key);
      store.flushSync();
    } catch (_) {
      throw new Error(`Failed to remove preference: ${key}`);
    }
  }

  static clear(): void {
    try {
      const store = AhuPreferences.requireStore();
      store.clearSync();
      store.flushSync();
    } catch (_) {
      throw new Error('Failed to clear AHUTong preferences');
    }
  }
}
