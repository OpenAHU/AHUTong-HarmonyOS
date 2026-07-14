import { AhuColors, AhuInsetCard, AhuPageHeader, AhuScreen, AhuTypography } from 'core_designsystem';
import { AhuCache } from 'core_datastore';
import { PreferencesPage } from './PreferencesPage';
import { LicensePage } from './LicensePage';
import { ContributorsPage } from './ContributorsPage';
import { common } from '@kit.AbilityKit';
import { BackPressDispatcher } from 'core_common';

@Component
export struct SettingsPage {
  @State activePage: string = '';
  @State message: string = '';
  @State showClear: boolean = false;
  @State clearing: boolean = false;
  @State checkingUpdate: boolean = false;
  @State showUpdateIntro: boolean = false;
  @State updateIntro: string = '';
  @State debugTapCount: number = 0;
  private lastDebugTap: number = 0;
  active: boolean = false;
  appVersion: string = '';
  onLogout: () => Promise<void> = async () => {};
  onClearAllData: () => Promise<void> = async () => {};
  onReminderChange: (enabled: boolean) => Promise<boolean> = async (_enabled: boolean) => true;
  onReconfigureTerm: () => void = () => {};
  onCheckUpdate: () => Promise<string> = async () => '检查更新失败';
  onLoadUpdateIntro: () => Promise<string> = async () => '暂无更新介绍';
  debugEnabled: boolean = false;
  onOpenDebug: () => void = () => {};

  aboutToAppear(): void { BackPressDispatcher.register('settings_page', () => this.handleBackPress()); }
  aboutToDisappear(): void { BackPressDispatcher.unregister('settings_page'); }

  private handleBackPress(): boolean {
    if (!this.active) return false;
    if (this.showUpdateIntro) { this.showUpdateIntro = false; return true; }
    if (this.showClear) { this.showClear = false; return true; }
    if (this.activePage.length > 0) { this.activePage = ''; return true; }
    return false;
  }

  private debugTap(): void {
    if (!this.debugEnabled) return;
    const now = Date.now();
    this.debugTapCount = now - this.lastDebugTap <= 1_000 ? this.debugTapCount + 1 : 1;
    this.lastDebugTap = now;
    if (this.debugTapCount >= 8) { this.debugTapCount = 0; this.onOpenDebug(); }
  }

  private async checkUpdate(): Promise<void> {
    if (this.checkingUpdate) return;
    this.checkingUpdate = true;
    this.message = '';
    try { this.message = await this.onCheckUpdate(); }
    finally { this.checkingUpdate = false; }
  }

  private async loadUpdateIntro(): Promise<void> {
    this.showUpdateIntro = true; this.updateIntro = '正在加载…';
    try { this.updateIntro = await this.onLoadUpdateIntro(); }
    catch (_) { this.updateIntro = '更新介绍加载失败，请稍后重试。'; }
  }

  private async feedback(): Promise<void> {
    try { const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({ action: 'ohos.want.action.viewData',
        uri: 'mqqapi://card/show_pslcard?src_type=internal&version=1&uin=1006203134&card_type=group&source=qrcode' });
    } catch (_) { this.message = '请安装 QQ 或 TIM'; }
  }

  private async logout(): Promise<void> {
    if (this.clearing) return; this.clearing = true;
    try { await this.onLogout(); } finally { this.clearing = false; }
  }

  private async clearAll(): Promise<void> {
    if (this.clearing) return; this.clearing = true;
    try { await this.onClearAllData(); this.showClear = false; } finally { this.clearing = false; }
  }

  private termLabel(): string {
    const schoolYear = AhuCache.getSchoolYear() ?? '--';
    const storedTerm = AhuCache.getSchoolTerm() ?? '';
    const parts = storedTerm.split('-');
    const term = parts.length >= 3 ? parts[parts.length - 1] : storedTerm;
    return `${schoolYear} 学年 · 第 ${term.length > 0 ? term : '--'} 学期`;
  }

