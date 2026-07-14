import { AhuColors, AhuTypography } from 'core_designsystem';
import type { AppUpdateInfo } from './AppUpdateManager';

@Component
export struct AppUpdateDialog {
  @Prop info: AppUpdateInfo;
  @Prop message: string = '';
  onAppGallery: () => void = () => {};
  onReleasePage: () => void = () => {};
  onDismiss: () => void = () => {};

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column({ space: 16 }) {
        Text(this.info.force ? '需要更新' : '发现新版本')
          .fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold);
        Text(`${this.info.title} · ${this.info.versionName}`)
          .fontSize(AhuTypography.body).fontWeight(FontWeight.Medium);
        Text('更新内容').fontSize(AhuTypography.body).fontWeight(FontWeight.Bold)
          .width('100%').textAlign(TextAlign.Start);
        Scroll() {
          Text(this.info.changelog).fontSize(AhuTypography.body)
            .fontColor(AhuColors.onSurfaceSecondary).width('100%');
        }.constraintSize({ maxHeight: 260 }).width('100%');
        Text('HarmonyOS 版本由应用市场或项目发行页分发，不会下载或安装 Android APK。')
          .fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary);
        if (this.message.length > 0) {
          Text(this.message).fontSize(AhuTypography.label).fontColor(AhuColors.error).width('100%');
        }
        Row({ space: 8 }) {
          if (!this.info.force) {
            Button('稍后', { type: ButtonType.Capsule }).onClick(() => this.onDismiss());
          }
          Button('项目发行页', { type: ButtonType.Capsule }).onClick(() => this.onReleasePage());
          Button('应用市场', { type: ButtonType.Capsule }).backgroundColor(AhuColors.primaryAction)
            .onClick(() => this.onAppGallery());
        }.width('100%').justifyContent(FlexAlign.End);
      }
      .width('88%').padding(24).backgroundColor(AhuColors.card).borderRadius(24)
      .shadow({ radius: 28, color: '#55000000' });
    }
    .width('100%').height('100%').backgroundColor('#66000000');
  }
}
