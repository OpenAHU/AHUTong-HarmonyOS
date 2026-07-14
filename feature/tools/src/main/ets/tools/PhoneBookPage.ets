import { common } from '@kit.AbilityKit';
import { AhuColors, AhuInsetCard, AhuScreen, AhuTypography } from 'core_designsystem';
import { Tel } from 'core_model';

interface PhoneCategory { name: string; entries: Array<Tel>; }

const PHONE_BOOK: Array<PhoneCategory> = [
  { name: '师生综合服务大厅', entries: [
    { name: '咨询台', tel: '63861400' }, { name: '财务处', tel: '63861322', tel2: '65107303' },
    { name: '研究生院', tel: '63861455', tel2: '65107332' }, { name: '教务处', tel: '63861055', tel2: '65107135' },
    { name: '双创学院', tel: '65106065' }, { name: '学生处（学生发展中心）', tel: '63861686', tel2: '65107232' },
    { name: '国际合作与交流处', tel: '63861848' }, { name: '学校办公室', tel: '63861659', tel2: '65107020' },
    { name: '网络信息中心', tel: '63861855', tel2: '65107421' }, { name: '保卫处', tel: '63861918' },
    { name: '人事处', tel: '63861922' }, { name: '国有资产管理与实验室管理处', tel: '63861949', tel2: '65107310' },
    { name: '人文社会科学处', tel: '63861958' }, { name: '科学技术处', tel: '63861983' },
    { name: '校团委', tel2: '65107537' }
  ] },
  { name: '学生处（心理健康教育中心）', entries: [
    { name: '学生思想教育科', tel: '63861900' }, { name: '学生管理科', tel: '63861054' },
    { name: '学生资助管理中心', tel: '63861900' }, { name: '学生就业指导中心', tel: '63861355', tel2: '63861383' },
    { name: '心理健康教育中心', tel: '63861590' }
  ] },
  { name: '校团委', entries: [{ name: '团委办公室', tel: '63861121', tel2: '63861196' }] },
  { name: '图书馆', entries: [{ name: '图书馆', tel: '63861109' }] },
  { name: '校医院（医保办）', entries: [
    { name: '24 小时值班电话', tel: '63861120' }, { name: '校医疗保障委员会办公室', tel: '63861715' }
  ] },
  { name: '后勤服务', entries: [
    { name: '学校物业监管办公室', tel: '63861358' }, { name: '餐饮监管办公室', tel: '63861398' }
  ] },
  { name: '报警电话', entries: [
    { name: '保卫处（优先联系）', tel: '63861110', tel2: '65108229' }, { name: '三里庵派出所', tel2: '63636594' },
    { name: '芙蓉派出所', tel: '63822505' }
  ] },
  { name: '磬苑后勤', entries: [
    { name: '校园报修电话', tel: '63861118' }, { name: '服务监督电话', tel: '63861722' },
    { name: '北区 24 小时报修电话', tel: '62950090' }, { name: '南区 24 小时报修电话', tel: '63861333' },
    { name: '桃园', tel: '63861034' }, { name: '李园', tel: '63861037' }, { name: '桔园', tel: '63861036' },
    { name: '枣园', tel: '63861218' }, { name: '榴园', tel: '63861217' }, { name: '杏园', tel: '63861219' },
    { name: '蕙8', tel: '63861654' }, { name: '蕙9', tel: '63861617' }, { name: '蕙10', tel: '63861697' },
    { name: '松园', tel: '63861160' }, { name: '竹园', tel: '63861115' }, { name: '梅园', tel: '63861113' },
    { name: '桂园', tel: '63861097' }, { name: '枫园', tel: '63861096' }, { name: '槐园', tel: '63861081' },
    { name: '留学生公寓', tel: '63861096' }
  ] },
  { name: '龙河后勤', entries: [
    { name: '宿舍管理办公室', tel2: '65107014' }, { name: '校园报修电话', tel2: '63861118' },
    { name: '服务监督电话', tel2: '63861722' }, { name: '206楼', tel2: '65107064' },
    { name: '207-208楼', tel2: '65108150' }, { name: '209楼', tel2: '65107940' },
    { name: '301楼', tel2: '65108004' }, { name: '304-306楼', tel2: '65108004' }
  ] }
];

@Component
export struct PhoneBookPage {
  @State category: string = PHONE_BOOK[0].name;
  @State searching: boolean = false;
  @State query: string = '';
  @State dialChoice?: Tel = undefined;
  @State error: string = '';
  onBack: () => void = () => {};

  private allEntries(): Array<Tel> {
    return PHONE_BOOK.reduce((result: Array<Tel>, item: PhoneCategory) => result.concat(item.entries), []);
  }

