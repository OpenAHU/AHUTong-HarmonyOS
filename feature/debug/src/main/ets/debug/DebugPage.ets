import { AhuCache } from 'core_datastore';
import { AhuColors, AhuInsetCard, AhuPageHeader, AhuScreen, AhuTypography } from 'core_designsystem';
import { MockScenarioController, MockScenarioOption } from './MockScenarioController';

@Component
export struct DebugPage {
  @State mockEnabled: boolean = AhuCache.getMockData();
  @State activeScenario: string = AhuCache.getMockScenario();
  @State effectiveTime: string = '';
  @State message: string = '';
  onBack: () => void = () => {};
  onDataChanged: () => void = () => {};
  onClearData: () => Promise<void> = async () => {};
  onTestReminder: (seconds: number) => Promise<boolean> = async (_seconds: number) => false;

  aboutToAppear(): void { this.refreshTime(); }

  private refreshTime(): void {
    const now = AhuCache.now();
    this.effectiveTime = `${now.getFullYear()}-${`${now.getMonth() + 1}`.padStart(2, '0')}-${`${now.getDate()}`.padStart(2, '0')} ` +
      `${`${now.getHours()}`.padStart(2, '0')}:${`${now.getMinutes()}`.padStart(2, '0')}`;
  }

  private applyScenario(id: string): void {
    const selected = MockScenarioController.apply(id);
    this.mockEnabled = true; this.activeScenario = selected.id;
    this.message = `已应用：${selected.title}`;
    this.onDataChanged(); this.refreshTime();
  }

  private setEnabled(value: boolean): void {
    if (value) this.applyScenario(this.activeScenario);
    else { MockScenarioController.disable(); this.mockEnabled = false; this.message = '已恢复真实数据源'; this.onDataChanged(); this.refreshTime(); }
  }

  private shiftTime(days: number): void {
    AhuCache.saveMockCurrentTimeMillis(AhuCache.now().getTime() + days * 86_400_000);
    this.message = `Mock 时间已调整 ${days > 0 ? '+' : ''}${days} 天`;
    this.onDataChanged(); this.refreshTime();
  }

  private async clearData(): Promise<void> {
    await this.onClearData(); this.mockEnabled = false; this.activeScenario = 'standard_student'; this.message = '缓存已清除'; this.refreshTime();
  }

  private async testReminder(seconds: number): Promise<void> {
    this.message = await this.onTestReminder(seconds) ? `已预约 ${seconds} 秒后测试提醒` : '测试提醒预约失败，请检查通知权限';
  }

  @Builder private section(title: string, subtitle: string) {
    Column({ space: 4 }) { Text(title).fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold);
      Text(subtitle).fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary); }
    .width('100%').alignItems(HorizontalAlign.Start).padding({ left: 20, top: 8 });
  }

  build() {
    AhuScreen({ scrollable: true }) {
      Row({ space: 8 }) { Text('‹').fontSize(34); Text('返回').fontSize(AhuTypography.body); }
        .padding({ left: 12, top: 8, bottom: 2 }).onClick(() => this.onBack());
      AhuPageHeader({ title: 'Debug' });
      Text('调试数据、时间、缓存和系统提醒').fontSize(AhuTypography.body)
        .fontColor(AhuColors.onSurfaceSecondary).padding({ left: 20 });
      this.section('数据源', '切换本地 Mock 数据；关闭后恢复真实网络数据源');
      AhuInsetCard() {
        Row() { Column({ space: 3 }) { Text('使用 Mock 数据').fontSize(AhuTypography.body).fontWeight(FontWeight.Medium);
          Text(this.mockEnabled ? '当前为模拟数据源' : '当前为真实数据源').fontSize(AhuTypography.label)
            .fontColor(AhuColors.onSurfaceSecondary); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          Toggle({ type: ToggleType.Switch, isOn: this.mockEnabled }).onChange((value: boolean) => this.setEnabled(value)); }
        .width('100%');
      }
      if (this.mockEnabled) {
        ForEach(MockScenarioController.scenarios, (scenario: MockScenarioOption) => {
          AhuInsetCard({ containerColor: this.activeScenario === scenario.id ? AhuColors.accentSurface : AhuColors.card }) {
            Row({ space: 12 }) { Column({ space: 3 }) { Text(`${scenario.title} · ${scenario.badge}`).fontSize(AhuTypography.body)
              .fontWeight(FontWeight.Medium); Text(scenario.subtitle).fontSize(AhuTypography.label)
              .fontColor(AhuColors.onSurfaceSecondary); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
              Text(this.activeScenario === scenario.id ? '✓' : '›').fontSize(22).fontColor(AhuColors.primaryAction); }
            .width('100%').onClick(() => this.applyScenario(scenario.id));
          }
        }, (scenario: MockScenarioOption) => scenario.id);
      }
      this.section('时间模拟', '影响首页、课表当前周、今日高亮和课表服务卡片');
      AhuInsetCard() { Column({ space: 10 }) { Text(this.effectiveTime).fontSize(22).fontWeight(FontWeight.Bold);
        Text(AhuCache.getMockCurrentTimeMillis() === undefined ? '当前使用系统时间' : '当前使用 Mock 时间')
          .fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary);
        Row({ space: 8 }) { Button('-5 天').onClick(() => this.shiftTime(-5)); Button('+3 天').onClick(() => this.shiftTime(3));
          Button('+7 天').onClick(() => this.shiftTime(7)); }.width('100%');
        Button('恢复系统时间').onClick(() => { AhuCache.clearMockCurrentTimeMillis(); this.onDataChanged(); this.refreshTime(); this.message = '已恢复系统时间'; });
      }.width('100%').alignItems(HorizontalAlign.Start); }
      this.section('通知测试', '独立预约测试提醒，不修改正式课前提醒计划');
      AhuInsetCard() { Row({ space: 10 }) { Button('10 秒后').onClick(() => this.testReminder(10));
        Button('50 秒后').onClick(() => this.testReminder(50)); }.width('100%'); }
      this.section('维护', '清理本地测试状态');
      AhuInsetCard() { Row() { Column({ space: 3 }) { Text('清除所有缓存').fontSize(AhuTypography.body).fontWeight(FontWeight.Medium);
        Text('包含登录、课表、Mock 时间及本地持久化数据').fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary); }
        .layoutWeight(1).alignItems(HorizontalAlign.Start); Text('›').fontSize(24); }.width('100%').onClick(() => this.clearData()); }
      if (this.message.length > 0) Text(this.message).fontSize(AhuTypography.label).fontColor(AhuColors.primaryAction).padding({ left: 20 });
    }
  }
}
