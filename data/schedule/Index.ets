import { CORE_COMMON_MODULE } from 'core_common';
import { CORE_MODEL_VERSION } from 'core_model';

export const DATA_SCHEDULE_MODULE: string = `${CORE_COMMON_MODULE}/data/schedule@${CORE_MODEL_VERSION}`;
export { ScheduleSetupRepository, ScheduleSetupValues } from './src/main/ets/schedule/ScheduleSetupRepository';
