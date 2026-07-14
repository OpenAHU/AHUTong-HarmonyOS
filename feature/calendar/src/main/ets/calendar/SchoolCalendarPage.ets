import { AhuColors, AhuLoading, AhuTypography } from 'core_designsystem';

@Component
export struct SchoolCalendarPage {
  @State revision: number = 0;
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  onBack: () => void = () => {};

  private url(): string {
    return this.revision === 0
      ? 'https://openahu.org/download/xiaoli.jpg'
      : `https://openahu.org/download/xiaoli.jpg?refresh=${this.revision}`;
  }

  private refresh(): void {
    this.isLoading = true;
    this.hasError = false;
    this.revision = Date.now();
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Button('‹', { type: ButtonType.Circle })
          .width(40).height(40).fontSize(28).backgroundColor(AhuColors.card).onClick(() => this.onBack());
        Text('校历').fontSize(28).fontWeight(FontWeight.Bold).fontColor(AhuColors.onSurface).layoutWeight(1);
        Button('↻', { type: ButtonType.Circle })
          .width(40).height(40).fontSize(22).backgroundColor(AhuColors.card).onClick(() => this.refresh());
      }
      .width('100%').padding({ left: 16, right: 16, top: 24 });

      Stack({ alignContent: Alignment.Center }) {
        Image(this.url())
          .width('100%').height('100%')
          .objectFit(ImageFit.Contain)
          .interpolation(ImageInterpolation.High)
          .alt($r('sys.media.ohos_app_icon'))
          .onComplete(() => { this.isLoading = false; this.hasError = false; })
          .onError(() => { this.isLoading = false; this.hasError = true; });
        if (this.isLoading) {
          AhuLoading({ message: '正在获取校历' });
        } else if (this.hasError) {
          Column({ space: 14 }) {
            Text('校历加载失败').fontSize(AhuTypography.body).fontColor(AhuColors.error);
            Button('重试', { type: ButtonType.Capsule }).onClick(() => this.refresh());
          }.alignItems(HorizontalAlign.Center);
        }
      }
      .width('100%').layoutWeight(1).padding(12);
    }
    .width('100%').height('100%').backgroundColor(AhuColors.pageBackground);
  }
}