  @Builder private item(title: string, subtitle: string, route: string) {
    AhuInsetCard() {
      Row() {
        Column({ space: 3 }) { Text(title).fontSize(AhuTypography.body).fontWeight(FontWeight.Medium);
          Text(subtitle).fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary); }
        .alignItems(HorizontalAlign.Start).layoutWeight(1);
        Text('›').fontSize(26).fontColor(AhuColors.onSurfaceSecondary);
      }.width('100%').onClick(() => { this.activePage = route; });
    }
  }

  build() {
    if (this.activePage === 'preferences') {
      PreferencesPage({ onBack: () => { this.activePage = ''; }, onReminderChange: this.onReminderChange });
    } else if (this.activePage === 'license') {
      LicensePage({ onBack: () => { this.activePage = ''; } });
    } else if (this.activePage === 'contributors') {
      ContributorsPage({ onBack: () => { this.activePage = ''; } });
    } else {
      Stack() {
        AhuScreen({ scrollable: true }) {
          AhuPageHeader({ title: '设置' });
        AhuInsetCard({ containerColor: AhuColors.accentSurface }) {
          Row({ space: 16 }) {
            Image($r('app.media.startIcon')).width(64).height(64).borderRadius(18);
            Column({ space: 5 }) { Text('安大通').fontSize(24).fontWeight(FontWeight.Bold);
              Text(`${this.appVersion} · HarmonyOS`).fontSize(AhuTypography.body).fontColor(AhuColors.onSurfaceSecondary); }
            .alignItems(HorizontalAlign.Start);
          }.width('100%');
        }
        Text('账户信息').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold).padding({ left: 20 });
        AhuInsetCard() {
          Column({ space: 5 }) {
            Text(AhuCache.getCurrentUser()?.name ?? '未登录').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold);
            Text(this.termLabel())
              .fontColor(AhuColors.onSurfaceSecondary);
          }.width('100%').alignItems(HorizontalAlign.Start).onClick(() => this.debugTap());
        }
        AhuInsetCard() {
          Row() { Column({ space: 3 }) { Text('学期设置').fontSize(AhuTypography.body).fontWeight(FontWeight.Medium);
            Text('重新设置学年、学期和当前周').fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary); }
            .alignItems(HorizontalAlign.Start).layoutWeight(1); Text('›').fontSize(26); }
          .width('100%').onClick(() => this.onReconfigureTerm());
        }
        AhuInsetCard() {
          Row() { Text('退出登录').fontSize(AhuTypography.body).fontWeight(FontWeight.Medium).layoutWeight(1);
            Text('›').fontSize(26); }.width('100%').onClick(() => this.logout());
        }
        this.item('偏好设置', '提醒、液态玻璃与主题颜色', 'preferences');
        Text('关于').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold).padding({ left: 20 });
        this.item('开源协议', '查看第三方软件许可', 'license');
        this.item('贡献名单', '感谢每一位项目贡献者', 'contributors');
        AhuInsetCard() {
          Row() { Column({ space: 3 }) { Text('检查更新').fontSize(AhuTypography.body).fontWeight(FontWeight.Medium);
            Text(this.checkingUpdate ? '正在检查新版本' : '通过应用市场或项目发行页更新')
              .fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary); }
            .alignItems(HorizontalAlign.Start).layoutWeight(1); Text(this.checkingUpdate ? '…' : '›').fontSize(26); }
          .width('100%').enabled(!this.checkingUpdate).onClick(() => this.checkUpdate());
        }
        AhuInsetCard() {
          Row() { Column({ space: 3 }) { Text('更新介绍').fontSize(AhuTypography.body).fontWeight(FontWeight.Medium);
            Text('查看当前 HarmonyOS 发行说明').fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary); }
            .alignItems(HorizontalAlign.Start).layoutWeight(1); Text('›').fontSize(26); }
          .width('100%').onClick(() => this.loadUpdateIntro());
        }
        AhuInsetCard() {
          Row() { Column({ space: 3 }) { Text('意见反馈').fontSize(AhuTypography.body).fontWeight(FontWeight.Medium);
            Text('加入安大通反馈群').fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary); }
            .alignItems(HorizontalAlign.Start).layoutWeight(1); Text('›').fontSize(26); }
          .width('100%').onClick(() => this.feedback());
        }
        if (this.message.length > 0) Text(this.message).fontColor(AhuColors.error).padding({ left: 20 });
          AhuInsetCard() {
            Row() { Column({ space: 3 }) { Text('清除数据').fontSize(AhuTypography.body).fontWeight(FontWeight.Medium);
              Text('清除登录状态、课表和缓存').fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary); }
              .alignItems(HorizontalAlign.Start).layoutWeight(1); Text('›').fontSize(26); }
            .width('100%').onClick(() => { this.showClear = true; });
          }
        }
        if (this.showClear) {
          Column({ space: 16 }) {
            Text('清除所有数据？').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold);
            Text('您的登录状态、课表等信息将会被永久清除').fontColor(AhuColors.onSurfaceSecondary);
            Row({ space: 10 }) {
              Button('取消', { type: ButtonType.Capsule }).enabled(!this.clearing).onClick(() => { this.showClear = false; });
              Button(this.clearing ? '清除中' : '清除', { type: ButtonType.Capsule }).enabled(!this.clearing)
                .backgroundColor(AhuColors.error).onClick(() => this.clearAll());
            }.width('100%').justifyContent(FlexAlign.End);
          }.width('86%').padding(24).backgroundColor(AhuColors.card).borderRadius(24)
            .shadow({ radius: 24, color: '#44000000' });
        }
        if (this.showUpdateIntro) {
          Column({ space: 16 }) {
            Text('更新介绍').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold);
            Scroll() { Text(this.updateIntro).fontSize(AhuTypography.body).fontColor(AhuColors.onSurfaceSecondary).width('100%'); }
              .constraintSize({ maxHeight: 360 }).width('100%');
            Button('关闭', { type: ButtonType.Capsule }).onClick(() => { this.showUpdateIntro = false; });
          }.width('86%').padding(24).backgroundColor(AhuColors.card).borderRadius(24)
            .shadow({ radius: 24, color: '#44000000' });
        }
      }.width('100%').height('100%');
    }
  }
}
