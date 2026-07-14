import { AhuColors, AhuInsetCard, AhuScreen, AhuTypography } from 'core_designsystem';
import { common } from '@kit.AbilityKit';

interface Developer { name: string; description: string; qq: string; }
const DEVELOPERS: Array<Developer> = [
  { name: '高玉灿（20级）', description: '架构规划、页面设计、爬虫', qq: '468766131' },
  { name: '谭哲昊（21级）', description: '架构规划、小组件', qq: '330771794' },
  { name: '王学雷（22级）', description: '页面设计、交互设计、新技术探索', qq: '257314409' },
  { name: '徐健灿（22级）', description: '爬虫、交互设计', qq: '3148336396' },
  { name: '王    钰（22级）', description: '架构规划、爬虫', qq: '605606366' }
];

@Component
export struct ContributorsPage {
  @State message: string = '';
  onBack: () => void = () => {};

  private async contact(qq: string): Promise<void> {
    try { const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({ action: 'ohos.want.action.viewData', uri: `mqqapi://card/show_pslcard?uin=${qq}` });
    } catch (_) { this.message = '请安装 QQ 或 TIM'; }
  }

  build() {
    AhuScreen({ scrollable: true }) {
      Row({ space: 12 }) {
        Button('‹', { type: ButtonType.Circle }).width(40).height(40).fontSize(28)
          .backgroundColor(AhuColors.card).fontColor(AhuColors.onSurface).onClick(() => this.onBack());
        Text('贡献名单').fontSize(AhuTypography.pageTitle).fontWeight(FontWeight.Bold).layoutWeight(1);
      }.width('100%').padding({ left: 16, right: 16, top: 24 });
      Text('加入我们').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold).padding({ left: 20 });
      AhuInsetCard() {
        Column({ space: 4 }) { Text('Hello~').fontSize(AhuTypography.body).fontWeight(FontWeight.Bold);
          Text('We are waiting for you!\nGet connection with us now!\nClick me for more info!')
            .fontColor(AhuColors.onSurfaceSecondary); }
        .width('100%').alignItems(HorizontalAlign.Start).onClick(() => { this.message = '请联系任意一位小伙伴'; });
      }
      Text('开发者').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold).padding({ left: 20 });
      if (this.message.length > 0) Text(this.message).fontColor(AhuColors.primaryAction).padding({ left: 20 });
      ForEach(DEVELOPERS, (developer: Developer) => {
        AhuInsetCard() {
          Row({ space: 16 }) {
            Image(`https://q1.qlogo.cn/g?b=qq&nk=${developer.qq}&s=640`).width(58).height(58).borderRadius(29);
            Column({ space: 4 }) {
              Text(developer.name).fontSize(AhuTypography.body).fontWeight(FontWeight.Bold);
              Text(developer.description).fontColor(AhuColors.onSurfaceSecondary);
              Text(`QQ: ${developer.qq}`).fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary);
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
          }.width('100%').onClick(() => this.contact(developer.qq));
        }
      }, (developer: Developer) => developer.qq);
    }
  }
}
