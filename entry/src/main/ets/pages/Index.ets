import { AhuColors } from 'core_designsystem';
import { SymbolGlyphModifier } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { AppLaunchGate } from 'feature_login';
import { ScheduleSetupPage, WeeklySchedulePage } from 'feature_schedule';
import { HomePage } from 'feature_home';
import { GradePage } from 'feature_grade';
import { ExamPage } from 'feature_exam';
import { SchoolCalendarPage } from 'feature_calendar';
import { FreeClassroomPage } from 'feature_classroom';
import { BathroomRechargePage, CardRechargePage, ElectricityRechargePage } from 'feature_payment';
import { ScheduleSetupRepository } from 'data_schedule';
import { LostFoundPage } from 'feature_portal';
import { PhoneBookPage, ToolsPage } from 'feature_tools';
import { WeatherPage } from 'feature_weather';
import { RepositoryPage } from 'feature_repository';
import { SettingsPage } from 'feature_settings';
import { CourseReminderManager } from 'feature_notification';
import { AppUpdateDialog, AppUpdateManager, AppUpdateStatus } from 'feature_update';
import type { AppUpdateInfo } from 'feature_update';
import { DebugPage } from 'feature_debug';
import BuildProfile from 'BuildProfile';
import { AuthRepositoryProvider } from 'data_auth';
import { AhuCache } from 'core_datastore';
import { fileIo as fs } from '@kit.CoreFileKit';

@Entry
@Component
struct Index {
  @State selectedIndex: number = 0;
  @State setupComplete: boolean = false;
  @State activePage: string = '';
  @State updateInfo: AppUpdateInfo | undefined = undefined;
  @State updateMessage: string = '';
  @StorageLink('ahu_liquid_glass') useLiquidGlass: boolean = true;
  @StorageLink('ahu_launch_route') @Watch('onLaunchRouteChanged') launchRoute: string = '';
  private readonly scheduleSetupRepository: ScheduleSetupRepository = new ScheduleSetupRepository();

  private async logout(clearAll: boolean): Promise<void> {
    await AuthRepositoryProvider.get().logout();
    if (clearAll) {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const downloadDir = `${context.filesDir}/repository`;
      try {
        fs.listFileSync(downloadDir).forEach((name: string) => {
          try { fs.unlinkSync(`${downloadDir}/${name}`); } catch (_) {}
        });
        fs.rmdirSync(downloadDir);
      } catch (_) {}
      AhuCache.clearAll();
    }
    this.setupComplete = false;
    const revision = AppStorage.get<number>('ahu_logout_revision') ?? 0;
    AppStorage.setOrCreate('ahu_logout_revision', revision + 1);
  }

  aboutToAppear(): void {
    this.setupComplete = this.scheduleSetupRepository.hasCompletedSetup();
    this.onLaunchRouteChanged();
    this.checkUpdate(false);
  }

  private async checkUpdate(manual: boolean): Promise<string> {
    const result = await AppUpdateManager.check();
    if (result.status === AppUpdateStatus.AVAILABLE && result.update) {
      this.updateInfo = result.update;
      this.updateMessage = '';
    }
    return manual ? result.message : '';
  }

