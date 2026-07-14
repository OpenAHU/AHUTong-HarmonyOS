import { AhuColors, AhuInsetCard, AhuLoading, AhuScreen, AhuTypography } from 'core_designsystem';
import { AhuCache } from 'core_datastore';
import { Course, HourlyForecast, WeatherResponse, courseLength, courseStartTime, courseWeekday } from 'core_model';
import { ScheduleRepository, ScheduleRepositoryProvider, ScheduleSetupRepository } from 'data_schedule';
import { LengthMetrics } from '@kit.ArkUI';
import { CampusCardRepository, CampusCardRepositoryProvider } from 'data_campuscard';
import { common } from '@kit.AbilityKit';
import { WeatherRepository, WeatherRepositoryProvider } from 'data_weather';

const PERIOD_START: Array<number> = [480, 530, 590, 640, 690, 840, 890, 950, 1000, 1050, 1140, 1190, 1240];
const PERIOD_END: Array<number> = [525, 575, 635, 685, 735, 885, 935, 995, 1045, 1095, 1185, 1235, 1285];

interface HomeWidget {
  id: string;
  title: string;
  symbol: Resource;
  tint: string;
}

const HOME_WIDGETS: Array<HomeWidget> = [
  { id: 'bathroom', title: '浴室缴费', symbol: $r('sys.symbol.drop'), tint: '#26A69A' },
  { id: 'electricity', title: '电控缴费', symbol: $r('sys.symbol.bolt'), tint: '#FFB300' },
  { id: 'grade', title: '成绩单', symbol: $r('sys.symbol.doc_text'), tint: '#FFC107' },
  { id: 'phone_book', title: '电话本', symbol: $r('sys.symbol.phone'), tint: '#009688' },
  { id: 'exam', title: '考场查询', symbol: $r('sys.symbol.doc_text'), tint: '#4CAF50' },
  { id: 'school_calendar', title: '校历', symbol: $r('sys.symbol.calendar'), tint: '#9C27B0' },
  { id: 'free_classroom', title: '空闲教室', symbol: $r('sys.symbol.house'), tint: '#03A9F4' },
  { id: 'lost_found', title: '失物招领', symbol: $r('sys.symbol.archivebox'), tint: '#1976D2' },
  { id: 'weather', title: '天气', symbol: $r('sys.symbol.drop'), tint: '#FFB300' },
  { id: 'repository', title: '学习资料', symbol: $r('sys.symbol.folder'), tint: '#8D6E63' }
];

@Component
export struct HomePage {
  private readonly scheduleRepository: ScheduleRepository = ScheduleRepositoryProvider.get();
  private readonly setupRepository: ScheduleSetupRepository = new ScheduleSetupRepository();
  private readonly campusCardRepository: CampusCardRepository = CampusCardRepositoryProvider.get();
  private readonly weatherRepository: WeatherRepository = WeatherRepositoryProvider.get();
  @State courses: Array<Course> = [];
  @State isLoading: boolean = true;
  @State currentWeek: number = 1;
  @State slots: Array<string> = [];
  @State isEditing: boolean = false;
  @State cardBalance?: number = undefined;
  @State cardError: string = '';
  @State showCardQrcode: boolean = false;
  @State cardQrcode: string = '';
  @State qrcodeLoading: boolean = false;
  @State showFullscreenQrcode: boolean = false;
  @State weather?: WeatherResponse = undefined;
  @State dragIndex: number = -1;
  @State dragTarget: number = -1;
  @State dragOffsetX: number = 0;
  @State dragOffsetY: number = 0;
  @StorageLink('ahu_home_edit_request') @Watch('onEditRequestChanged') homeEditRequest: number = 0;
  private originalBrightness: number = -1;
  onOpenSchedule: () => void = () => {};
  onOpenWidget: (route: string) => void = (_: string) => {};
  onOpenRecharge: () => void = () => {};
  homeEditEnabled: boolean = false;

  private onEditRequestChanged(): void {
    if (this.homeEditEnabled) this.isEditing = true;
  }

