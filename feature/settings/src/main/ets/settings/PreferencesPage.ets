import { AhuColors, AhuInsetCard, AhuTypography } from 'core_designsystem';
import { AhuCache } from 'core_datastore';
import { common } from '@kit.AbilityKit';
import { notificationManager } from '@kit.NotificationKit';

interface ThemeOption { name: string; color: string; }
const THEME_OPTIONS: Array<ThemeOption> = [
  { name: '默认', color: '' }, { name: '极光蓝', color: '#FF4A90E2' }, { name: '樱花粉', color: '#FFE07A9F' },
  { name: '落日橙', color: '#FFF4A261' }, { name: '靛夜蓝', color: '#FF5C6BC0' }, { name: '苔藓绿', color: '#FF6A994E' },
  { name: '薰衣草紫', color: '#FF9B7EDE' }, { name: '绯红花', color: '#FFD64550' },
  { name: '天空青', color: '#FF4CC9F0' }, { name: '森林翡翠', color: '#FF2E8B57' },
  { name: '午夜紫', color: '#FF6A4C93' }, { name: '珊瑚粉', color: '#FFFF6F61' },
  { name: '北极薄荷', color: '#FF7ED9C3' }
];

@Component
export struct PreferencesPage {
  @State reminder: boolean = false;
  @State liveCountdown: boolean = false;
  @State liquidGlass: boolean = true;
  @State themeColor: string = '';
  @State showCustom: boolean = false;
  @State customColor: string = '';
  @State colorError: string = '';
  @State reminderMessage: string = '';
  onBack: () => void = () => {};
  onReminderChange: (enabled: boolean) => Promise<boolean> = async (_enabled: boolean) => true;

  aboutToAppear(): void {
    this.reminder = AhuCache.courseReminderEnabled(); this.liveCountdown = AhuCache.liveCountdownEnabled();
    this.liquidGlass = AhuCache.useLiquidGlass(); this.themeColor = AhuCache.themeColor();
  }

  private setTheme(color: string): void {
    this.themeColor = color; AhuCache.setThemeColor(color); AppStorage.setOrCreate('ahu_theme_color', color);
  }

  private saveCustom(): void {
    const value = this.customColor.trim().toUpperCase();
    if (!/^#[0-9A-F]{8}$/.test(value)) { this.colorError = '请输入 #AARRGGBB 格式，例如 #FF007FAC'; return; }
    this.setTheme(value); this.showCustom = false; this.colorError = '';
  }

  private async changeReminder(enabled: boolean): Promise<void> {
    this.reminderMessage = '';
    const applied = await this.onReminderChange(enabled);
    this.reminder = enabled && applied;
    if (!this.reminder) {
      this.liveCountdown = false;
      AhuCache.setLiveCountdownEnabled(false);
    }
    if (enabled && !applied) this.reminderMessage = '未获得通知权限，课前提醒未开启';
  }

  private async openReminderSettings(): Promise<void> {
    this.reminderMessage = '';
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await notificationManager.openNotificationSettings(context);
    } catch (_) {
      this.reminderMessage = '暂时无法打开系统通知设置，请前往系统设置中管理安大通通知';
    }
  }