  private visibleEntries(): Array<Tel> {
    if (this.searching) {
      const query = this.query.trim().toLowerCase();
      if (query.length === 0) return [];
      return this.allEntries().filter((item: Tel) => item.name.toLowerCase().includes(query) ||
        (item.tel ?? '').includes(query) || (item.tel2 ?? '').includes(query));
    }
    return PHONE_BOOK.find((item: PhoneCategory) => item.name === this.category)?.entries ?? [];
  }

  private async dial(number?: string): Promise<void> {
    if (!number) return;
    this.error = '';
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({ action: 'ohos.want.action.dial', uri: `tel:0551-${number}` });
      this.dialChoice = undefined;
    } catch (_) { this.error = '无法打开系统拨号器'; }
  }

  private onEntryClick(item: Tel): void {
    if (item.tel && item.tel2 && item.tel !== item.tel2) this.dialChoice = item;
    else this.dial(item.tel ?? item.tel2);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      AhuScreen({ scrollable: true }) {
        Row({ space: 10 }) {
          Button('‹', { type: ButtonType.Circle }).width(40).height(40).fontSize(28)
            .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.card).onClick(() => {
              if (this.searching) { this.searching = false; this.query = ''; } else this.onBack();
            });
          Text('校园电话本').fontSize(28).fontWeight(FontWeight.Bold).layoutWeight(1);
          Button(this.searching ? '关闭' : '搜索', { type: ButtonType.Capsule }).backgroundColor(AhuColors.card)
            .fontColor(AhuColors.onSurface).onClick(() => { this.searching = !this.searching; this.query = ''; });
        }.width('100%').padding({ left: 16, right: 16, top: 20 });
        if (this.searching) {
          TextInput({ text: this.query, placeholder: '搜索电话或部门' }).onChange((value: string) => this.query = value)
            .margin({ left: 16, right: 16 });
        } else {
          Scroll() { Row({ space: 8 }) { ForEach(PHONE_BOOK, (item: PhoneCategory) => {
            Button(item.name, { type: ButtonType.Capsule })
              .fontColor(this.category === item.name ? AhuColors.onPrimaryAction : AhuColors.onSurface)
              .backgroundColor(this.category === item.name ? AhuColors.primaryAction : AhuColors.chipUnselected)
              .onClick(() => this.category = item.name);
          }, (item: PhoneCategory) => item.name); } }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
            .padding({ left: 16, right: 16 });
        }
        if (this.error.length > 0) Text(this.error).fontColor(AhuColors.error).padding({ left: 18, right: 18 });
        if (this.visibleEntries().length === 0) {
          Text(this.searching && this.query.length === 0 ? '请输入关键词' : '没有搜索结果').width('100%')
            .textAlign(TextAlign.Center).fontColor(AhuColors.onSurfaceSecondary).padding(48);
        } else {
          ForEach(this.visibleEntries(), (item: Tel) => {
            AhuInsetCard() {
              Row({ space: 12 }) {
                Column({ space: 6 }) {
                  Text(item.name).fontSize(AhuTypography.body).fontWeight(FontWeight.Bold);
                  if (item.tel) Text(`磬苑  0551-${item.tel}`).fontSize(AhuTypography.label)
                    .fontColor(AhuColors.onSurfaceSecondary);
                  if (item.tel2 && item.tel2 !== item.tel) Text(`龙河  0551-${item.tel2}`).fontSize(AhuTypography.label)
                    .fontColor(AhuColors.onSurfaceSecondary);
                }.layoutWeight(1).alignItems(HorizontalAlign.Start);
                SymbolGlyph($r('sys.symbol.phone')).fontSize(24).fontColor([AhuColors.primaryAction]);
              }.width('100%').onClick(() => this.onEntryClick(item));
            }
          }, (item: Tel, index: number) => `${item.name}:${item.tel ?? ''}:${item.tel2 ?? ''}:${index}`);
        }
      }
      if (this.dialChoice) {
        Column({ space: 16 }) {
          Text(this.dialChoice.name).fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold);
          Button(`磬苑校区  0551-${this.dialChoice.tel}`, { type: ButtonType.Capsule }).width('100%')
            .onClick(() => this.dial(this.dialChoice?.tel));
          Button(`龙河校区  0551-${this.dialChoice.tel2}`, { type: ButtonType.Capsule }).width('100%')
            .onClick(() => this.dial(this.dialChoice?.tel2));
          Button('取消', { type: ButtonType.Capsule }).width('100%').backgroundColor(AhuColors.chipUnselected)
            .fontColor(AhuColors.onSurface).onClick(() => this.dialChoice = undefined);
        }.width('86%').padding(24).backgroundColor(AhuColors.card).borderRadius(28).alignItems(HorizontalAlign.Start);
      }
    }.width('100%').height('100%');
  }
}
