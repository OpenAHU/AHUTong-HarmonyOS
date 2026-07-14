import { AhuColors, AhuInsetCard, AhuScreen, AhuTypography } from 'core_designsystem';
import { common } from '@kit.AbilityKit';

interface LicenseItem { name: string; author: string; url: string; license: string; }
const LICENSES: Array<LicenseItem> = [
  { name: 'ArkUI / HarmonyOS SDK', author: 'Huawei', url: 'https://developer.huawei.com/consumer/cn/', license: 'HarmonyOS SDK License' },
  { name: 'AndroidX', author: 'Google', url: 'https://source.android.com', license: 'Apache License 2.0' },
  { name: 'Material', author: 'Google', url: 'https://source.android.com', license: 'Apache License 2.0' },
  { name: 'Gson', author: 'Google', url: 'https://github.com/google/gson', license: 'Apache License 2.0' },
  { name: 'OkHttp', author: 'Square', url: 'https://github.com/square/okhttp', license: 'Apache License 2.0' },
  { name: 'Retrofit', author: 'Square', url: 'https://github.com/square/retrofit', license: 'Apache License 2.0' },
  { name: 'Jsoup', author: 'jsoup.org', url: 'https://jsoup.org/', license: 'MIT License' },
  { name: 'MMKV', author: 'Tencent', url: 'https://github.com/Tencent/MMKV', license: 'BSD 3-Clause License' },
  { name: 'Coil', author: 'Coil Contributors', url: 'https://github.com/coil-kt/coil', license: 'Apache License 2.0' },
  { name: 'PersistentCookieJar', author: 'Fran Montiel', url: 'https://github.com/franmontiel/PersistentCookieJar', license: 'Apache License 2.0' },
  { name: 'ZXing Android Embedded', author: 'JourneyApps', url: 'https://github.com/journeyapps/zxing-android-embedded', license: 'Apache License 2.0' },
  { name: 'Monet', author: 'Kyant0', url: 'https://github.com/Kyant0/Monet', license: 'Apache License 2.0' },
  { name: 'Backdrop', author: 'Kyant0', url: 'https://github.com/Kyant0/AndroidLiquidGlass', license: 'Apache License 2.0' },
  { name: 'Capsule', author: 'Kyant0', url: 'https://github.com/Kyant0/Capsule', license: 'Apache License 2.0' },
  { name: 'More...', author: 'Various Developers', url: 'https://github.com/', license: '...' }
];

@Component
export struct LicensePage {
  @State error: string = '';
  onBack: () => void = () => {};

  private async open(url: string): Promise<void> {
    try { const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({ action: 'ohos.want.action.viewData', uri: url });
    } catch (_) { this.error = '无法打开链接'; }
  }

  build() {
    AhuScreen({ scrollable: true }) {
      Row({ space: 12 }) {
        Button('‹', { type: ButtonType.Circle }).width(40).height(40).fontSize(28)
          .backgroundColor(AhuColors.card).fontColor(AhuColors.onSurface).onClick(() => this.onBack());
        Text('开源协议').fontSize(AhuTypography.pageTitle).fontWeight(FontWeight.Bold).layoutWeight(1);
      }.width('100%').padding({ left: 16, right: 16, top: 24 });
      if (this.error.length > 0) Text(this.error).fontColor(AhuColors.error).padding({ left: 20 });
      ForEach(LICENSES, (item: LicenseItem) => {
        AhuInsetCard() {
          Column({ space: 4 }) {
            Text(item.name).fontSize(AhuTypography.body).fontWeight(FontWeight.Bold);
            Text(item.author).fontColor(AhuColors.onSurfaceSecondary);
            Text(item.license).fontSize(AhuTypography.label).fontColor(AhuColors.primaryAction);
            Text(item.url).fontSize(12).fontColor(AhuColors.onSurfaceSecondary).maxLines(1);
          }.width('100%').alignItems(HorizontalAlign.Start).onClick(() => this.open(item.url));
        }
      }, (item: LicenseItem) => item.name);
    }
  }
}