  aboutToAppear(): void {
    const config = this.setupRepository.displayConfig();
    this.currentWeek = config?.currentWeek ?? 1;
    this.slots = AhuCache.getHomeWidgetSlots();
    this.load();
    this.loadBalance(false);
    this.loadWeather();
  }

  private async load(): Promise<void> {
    const result = await this.scheduleRepository.getSchedule(false);
    this.courses = result.data ?? [];
    this.isLoading = false;
  }

  private async loadBalance(refresh: boolean): Promise<void> {
    this.cardError = '';
    const result = await this.campusCardRepository.getBalance(refresh);
    if (result.isSuccess && result.data) this.cardBalance = result.data.balance;
    else this.cardError = result.error?.message ?? '余额加载失败';
  }

  private async loadWeather(): Promise<void> {
    if (!this.weatherRepository.showOnHome()) return;
    const result = await this.weatherRepository.getWeather();
    if (result.isSuccess && result.data) this.weather = result.data;
  }

  private rainSoon(weather: WeatherResponse): boolean {
    const rain = (value?: string): boolean => /雨|雪|雷|冰雹/.test(value ?? '');
    return rain(weather.weather) || (weather.hourly_forecast?.slice(0, 6)
      .some((item: HourlyForecast) => rain(item.weather)) ?? false);
  }

  private async loadQrcode(): Promise<void> {
    this.qrcodeLoading = true;
    this.cardError = '';
    const result = await this.campusCardRepository.getQrcode();
    if (result.isSuccess && result.data) this.cardQrcode = result.data;
    else {
      this.cardQrcode = '';
      this.cardError = result.error?.message ?? '校园码加载失败';
    }
    this.qrcodeLoading = false;
  }

  private openQrcode(): void {
    this.showCardQrcode = true;
    this.loadQrcode();
  }

