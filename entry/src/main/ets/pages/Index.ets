import {
  AhuColors,
  AhuInsetCard,
  AhuPageHeader,
  AhuScreen,
  AhuTypography
} from 'core_designsystem';
import { SymbolGlyphModifier } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { LaunchConsentGate } from 'feature_login';

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
        MigrationPage({
          title: $r('app.string.nav_home'),
          description: $r('app.string.home_migration_description')
        });
      }
      .tabBar(new BottomTabBarStyle({
        normal: new SymbolGlyphModifier($r('sys.symbol.house')),
        selected: new SymbolGlyphModifier($r('sys.symbol.house_fill'))
      }, $r('app.string.nav_home')));

      TabContent() {
        MigrationPage({
          title: $r('app.string.nav_schedule'),
          description: $r('app.string.schedule_migration_description')
        });
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

  build() {
    Stack() {
      LaunchConsentGate({
        rejectAction: () => this.terminateApplication(),
        content: this.mainContent
      });
    }
    .width('100%')
    .height('100%');
  }
}
