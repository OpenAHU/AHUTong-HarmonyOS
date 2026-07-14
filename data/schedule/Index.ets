import { CORE_COMMON_MODULE } from 'core_common';
import { CORE_MODEL_VERSION } from 'core_model';

export const DATA_SCHEDULE_MODULE: string = `${CORE_COMMON_MODULE}/data/schedule@${CORE_MODEL_VERSION}`;
export {
  ScheduleDisplayConfig,
  ScheduleSetupRepository,
  ScheduleSetupValues
} from './src/main/ets/schedule/ScheduleSetupRepository';
export {
  CrawlerScheduleSource,
  DefaultScheduleRepository,
  ScheduleRepository,
  ScheduleRepositoryProvider
} from './src/main/ets/schedule/ScheduleRepository';
export {
  ScheduleReminderCoordinator,
  ScheduleReminderCoordinatorProvider
} from './src/main/ets/schedule/ScheduleReminderCoordinator';
