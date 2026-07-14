import { AhuColors, AhuLoading, AhuTypography } from 'core_designsystem';
import { common } from '@kit.AbilityKit';
import { CalendarImageSaver } from './CalendarImageSaver';
import { SchoolCalendarRepository } from 'data_calendar';

@Component
export struct SchoolCalendarPage {
  @State imageSource: string = '';
  @State localPath: string = '';
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State scaleValue: number = 1;
  @State pinchStartScale: number = 1;
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State panStartX: number = 0;
  @State panStartY: number = 0;
  @State isSaving: boolean = false;
  @State message: string = '';
  onBack: () => void = () => {};

  aboutToAppear(): void { this.load(false); }

  private async load(forceRefresh: boolean): Promise<void> {
    this.isLoading = true;
    this.hasError = false;
    this.message = '';
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const image = await SchoolCalendarRepository.getCalendarImage(context, forceRefresh);
      this.localPath = image.path; this.imageSource = image.uri;
    } catch (error) { this.hasError = true; this.message = (error as Error).message ?? '校历加载失败'; }
    finally { this.isLoading = false; }
  }

  private refresh(): void { this.load(true); }

  private resetTransform(): void {
    this.scaleValue = 1; this.offsetX = 0; this.offsetY = 0;
  }

  private async save(): Promise<void> {
    if (this.isSaving || this.hasError || this.isLoading) return;
    this.isSaving = true; this.message = '';
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await CalendarImageSaver.saveLocal(context, this.localPath);
      this.message = '已保存到图库';
    } catch (error) {
      this.message = (error as Error).message ?? '保存失败';
    } finally { this.isSaving = false; }
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Button('‹', { type: ButtonType.Circle })
          .width(40).height(40).fontSize(28).backgroundColor(AhuColors.card).onClick(() => this.onBack());
        Text('校历').fontSize(28).fontWeight(FontWeight.Bold).fontColor(AhuColors.onSurface).layoutWeight(1);
        Button('↻', { type: ButtonType.Circle })
          .width(40).height(40).fontSize(22).backgroundColor(AhuColors.card).onClick(() => this.refresh());
        Button(this.isSaving ? '…' : '存', { type: ButtonType.Circle })
          .width(40).height(40).fontSize(15).enabled(!this.isSaving && !this.isLoading && !this.hasError)
          .backgroundColor(AhuColors.card).fontColor(AhuColors.onSurface).onClick(() => this.save());
      }
      .width('100%').padding({ left: 16, right: 16, top: 24 });

      Stack({ alignContent: Alignment.Center }) {
        Image(this.imageSource)
          .width('100%').height('100%')
          .objectFit(ImageFit.Contain)
          .interpolation(ImageInterpolation.High)
          .scale({ x: this.scaleValue, y: this.scaleValue })
          .translate({ x: this.offsetX, y: this.offsetY })
          .gesture(GestureGroup(GestureMode.Parallel,
            PinchGesture({ fingers: 2 })
              .onActionStart(() => { this.pinchStartScale = this.scaleValue; })
              .onActionUpdate((event: GestureEvent) => {
                this.scaleValue = Math.max(0.5, Math.min(5, this.pinchStartScale * event.scale));
              }),
            PanGesture({ fingers: 1 })
              .onActionStart(() => { this.panStartX = this.offsetX; this.panStartY = this.offsetY; })
              .onActionUpdate((event: GestureEvent) => {
                this.offsetX = this.panStartX + event.offsetX; this.offsetY = this.panStartY + event.offsetY;
              }),
            TapGesture({ count: 2 }).onAction(() => this.resetTransform())
          ))
          .alt($r('sys.media.ohos_app_icon'))
          .onComplete(() => { this.isLoading = false; this.hasError = false; })
          .onError(() => { this.isLoading = false; this.hasError = true; });
        if (this.isLoading) {
          AhuLoading({ message: '正在获取校历' });
        } else if (this.hasError) {
          Column({ space: 14 }) {
            Text('校历加载失败').fontSize(AhuTypography.body).fontColor(AhuColors.error);
            Button('重试', { type: ButtonType.Capsule }).onClick(() => this.load(false));
          }.alignItems(HorizontalAlign.Center);
        }
      }
      .width('100%').layoutWeight(1).padding(12);
      if (this.message.length > 0) {
        Text(this.message).fontSize(AhuTypography.label)
          .fontColor(this.message === '已保存到图库' ? AhuColors.primaryAction : AhuColors.error)
          .padding({ bottom: 10 });
      }
    }
    .width('100%').height('100%').backgroundColor(AhuColors.pageBackground);
  }
}
