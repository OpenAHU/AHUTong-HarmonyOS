import { AhuColors, AhuDimens } from '../theme/AhuTokens';

@Component
export struct AhuScreen {
  @Prop scrollable: boolean = true;
  @Prop clearBottomNav: boolean = false;
  @BuilderParam content: () => void = () => {};

  @Builder
  private pageContent() {
    Column({ space: AhuDimens.sectionSpacing }) {
      this.content();
    }
    .width('100%')
    .minHeight('100%')
    .padding({ bottom: this.clearBottomNav ? AhuDimens.bottomNavClearance : 0 });
  }

  build() {
    Stack() {
      if (this.scrollable) {
        Scroll() {
          this.pageContent();
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off);
      } else {
        this.pageContent();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AhuColors.pageBackground);
  }
}
