export { CORE_MODEL_VERSION } from './src/main/ets/model/CommonModels';
export { UserType, getSchoolYears } from './src/main/ets/model/UserModels';
export type { User } from './src/main/ets/model/UserModels';
export type { Course, ScheduleConfig } from './src/main/ets/model/ScheduleModels';
export { courseEndWeek, courseLength, courseOccursInWeek, courseStartTime, courseStartWeek, courseWeekday } from './src/main/ets/model/ScheduleModels';
export type {
  CourseGrade,
  Exam,
  Grade,
  GradeItem,
  GradeResponse,
  GradeStudentProfile,
  GpaRankInfo,
  GpaSemesterSub,
  TermGrade
} from './src/main/ets/model/AcademicModels';
export type {
  BathRoom,
  BathroomAccountData,
  BathroomTelInfo,
  CampusDataItem,
  CampusItem,
  Card,
  ElectricityChargeInfo,
  ElectricityDepositHistoryItem,
  RoomSelectionInfo,
  Tel
} from './src/main/ets/model/CampusModels';
export type {
  LostFoundImage,
  LostFoundItem,
  LostFoundPage,
  LostFoundPublishRequest,
  LostFoundResponse,
  LostFoundType,
  LostFoundUser
} from './src/main/ets/model/PortalModels';
export type { ApkUpdateInfo, LicenseInfo } from './src/main/ets/model/CommonModels';
export type { AirPollutants, ForecastDay, HourlyForecast, LifeIndexItem, LifeIndices, WeatherAlert, WeatherResponse } from './src/main/ets/model/WeatherModels';
