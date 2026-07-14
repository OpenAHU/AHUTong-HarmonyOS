import {
  AhuColors,
  AhuInsetCard,
  AhuPageHeader,
  AhuScreen,
  AhuTypography
} from 'core_designsystem';
import { SymbolGlyphModifier } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { AppLaunchGate } from 'feature_login';
import { ScheduleSetupPage, WeeklySchedulePage } from 'feature_schedule';
import { HomePage } from 'feature_home';
import { GradePage } from 'feature_grade';
import { ExamPage } from 'feature_exam';
import { ScheduleSetupRepository } from 'data_schedule';

@Component
struct MigrationPage {
  @Prop title: ResourceStr = '';
  @Prop description: ResourceStr = '';

  build() {
    AhuScreen({ scrollable: true }) {
      AhuPageHeader({ title: this.title });
      AhuInsetCard() {
        Column({ space: 12 }) {
          Text($r('app.string.migration_in_progress'))
            .fontSize(AhuTypography.sectionTitle)
            .fontWeight(FontWeight.Bold)
            .fontColor(AhuColors.onSurface);
          Text(this.description)
            .fontSize(AhuTypography.body)
            .fontColor(AhuColors.onSurfaceSecondary)
            .lineHeight(24);
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start);
      }
    }
  }
}

@Entry
@Component
struct Index {
  @State selectedIndex: number = 0;
  @State setupComplete: boolean = false;
  @State activePage: string = '';
  private readonly scheduleSetupRepository: ScheduleSetupRepository = new ScheduleSetupRepository();

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
            if (route === 'grade' || route === 'exam') {
              this.activePage = route;
            }
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
        MigrationPage({
          title: $r('app.string.nav_tools'),
          description: $r('app.string.tools_migration_description')
        });
      }
      .tabBar(new BottomTabBarStyle({
        normal: new SymbolGlyphModifier($r('sys.symbol.wrench_and_screwdriver')),
        selected: new SymbolGlyphModifier($r('sys.symbol.wrench_and_screwdriver_fill'))
      }, $r('app.string.nav_tools')));

      TabContent() {
        MigrationPage({
          title: $r('app.string.nav_settings'),
          description: $r('app.string.settings_migration_description')
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
    .barBackgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THICK)
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
