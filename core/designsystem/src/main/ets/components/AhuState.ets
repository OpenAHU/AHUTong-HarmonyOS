import { AhuColors, AhuTypography } from '../theme/AhuTokens';

@Component
export struct AhuLoading {
  @Prop message: ResourceStr = '';

  build() {
    Column({ space: 16 }) {
      LoadingProgress()
        .width(40)
        .height(40)
        .color(AhuColors.primaryAction);
      Text(this.message)
        .fontSize(AhuTypography.body)
        .fontColor(AhuColors.onSurfaceSecondary);
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }
}

@Component
export struct AhuEmptyState {
  @Prop text: string = '';

  build() {
    Column() {
      Text(this.text)
        .fontSize(AhuTypography.body)
        .fontColor(AhuColors.onSurfaceSecondary)
        .textAlign(TextAlign.Center);
    }
    .width('100%')
    .height('100%')
    .padding(32)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }
}
