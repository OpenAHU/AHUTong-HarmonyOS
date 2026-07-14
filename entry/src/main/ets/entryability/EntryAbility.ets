import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AhuCache, AhuPreferences } from 'core_datastore';
import { CampusGatewayProvider } from 'core_sdk';
import { AuthRepositoryProvider } from 'data_auth';
import { ScheduleReminderCoordinator, ScheduleReminderCoordinatorProvider, ScheduleWidgetCoordinator,
  ScheduleWidgetCoordinatorProvider } from 'data_schedule';
import { CourseReminderManager } from 'feature_notification';
import { ScheduleWidgetManager } from 'feature_widget';

const DOMAIN = 0xA001;
const TAG = 'AHUTong';

class CourseScheduleReminderCoordinator implements ScheduleReminderCoordinator {
  reschedule(): void {
    CourseReminderManager.reschedule().catch(() => {});
  }
}

class CourseScheduleWidgetCoordinator implements ScheduleWidgetCoordinator {
  update(): void { ScheduleWidgetManager.updateAll().catch(() => {}); }
}

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    AhuPreferences.initialize(this.context);
    AppStorage.setOrCreate('ahu_theme_color', AhuCache.themeColor());
    AppStorage.setOrCreate('ahu_liquid_glass', AhuCache.useLiquidGlass());
    AppStorage.setOrCreate('ahu_logout_revision', 0);
    AppStorage.setOrCreate('ahu_home_edit_request', 0);
    CampusGatewayProvider.initialize();
    AuthRepositoryProvider.initialize(CampusGatewayProvider.get());
    ScheduleReminderCoordinatorProvider.initialize(new CourseScheduleReminderCoordinator());
    ScheduleWidgetCoordinatorProvider.initialize(new CourseScheduleWidgetCoordinator());
    CourseReminderManager.reschedule().catch(() => {});
    ScheduleWidgetManager.updateAll().catch(() => {});
    this.applyLaunchWant(want);
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, TAG, 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onDestroy');
  }

  onNewWant(want: Want): void {
    this.applyLaunchWant(want);
  }

  private applyLaunchWant(want: Want): void {
    const route = want.parameters?.['route'] as string;
    AppStorage.setOrCreate('ahu_launch_route', route === 'schedule' ? 'schedule' : '');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'Ability onBackground');
  }
}