  private async openAppGallery(): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    if (!await AppUpdateManager.openAppGallery(context)) this.updateMessage = '未找到应用市场，请使用项目发行页。';
  }

  private async openReleasePage(): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    if (!await AppUpdateManager.openReleasePage(context, this.updateInfo)) this.updateMessage = '无法打开项目发行页，请检查浏览器。';
  }

  private onLaunchRouteChanged(): void {
    if (this.launchRoute === 'schedule') this.selectedIndex = 1;
  }

  private terminateApplication(): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    try {
      context.terminateSelf();
    } catch (_) {
    }
  }

  @Builder
  private mainContent() {
    Tabs({ barPosition: BarPosition.End, index: this.selectedIndex }) {
      TabContent() {
        HomePage({
          onOpenSchedule: () => {
            this.selectedIndex = 1;
          },
          onOpenWidget: (route: string) => {
            if (route === 'grade' || route === 'exam' || route === 'school_calendar' || route === 'free_classroom' || route === 'bathroom' || route === 'electricity' || route === 'lost_found' || route === 'phone_book' || route === 'weather' || route === 'repository') {
              this.activePage = route;
            }
          },
          onOpenRecharge: () => {
            this.activePage = 'card_recharge';
          }
        });
      }
      .tabBar(new BottomTabBarStyle({
        normal: new SymbolGlyphModifier($r('sys.symbol.house')),
        selected: new SymbolGlyphModifier($r('sys.symbol.house_fill'))
      }, $r('app.string.nav_home')));

      TabContent() {
        WeeklySchedulePage();
      }
      .tabBar(new BottomTabBarStyle({
        normal: new SymbolGlyphModifier($r('sys.symbol.calendar')),
        selected: new SymbolGlyphModifier($r('sys.symbol.calendar_fill'))
      }, $r('app.string.nav_schedule')));

      TabContent() {
        ToolsPage({ onOpenWidget: (route: string) => { this.activePage = route; } });
      }
      .tabBar(new BottomTabBarStyle({
        normal: new SymbolGlyphModifier($r('sys.symbol.wrench_and_screwdriver')),
        selected: new SymbolGlyphModifier($r('sys.symbol.wrench_and_screwdriver_fill'))
      }, $r('app.string.nav_tools')));

      TabContent() {
        SettingsPage({
          appVersion: AppUpdateManager.currentVersion(),
          onLogout: () => this.logout(false),
          onClearAllData: () => this.logout(true),
          onReminderChange: (enabled: boolean) => {
            const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
            return CourseReminderManager.setEnabled(context, enabled);
          },
          onReconfigureTerm: () => { this.activePage = 'term_setup'; },
          onCheckUpdate: () => this.checkUpdate(true),
          onLoadUpdateIntro: () => AppUpdateManager.introduction(),
          debugEnabled: BuildProfile.DEBUG,
          onOpenDebug: () => { this.activePage = 'debug'; }
        });
      }
      .tabBar(new BottomTabBarStyle({
        normal: new SymbolGlyphModifier($r('sys.symbol.gearshape')),
        selected: new SymbolGlyphModifier($r('sys.symbol.gearshape_fill'))
      }, $r('app.string.nav_settings')));
    }
    .width('100%')
    .height('100%')
    .scrollable(false)
    .barMode(BarMode.Fixed)
    .barOverlap(true)
    .barBackgroundColor(AhuColors.card)
    .barBackgroundBlurStyle(this.useLiquidGlass ? BlurStyle.COMPONENT_ULTRA_THICK : BlurStyle.NONE)
    .animationDuration(220)
    .onChange((index: number) => {
      this.selectedIndex = index;
    })
    .backgroundColor(AhuColors.pageBackground);
  }

  @Builder
  private postLoginContent() {
    if (this.setupComplete) {
      if (this.activePage === 'term_setup') {
        ScheduleSetupPage({ onSetup: () => { this.setupComplete = true; this.activePage = ''; } });
      } else if (this.activePage === 'grade') {
        GradePage({ onBack: () => { this.activePage = ''; } });
      } else if (this.activePage === 'exam') {
        ExamPage({ onBack: () => { this.activePage = ''; } });
      } else if (this.activePage === 'school_calendar') {
        SchoolCalendarPage({ onBack: () => { this.activePage = ''; } });
      } else if (this.activePage === 'free_classroom') {
        FreeClassroomPage({ onBack: () => { this.activePage = ''; } });
      } else if (this.activePage === 'card_recharge') {
        CardRechargePage({ onBack: () => { this.activePage = ''; } });
      } else if (this.activePage === 'bathroom') {
        BathroomRechargePage({ onBack: () => { this.activePage = ''; } });
      } else if (this.activePage === 'electricity') {
        ElectricityRechargePage({ onBack: () => { this.activePage = ''; } });
      } else if (this.activePage === 'lost_found') {
        LostFoundPage({ onBack: () => { this.activePage = ''; } });
      } else if (this.activePage === 'phone_book') {
        PhoneBookPage({ onBack: () => { this.activePage = ''; } });
      } else if (this.activePage === 'weather') {
        WeatherPage({ onBack: () => { this.activePage = ''; } });
      } else if (this.activePage === 'repository') {
        RepositoryPage({ onBack: () => { this.activePage = ''; } });
      } else if (this.activePage === 'debug' && BuildProfile.DEBUG) {
        DebugPage({
          onBack: () => { this.activePage = ''; },
          onDataChanged: () => {
            this.setupComplete = this.scheduleSetupRepository.hasCompletedSetup();
            const revision = AppStorage.get<number>('ahu_mock_revision') ?? 0;
            AppStorage.setOrCreate('ahu_mock_revision', revision + 1);
          },
          onClearData: () => this.logout(true),
          onTestReminder: (seconds: number) => {
            const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
            return CourseReminderManager.scheduleDebug(context, seconds);
          }
        });
      } else {
        this.mainContent();
      }
    } else {
      ScheduleSetupPage({
        onSetup: () => {
          this.setupComplete = true;
        }
      });
    }
  }

  build() {
    Stack() {
      AppLaunchGate({
        rejectAction: () => this.terminateApplication(),
        content: this.postLoginContent
      });
      if (this.updateInfo) {
        AppUpdateDialog({
          info: this.updateInfo,
          message: this.updateMessage,
          onAppGallery: () => this.openAppGallery(),
          onReleasePage: () => this.openReleasePage(),
          onDismiss: () => { this.updateInfo = undefined; this.updateMessage = ''; }
        });
      }
    }
    .width('100%')
    .height('100%');
  }
}
