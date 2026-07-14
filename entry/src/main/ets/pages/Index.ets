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
import { AuthRepositoryProvider } from 'data_auth';
import { AhuCache } from 'core_datastore';
import { fileIo as fs } from '@kit.CoreFileKit';

@Entry
@Component
struct Index {
  @State selectedIndex: number = 0;
  @State setupComplete: boolean = false;
  @State activePage: string = '';
  @StorageLink('ahu_liquid_glass') useLiquidGlass: boolean = true;
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
        SettingsPage({ onLogout: () => this.logout(false), onClearAllData: () => this.logout(true) });
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
      if (this.activePage === 'grade') {
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
    }
    .width('100%')
    .height('100%');
  }
}
