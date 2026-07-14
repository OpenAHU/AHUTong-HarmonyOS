import { AhuColors, AhuDimens, AhuTypography } from '../theme/AhuTokens';

@Component
export struct AhuPageHeader {
  @Prop title: ResourceStr = '';

  @Builder
  private emptyContent() {}

  @BuilderParam actions: () => void = this.emptyContent;
  @BuilderParam below: () => void = this.emptyContent;

  build() {
    Column({ space: AhuDimens.contentHorizontal }) {
      Row() {
        Text(this.title)
          .fontSize(AhuTypography.pageTitle)
          .fontWeight(FontWeight.Bold)
          .fontColor(AhuColors.onSurface)
          .layoutWeight(1);
        Row() {
          this.actions();
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);

      this.below();
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({
      left: AhuDimens.titleHorizontal,
      right: AhuDimens.titleHorizontal,
      top: AhuDimens.titleTop
    });
  }
}
