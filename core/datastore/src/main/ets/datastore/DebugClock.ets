import { AhuPreferences, PreferencesKeys } from './AhuPreferences';

export class DebugClock {
  static isMocked(): boolean {
    return AhuPreferences.contains(PreferencesKeys.MOCK_CURRENT_TIME);
  }

  static nowMillis(): number {
    return DebugClock.isMocked() ?
      AhuPreferences.getNumber(PreferencesKeys.MOCK_CURRENT_TIME) : Date.now();
  }

  static now(): Date {
    return new Date(DebugClock.nowMillis());
  }

  static setMockTime(time?: number): void {
    if (time === undefined) {
      AhuPreferences.remove(PreferencesKeys.MOCK_CURRENT_TIME);
    } else {
      AhuPreferences.putNumber(PreferencesKeys.MOCK_CURRENT_TIME, time);
    }
  }
}