  build() {
    Stack() {
      Scroll() {
        Column({ space: 14 }) {
          Row({ space: 12 }) {
            Button('‹', { type: ButtonType.Circle }).width(40).height(40).fontSize(28)
              .backgroundColor(AhuColors.card).fontColor(AhuColors.onSurface).onClick(() => this.onBack());
            Text('偏好设置').fontSize(AhuTypography.pageTitle).fontWeight(FontWeight.Bold).layoutWeight(1);
          }.width('100%').padding({ left: 16, right: 16, top: 24 });

          AhuInsetCard() {
            Column({ space: 16 }) {
              Text('通知').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold).width('100%');
              Row() {
                Column({ space: 4 }) { Text('课前提醒'); Text('上课前 10 分钟提醒下一节课')
                  .fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary); }
                .alignItems(HorizontalAlign.Start).layoutWeight(1);
                Toggle({ type: ToggleType.Switch, isOn: this.reminder }).onChange((enabled: boolean) => {
                  this.changeReminder(enabled);
                });
              }.width('100%');
              if (this.reminderMessage.length > 0) {
                Text(this.reminderMessage).fontSize(AhuTypography.label).fontColor(AhuColors.error).width('100%');
              }
              Divider().color(AhuColors.divider);
              Row() {
                Column({ space: 4 }) { Text('课前倒计时岛卡提醒（实验性）');
                  Text('需同时开启课前提醒，展示样式由 HarmonyOS 系统决定').fontSize(AhuTypography.label)
                    .fontColor(AhuColors.onSurfaceSecondary); }.alignItems(HorizontalAlign.Start).layoutWeight(1);
                Toggle({ type: ToggleType.Switch, isOn: this.liveCountdown }).enabled(this.reminder)
                  .onChange((enabled: boolean) => { this.liveCountdown = enabled; AhuCache.setLiveCountdownEnabled(enabled); });
              }.width('100%');
              Button('管理提醒权限', { type: ButtonType.Normal })
                .backgroundColor(Color.Transparent).fontColor(AhuColors.primaryAction)
                .alignSelf(ItemAlign.End).onClick(() => this.openReminderSettings());
            }.width('100%').alignItems(HorizontalAlign.Start);
          }

          AhuInsetCard() {
            Row() {
              Column({ space: 4 }) { Text('液态玻璃').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold);
                Text('启用液态玻璃效果').fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary); }
              .alignItems(HorizontalAlign.Start).layoutWeight(1);
              Toggle({ type: ToggleType.Switch, isOn: this.liquidGlass }).onChange((enabled: boolean) => {
                this.liquidGlass = enabled; AhuCache.setUseLiquidGlass(enabled);
                AppStorage.setOrCreate('ahu_liquid_glass', enabled);
              });
            }.width('100%');
          }

          AhuInsetCard() {
            Column({ space: 14 }) {
              Text('主题颜色').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold).width('100%');
              Scroll() {
                Row({ space: 16 }) {
                  Column({ space: 6 }) {
                    Text('+').fontSize(28).width(48).height(48).textAlign(TextAlign.Center)
                      .backgroundColor(AhuColors.cardStrong).borderRadius(12);
                    Text('自定义').fontSize(12);
                  }.onClick(() => { this.customColor = this.themeColor; this.showCustom = true; });
                  ForEach(THEME_OPTIONS, (option: ThemeOption) => {
                    Column({ space: 6 }) {
                      Stack({ alignContent: Alignment.Center }) {
                        Text('').width(48).height(48).backgroundColor(option.color.length > 0 ? option.color : AhuColors.primaryAction)
                          .borderRadius(12);
                        if (this.themeColor === option.color) Text('✓').fontSize(24).fontColor(Color.White);
                      }
                      Text(option.name).fontSize(12).fontColor(this.themeColor === option.color ? AhuColors.primaryAction : AhuColors.onSurface);
                    }.onClick(() => this.setTheme(option.color));
                  }, (option: ThemeOption) => option.name);
                }
              }.scrollable(ScrollDirection.Horizontal).width('100%');
            }.width('100%').alignItems(HorizontalAlign.Start);
          }
        }.padding({ bottom: 40 });
      }.width('100%').height('100%');

      if (this.showCustom) {
        Column({ space: 14 }) {
          Text('自定义主题颜色').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold);
          TextInput({ text: this.customColor, placeholder: '#FF007FAC' }).onChange((value: string) => { this.customColor = value; });
          if (this.colorError.length > 0) Text(this.colorError).fontSize(AhuTypography.label).fontColor(AhuColors.error);
          Row({ space: 10 }) {
            Button('取消', { type: ButtonType.Capsule }).onClick(() => { this.showCustom = false; this.colorError = ''; });
            Button('确定', { type: ButtonType.Capsule }).onClick(() => this.saveCustom());
          }.justifyContent(FlexAlign.End).width('100%');
        }.width('88%').padding(24).backgroundColor(AhuColors.card).borderRadius(24).shadow({ radius: 24, color: '#44000000' });
      }
    }.width('100%').height('100%').backgroundColor(AhuColors.pageBackground);
  }
}
