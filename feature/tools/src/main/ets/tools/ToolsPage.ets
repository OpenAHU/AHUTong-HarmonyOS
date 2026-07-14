import { AhuColors, AhuInsetCard, AhuPageHeader, AhuScreen, AhuTypography } from 'core_designsystem';
import { AhuCache } from 'core_datastore';

interface ToolEntry { id: string; title: string; symbol: Resource; tint: string; }

const TOOL_ENTRIES: Array<ToolEntry> = [
  { id: 'bathroom', title: '浴室缴费', symbol: $r('sys.symbol.drop'), tint: '#26A69A' },
  { id: 'electricity', title: '电控缴费', symbol: $r('sys.symbol.bolt'), tint: '#FFB300' },
  { id: 'grade', title: '成绩单', symbol: $r('sys.symbol.doc_text'), tint: '#FFC107' },
  { id: 'phone_book', title: '校园电话本', symbol: $r('sys.symbol.phone'), tint: '#009688' },
  { id: 'exam', title: '考场查询', symbol: $r('sys.symbol.doc_text'), tint: '#4CAF50' },
  { id: 'school_calendar', title: '校历', symbol: $r('sys.symbol.calendar'), tint: '#9C27B0' },
  { id: 'free_classroom', title: '空闲教室', symbol: $r('sys.symbol.house'), tint: '#03A9F4' },
  { id: 'lost_found', title: '失物招领', symbol: $r('sys.symbol.archivebox'), tint: '#1976D2' },
  { id: 'weather', title: '天气', symbol: $r('sys.symbol.drop'), tint: '#FFB300' },
  { id: 'repository', title: '学习资料', symbol: $r('sys.symbol.folder'), tint: '#8D6E63' }
];

@Component
export struct ToolsPage {
  @State entries: Array<ToolEntry> = [];
  @State cardTip: string = '';
  homeEditEnabled: boolean = false;
  onEditHome: () => void = () => {};
  onOpenWidget: (route: string) => void = (_: string) => {};

  aboutToAppear(): void { this.refresh(); }

  private refresh(): void {
    const placed = AhuCache.getHomeWidgetSlots();
    this.entries = TOOL_ENTRIES.filter((item: ToolEntry) => !placed.includes(item.id));
  }

  @Builder private headerActions() {
    if (this.homeEditEnabled) {
      Button('编辑首页', { type: ButtonType.Capsule }).fontSize(AhuTypography.label)
        .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.card).onClick(() => this.onEditHome());
    }
  }

  build() {
    AhuScreen({ scrollable: true }) {
      AhuPageHeader({ title: '工具', actions: this.headerActions });
      AhuInsetCard({ containerColor: AhuColors.accentSurface }) {
        Row({ space: 14 }) {
          SymbolGlyph($r('sys.symbol.calendar')).fontSize(34).fontColor([AhuColors.primaryAction]);
          Column({ space: 3 }) {
            Text('桌面课表卡片').fontSize(AhuTypography.body).fontWeight(FontWeight.Bold);
            Text('长按桌面，在服务卡片中选择“安大通 · 今日课表”')
              .fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary);
          }.alignItems(HorizontalAlign.Start).layoutWeight(1);
          Text('›').fontSize(26).fontColor(AhuColors.onSurfaceSecondary);
        }.width('100%').onClick(() => { this.cardTip = 'HarmonyOS 由桌面统一管理服务卡片，请长按桌面添加'; });
      }
      if (this.cardTip.length > 0) {
        Text(this.cardTip).fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary)
          .padding({ left: 18, right: 18 });
      }
      Text('未固定到首页的工具').fontSize(AhuTypography.body).fontColor(AhuColors.onSurfaceSecondary)
        .padding({ left: 18, right: 18 });
      if (this.entries.length === 0) {
        Text('所有工具都已固定到首页').width('100%').textAlign(TextAlign.Center)
          .fontColor(AhuColors.onSurfaceSecondary).padding(48);
      } else {
        Grid() {
          ForEach(this.entries, (item: ToolEntry) => {
            GridItem() {
              Column({ space: 12 }) {
                SymbolGlyph(item.symbol).fontSize(34).fontColor([item.tint]);
                Text(item.title).fontSize(AhuTypography.body).fontWeight(FontWeight.Medium).maxLines(1);
              }.width('100%').height(112).justifyContent(FlexAlign.Center).backgroundColor(AhuColors.card)
                .borderRadius(24).onClick(() => this.onOpenWidget(item.id));
            }
          }, (item: ToolEntry) => item.id);
        }.columnsTemplate('1fr 1fr').columnsGap(12).rowsGap(12).padding({ left: 16, right: 16 });
      }
    }
  }
}
