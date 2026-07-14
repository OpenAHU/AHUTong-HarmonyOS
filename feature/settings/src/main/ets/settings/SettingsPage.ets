import { AhuColors, AhuInsetCard, AhuPageHeader, AhuScreen, AhuTypography } from 'core_designsystem';
import { AhuCache } from 'core_datastore';
import { PreferencesPage } from './PreferencesPage';

@Component
export struct SettingsPage {
  @State activePage: string = '';

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
      PreferencesPage({ onBack: () => { this.activePage = ''; } });
    } else {
      AhuScreen({ scrollable: true }) {
        AhuPageHeader({ title: '设置' });
        AhuInsetCard({ containerColor: AhuColors.accentSurface }) {
          Row({ space: 16 }) {
            Image($r('app.media.startIcon')).width(64).height(64).borderRadius(18);
            Column({ space: 5 }) { Text('安大通').fontSize(24).fontWeight(FontWeight.Bold);
              Text('HarmonyOS 迁移版').fontSize(AhuTypography.body).fontColor(AhuColors.onSurfaceSecondary); }
            .alignItems(HorizontalAlign.Start);
          }.width('100%');
        }
        Text('账户信息').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold).padding({ left: 20 });
        AhuInsetCard() {
          Column({ space: 5 }) {
            Text(AhuCache.getCurrentUser()?.name ?? '未登录').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold);
            Text(`${AhuCache.getSchoolYear() ?? '--'} 学年 · 第 ${AhuCache.getSchoolTerm() ?? '--'} 学期`)
              .fontColor(AhuColors.onSurfaceSecondary);
          }.width('100%').alignItems(HorizontalAlign.Start);
        }
        this.item('偏好设置', '提醒、液态玻璃与主题颜色', 'preferences');
        Text('关于').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold).padding({ left: 20 });
        this.item('开源协议', '查看第三方软件许可', 'license');
        this.item('贡献名单', '感谢每一位项目贡献者', 'contributors');
        this.item('清除数据', '清除登录状态、课表和缓存', 'clear');
      }
    }
  }
}