  private async openFullscreenQrcode(): Promise<void> {
    if (this.cardQrcode.length === 0) return;
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const mainWindow = context.windowStage.getMainWindowSync();
      this.originalBrightness = mainWindow.getWindowProperties().brightness;
      await mainWindow.setWindowBrightness(1);
      this.showFullscreenQrcode = true;
    } catch (_) {
      this.cardError = '无法调整屏幕亮度';
    }
  }

  private async closeFullscreenQrcode(): Promise<void> {
    this.showFullscreenQrcode = false;
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.windowStage.getMainWindowSync().setWindowBrightness(this.originalBrightness);
    } catch (_) {
      // Window may already be unavailable while the page or ability is leaving the foreground.
    }
    this.originalBrightness = -1;
  }

  aboutToDisappear(): void {
    if (this.showFullscreenQrcode) this.closeFullscreenQrcode();
  }

  private todayCourses(): Array<Course> {
    const weekday = ((AhuCache.now().getDay() + 6) % 7) + 1;
    return this.courses.filter((course: Course): boolean =>
      courseWeekday(course) === weekday && (course.weekIndexes ?? []).includes(this.currentWeek))
      .sort((left: Course, right: Course): number => courseStartTime(left) - courseStartTime(right));
  }

  private currentMinutes(): number {
    const now = AhuCache.now();
    return now.getHours() * 60 + now.getMinutes();
  }

  private courseStart(course: Course): number {
    return PERIOD_START[Math.max(0, courseStartTime(course) - 1)] ?? 0;
  }

  private courseEnd(course: Course): number {
    const endPeriod = courseStartTime(course) + courseLength(course) - 1;
    return PERIOD_END[Math.max(0, endPeriod - 1)] ?? 0;
  }

  private activeCourse(courses: Array<Course>): Course | undefined {
    const minutes = this.currentMinutes();
    return courses.find((course: Course): boolean => minutes >= this.courseStart(course) && minutes <= this.courseEnd(course));
  }

  private nextCourse(courses: Array<Course>): Course | undefined {
    const minutes = this.currentMinutes();
    return courses.find((course: Course): boolean => minutes < this.courseStart(course));
  }

  private dateLabel(): string {
    const now = AhuCache.now();
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return `${now.getMonth() + 1}`.padStart(2, '0') + '-' + `${now.getDate()}`.padStart(2, '0') +
      ` / 周${weekdays[now.getDay()]}`;
  }

  private shortLocation(location?: string): string {
    return (location ?? '')
      .replace('博学北楼', '博北').replace('博学南楼', '博南')
      .replace('笃行北楼', '笃北').replace('笃行南楼', '笃南')
      .replace('互联大楼', '互楼').replace('体育场', '体');
  }

  private widgetById(id: string): HomeWidget | undefined {
    return HOME_WIDGETS.find((widget: HomeWidget): boolean => widget.id === id);
  }

  private saveSlots(slots: Array<string>): void {
    this.slots = slots;
    AhuCache.saveHomeWidgetSlots(slots);
  }

  private removeWidget(index: number): void {
    const next = this.slots.slice();
    next[index] = '';
    this.saveSlots(next);
  }

  private addWidget(id: string): void {
    if (this.slots.includes(id)) {
      return;
    }
    const index = this.slots.findIndex((value: string): boolean => value.length === 0);
    if (index < 0) {
      return;
    }
    const next = this.slots.slice();
    next[index] = id;
    this.saveSlots(next);
  }

  private moveWidget(index: number, offset: number): void {
    const target = index + offset;
    if (target < 0 || target >= this.slots.length) {
      return;
    }
    const next = this.slots.slice();
    const value = next[index];
    next[index] = next[target];
    next[target] = value;
    this.saveSlots(next);
  }

  private updateDrag(index: number, offsetX: number, offsetY: number): void {
    if (this.dragIndex !== index) return;
    this.dragOffsetX = offsetX; this.dragOffsetY = offsetY;
    const sourceRow = Math.floor(index / 2); const sourceColumn = index % 2;
    const row = Math.max(0, Math.min(3, sourceRow + Math.round(offsetY / 92)));
    const column = Math.max(0, Math.min(1, sourceColumn + Math.round(offsetX / 170)));
    this.dragTarget = row * 2 + column;
  }

  private finishDrag(): void {
    if (this.dragIndex >= 0 && this.dragTarget >= 0 && this.dragIndex !== this.dragTarget) {
      const next = this.slots.slice(); const value = next[this.dragIndex];
      next[this.dragIndex] = next[this.dragTarget]; next[this.dragTarget] = value;
      this.saveSlots(next);
    }
    this.dragIndex = -1; this.dragTarget = -1; this.dragOffsetX = 0; this.dragOffsetY = 0;
  }

  @Builder
  private editHeader() {
    Row() {
      Text('首页')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(AhuColors.onSurface)
        .layoutWeight(1);
      if (this.homeEditEnabled || this.isEditing) {
        Button(this.isEditing ? '完成' : '编辑', { type: ButtonType.Capsule })
          .fontColor(this.isEditing ? AhuColors.onPrimaryAction : AhuColors.onSurface)
          .backgroundColor(this.isEditing ? AhuColors.primaryAction : AhuColors.card)
          .onClick(() => { this.isEditing = !this.isEditing; });
      }
    }
    .width('100%')
    .padding({ left: 24, right: 16, top: 24 });
  }

  @Builder
  private glance(courses: Array<Course>) {
    Column({ space: 28 }) {
      Text(this.dateLabel())
        .fontSize(AhuTypography.body)
        .fontColor(AhuColors.onSurface);
      Column({ space: 8 }) {
        if (this.activeCourse(courses)) {
          Text($r('app.string.home_in_class')).fontSize(AhuTypography.body).fontWeight(FontWeight.Bold);
          Text(this.activeCourse(courses)?.name ?? '')
            .fontSize(40).fontWeight(FontWeight.Bold).fontColor(AhuColors.onSurface).maxLines(2);
          Text(`距下课还有 ${Math.max(0, this.courseEnd(this.activeCourse(courses)!) - this.currentMinutes())} 分钟`)
            .fontSize(AhuTypography.body).fontColor(AhuColors.onSurfaceSecondary);
        } else if (this.nextCourse(courses)) {
          Text($r('app.string.home_next_class')).fontSize(AhuTypography.body).fontWeight(FontWeight.Bold);
          Text(this.nextCourse(courses)?.name ?? '')
            .fontSize(40).fontWeight(FontWeight.Bold).fontColor(AhuColors.onSurface).maxLines(2);
          Text(`还有 ${Math.max(0, this.courseStart(this.nextCourse(courses)!) - this.currentMinutes())} 分钟，` +
            `${this.nextCourse(courses)?.location ?? ''}`)
            .fontSize(AhuTypography.body).fontColor(AhuColors.onSurfaceSecondary).maxLines(1);
        } else {
          Text($r('app.string.home_today_courses')).fontSize(AhuTypography.body).fontWeight(FontWeight.Bold);
          Text(courses.length > 0 ? $r('app.string.home_all_courses_done') : $r('app.string.home_no_courses'))
            .fontSize(34).fontWeight(FontWeight.Bold).fontColor(AhuColors.onSurface);
          Text('准备您自己的安排吧').fontSize(AhuTypography.body).fontColor(AhuColors.onSurfaceSecondary);
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .onClick(() => this.onOpenSchedule());
    }
    .width('100%')
    .padding({ left: 32, right: 32, top: 8 });
  }

  @Builder
  private todayTimeline(courses: Array<Course>) {
    AhuInsetCard() {
      Column({ space: 14 }) {
        if (courses.length === 0) {
          Text($r('app.string.home_no_courses')).fontSize(AhuTypography.body).fontWeight(FontWeight.Bold);
          Text($r('app.string.home_view_schedule')).fontColor(AhuColors.onSurfaceSecondary);
        } else {
          ForEach(courses, (course: Course) => {
            Row({ space: 12 }) {
              Text(`${courseStartTime(course)} - ${courseStartTime(course) + courseLength(course) - 1}`)
                .width(54).fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary);
              Text(course.name ?? '').layoutWeight(1).fontSize(AhuTypography.body).fontWeight(FontWeight.Medium).maxLines(1);
              Text(this.shortLocation(course.location)).fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary);
            }
            .width('100%');
          }, (course: Course) => `${course.courseId}-${course.startTime}`);
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .onClick(() => this.onOpenSchedule());
    }
  }

  @Builder
  private campusCard() {
    AhuInsetCard() {
      if (this.showCardQrcode) {
        Column({ space: 12 }) {
          Row() {
            Button('←', { type: ButtonType.Circle }).width(40).height(40)
              .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.chipUnselected)
              .onClick(() => this.showCardQrcode = false);
            Blank();
            Button('放大', { type: ButtonType.Capsule }).height(40)
              .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.chipUnselected)
              .enabled(this.cardQrcode.length > 0)
              .onClick(() => this.openFullscreenQrcode());
          }.width('100%');
          if (this.qrcodeLoading) {
            LoadingProgress().width(48).height(48).color(AhuColors.primaryAction);
          } else if (this.cardQrcode.length > 0) {
            QRCode(this.cardQrcode).width(200).height(200).color('#000000').backgroundColor('#FFFFFF')
              .onClick(() => {
                this.loadQrcode();
                this.loadBalance(true);
              });
          } else {
            Text(this.cardError.length > 0 ? this.cardError : '校园码加载失败')
              .fontColor(AhuColors.error).onClick(() => this.loadQrcode());
          }
          Text(this.cardBalance === undefined ? '--' : `¥ ${this.cardBalance.toFixed(2)}`)
            .fontSize(24).fontWeight(FontWeight.Bold).fontColor(AhuColors.onSurface);
        }.width('100%').alignItems(HorizontalAlign.Center);
      } else {
        Row() {
          Column({ space: 16 }) {
            Text('校园卡余额').fontSize(AhuTypography.body).fontWeight(FontWeight.Bold).fontColor(AhuColors.onSurface);
            Text(this.cardBalance === undefined ? '--' : `¥ ${this.cardBalance.toFixed(2)}`)
              .fontSize(26).fontWeight(FontWeight.Bold).fontColor(AhuColors.onSurface);
            if (this.cardError.length > 0) Text(this.cardError).fontSize(12).fontColor(AhuColors.error).maxLines(1);
          }.layoutWeight(1).alignItems(HorizontalAlign.Start).onClick(() => this.openQrcode());
          Button('↻', { type: ButtonType.Circle }).width(40).height(40).fontSize(20)
            .backgroundColor(AhuColors.chipUnselected).fontColor(AhuColors.onSurface).onClick(() => this.loadBalance(true));
          Divider().vertical(true).height(80).color(AhuColors.divider).margin({ left: 12, right: 12 });
          Text('充\n值').fontSize(AhuTypography.body).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
            .onClick(() => this.onOpenRecharge());
        }.width('100%').alignItems(VerticalAlign.Center);
      }
    }
  }

  @Builder
  private weatherCard() {
    if (this.weatherRepository.showOnHome() && this.weather) {
      AhuInsetCard() {
        Row({ space: 16 }) {
          SymbolGlyph($r('sys.symbol.drop')).fontSize(38).fontColor(['#FFB300']);
          Column({ space: 5 }) {
            Text(this.weather.district ?? this.weather.city ?? '当前位置').fontSize(AhuTypography.label)
              .fontColor(AhuColors.onSurfaceSecondary);
            Text(`${this.weather.temperature === undefined ? '--' : Math.round(this.weather.temperature)}°  ${this.weather.weather ?? ''}`)
              .fontSize(26).fontWeight(FontWeight.Bold);
            Text(this.rainSoon(this.weather) ? '近期可能有降水，记得带伞' :
              `空气质量 ${this.weather.aqi_category ?? '--'} ${this.weather.aqi ?? ''}`)
              .fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary);
          }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          Text('›').fontSize(28).fontColor(AhuColors.onSurfaceSecondary);
        }.width('100%').onClick(() => this.onOpenWidget('weather'));
      }
    }
  }

  @Builder
  private fullscreenQrcode() {
    Column() {
      QRCode(this.cardQrcode).width(340).height(340).color('#000000').backgroundColor('#FFFFFF');
      Text('点击空白处关闭').fontSize(AhuTypography.body).fontColor('#66000000').margin({ top: 24 });
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    .backgroundColor('#FFFFFFFF')
    .onClick(() => this.closeFullscreenQrcode());
  }

  @Builder
  private widgetGrid() {
    Grid() {
      ForEach(this.slots, (id: string, index: number) => {
        GridItem() {
          if (id.length > 0 && this.widgetById(id)) {
            Stack({ alignContent: Alignment.TopEnd }) {
              Column({ space: 8 }) {
                SymbolGlyph(this.widgetById(id)?.symbol)
                  .fontSize(30)
                  .fontColor([this.widgetById(id)?.tint ?? '#607D8B']);
                Text(this.widgetById(id)?.title ?? '')
                  .fontSize(AhuTypography.label)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(AhuColors.onSurface)
                  .maxLines(1);
              }
              .width('100%').height('100%')
              .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center);
              if (this.isEditing) {
                Button('×', { type: ButtonType.Circle })
                  .width(28).height(28).margin(6)
                  .fontSize(18).fontColor(AhuColors.onPrimaryAction)
                  .backgroundColor(AhuColors.error)
                  .onClick(() => this.removeWidget(index));
              }
            }
            .width('100%').height('100%')
            .backgroundColor(AhuColors.card).borderRadius(24)
            .opacity(this.dragIndex === index ? 0.55 : 1)
            .translate({ x: this.dragIndex === index ? this.dragOffsetX : 0,
              y: this.dragIndex === index ? this.dragOffsetY : 0 })
            .border({ width: this.dragTarget === index ? 2 : 0, color: AhuColors.primaryAction })
            .gesture(GestureGroup(GestureMode.Sequence,
              LongPressGesture({ repeat: false, duration: 350 }).onAction(() => {
                if (this.homeEditEnabled) {
                  this.isEditing = true; this.dragIndex = index; this.dragTarget = index;
                }
              }),
              PanGesture({ fingers: 1 }).onActionUpdate((event: GestureEvent) => {
                this.updateDrag(index, event.offsetX, event.offsetY);
              }).onActionEnd(() => this.finishDrag()).onActionCancel(() => this.finishDrag())
            ))
            .onClick(() => {
              if (!this.isEditing) {
                this.onOpenWidget(id);
              }
            });
          } else {
            Column() {
              if (this.isEditing) {
                Text('+').fontSize(28).fontColor(AhuColors.onSurfaceSecondary);
              }
            }
            .width('100%').height('100%')
            .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
            .border({ width: this.isEditing ? 1 : 0, color: AhuColors.divider, style: BorderStyle.Dashed })
            .backgroundColor(this.dragTarget === index ? AhuColors.accentSurface : Color.Transparent)
            .borderRadius(24);
          }
        }
      }, (_: string, index: number) => `${index}`);
    }
    .columnsTemplate('1fr 1fr')
    .rowsGap(12)
    .columnsGap(12)
    .height(368)
    .padding({ left: 16, right: 16 });
  }

  @Builder
  private widgetEditor() {
    AhuInsetCard() {
      Column({ space: 14 }) {
        Text('已添加工具')
          .fontSize(AhuTypography.body).fontWeight(FontWeight.Bold).fontColor(AhuColors.onSurface);
        Text('长按上方卡片并拖到目标槽位；也可使用下方按钮精确排序')
          .fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary);
        ForEach(this.slots, (id: string, index: number) => {
          if (id.length > 0 && this.widgetById(id)) {
            Row({ space: 8 }) {
              Text(this.widgetById(id)?.title ?? '').layoutWeight(1).fontColor(AhuColors.onSurface);
              Button('↑', { type: ButtonType.Circle })
                .width(34).height(34).enabled(index > 0)
                .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.chipUnselected)
                .onClick(() => this.moveWidget(index, -1));
              Button('↓', { type: ButtonType.Circle })
                .width(34).height(34).enabled(index < this.slots.length - 1)
                .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.chipUnselected)
                .onClick(() => this.moveWidget(index, 1));
            }
            .width('100%');
          }
        }, (_: string, index: number) => `selected-${index}`);
        Divider().color(AhuColors.divider);
        Text('添加小工具')
          .fontSize(AhuTypography.body).fontWeight(FontWeight.Bold).fontColor(AhuColors.onSurface);
        Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(8), cross: LengthMetrics.vp(8) } }) {
          ForEach(HOME_WIDGETS, (widget: HomeWidget) => {
            if (!this.slots.includes(widget.id)) {
              Button(`+ ${widget.title}`, { type: ButtonType.Capsule })
                .fontSize(AhuTypography.label)
                .fontColor(AhuColors.onSurface)
                .backgroundColor(AhuColors.chipUnselected)
                .enabled(this.slots.includes(''))
                .onClick(() => this.addWidget(widget.id));
            }
          }, (widget: HomeWidget) => widget.id);
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start);
    }
  }

  build() {
    Stack() {
      if (this.isLoading) {
        AhuLoading({ message: $r('app.string.home_loading') });
      } else {
        AhuScreen({ scrollable: true, clearBottomNav: true }) {
          this.editHeader();
          this.glance(this.todayCourses());
          this.todayTimeline(this.todayCourses());
          this.weatherCard();
          this.campusCard();
          this.widgetGrid();
          if (this.isEditing) {
            this.widgetEditor();
          }
        }
      }
      if (this.showFullscreenQrcode) {
        this.fullscreenQrcode();
      }
    }
    .width('100%').height('100%');
  }
}
