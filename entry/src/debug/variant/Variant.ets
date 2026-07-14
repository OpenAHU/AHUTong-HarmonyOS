import { common } from '@kit.AbilityKit';
import { DebugPage } from 'feature_debug';
import { CourseReminderManager } from 'feature_notification';
import { AppMaintenance } from 'entry/ets/app/AppMaintenance';
import { AppRoot } from 'entry/ets/pages/AppRoot';

@Component
export struct VariantRoot {
  private increment(key: string): void {
    AppStorage.setOrCreate(key, (AppStorage.get<number>(key) ?? 0) + 1);
  }

  @Builder private debugContent() {
    DebugPage({
      onBack: () => this.increment('ahu_debug_close_revision'),
      onDataChanged: () => this.increment('ahu_mock_revision'),
      onGrayStateChanged: () => this.increment('ahu_gray_revision'),
      onClearData: async () => {
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        await AppMaintenance.logout(context, true);
        this.increment('ahu_logout_revision');
      },
      onTestReminder: (seconds: number) => {
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        return CourseReminderManager.scheduleDebug(context, seconds);
      }
    });
  }

  build() { AppRoot({ debugEnabled: true, debugContent: this.debugContent }); }
}
