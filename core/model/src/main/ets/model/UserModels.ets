export enum UserType {
  AHU_LOCAL = '0',
  AHU_WISDOM = '2'
}

export interface User {
  name: string;
  xh: string;
  type?: UserType;
}

export function getSchoolYears(user: User, currentDate: Date = new Date()): Array<string> {
  if (user.xh.length < 4) {
    return [];
  }
  const startYear = Number.parseInt(user.xh.substring(2, 4), 10) + 2000;
  if (!Number.isFinite(startYear)) {
    return [];
  }
  const academicYear = currentDate.getFullYear() - (currentDate.getMonth() < 8 ? 1 : 0);
  const years: Array<string> = [];
  for (let year = academicYear; year >= startYear; year--) {
    years.push(`${year}-${year + 1}`);
  }
  return years;
}
