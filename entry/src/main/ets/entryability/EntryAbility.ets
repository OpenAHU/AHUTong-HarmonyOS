import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AhuCache, AhuPreferences } from 'core_datastore';
import { CampusGatewayProvider } from 'core_sdk';
import { AuthRepositoryProvider } from 'data_auth';
import { ScheduleReminderCoordinator, ScheduleReminderCoordinatorProvider } from 'data_schedule';
import { CourseReminderManager } from 'feature_notification';

const DOMAIN = 0x0000;

class CourseScheduleReminderCoordinator implements ScheduleReminderCoordinator {
  reschedule(): void {
    CourseReminderManager.reschedule().catch(() => {});
  }
}

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    AhuPreferences.initialize(this.context);
    AppStorage.setOrCreate('ahu_theme_color', AhuCache.themeColor());
    AppStorage.setOrCreate('ahu_liquid_glass', AhuCache.useLiquidGlass());
    AppStorage.setOrCreate('ahu_logout_revision', 0);
    CampusGatewayProvider.initialize();
    AuthRepositoryProvider.initialize(CampusGatewayProvider.get());
    ScheduleReminderCoordinatorProvider.initialize(new CourseScheduleReminderCoordinator());
    CourseReminderManager.reschedule().catch(() => {});
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
