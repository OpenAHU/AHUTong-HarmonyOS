import { AhuCache } from 'core_datastore';

export interface ScheduleSetupValues {
  schoolYear: string;
  schoolTerm: string;
  currentWeek: number;
}

export class ScheduleSetupRepository {
  hasCompletedSetup(): boolean {
    return AhuCache.getSchoolYear() !== undefined && AhuCache.getSchoolTerm() !== undefined;
  }

  defaultValues(now: Date = new Date()): ScheduleSetupValues {
    const month = now.getMonth() + 1;
    const startYear = month >= 9 ? now.getFullYear() : now.getFullYear() - 1;
    const term = month >= 7 && month <= 8 ? '3' : month >= 2 && month <= 6 ? '2' : '1';
    return {
      schoolYear: AhuCache.getSchoolYear() ?? `${startYear}-${startYear + 1}`,
      schoolTerm: this.cachedTerm() ?? term,
      currentWeek: 1
    };
  }

  private cachedTerm(): string | undefined {
    const semester = AhuCache.getSchoolTerm();
    if (!semester) {
      return undefined;
    }
    const pieces = semester.split('-');
    return pieces.length >= 3 ? pieces[pieces.length - 1] : semester;
  }

  save(values: ScheduleSetupValues, now: Date = new Date()): void {
    const normalizedYear = values.schoolYear.trim();
    const normalizedTerm = values.schoolTerm.trim();
    const week = Math.max(1, Math.min(30, values.currentWeek));
    AhuCache.saveSchoolYear(normalizedYear);
    AhuCache.saveSchoolTerm(`${normalizedYear}-${normalizedTerm}`);

    const mondayOffset = (now.getDay() + 6) % 7;
    const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    start.setDate(start.getDate() - mondayOffset - (week - 1) * 7);
    const month = `${start.getMonth() + 1}`.padStart(2, '0');
    const day = `${start.getDate()}`.padStart(2, '0');
    AhuCache.saveSchoolTermStartTime(normalizedYear, normalizedTerm,
      `${start.getFullYear()}-${month}-${day}`);
  }
}
