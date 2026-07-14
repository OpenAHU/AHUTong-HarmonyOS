import { AhuColors, AhuInsetCard, AhuLoading, AhuScreen, AhuTypography } from 'core_designsystem';
import { AhuCache } from 'core_datastore';
import { Course, courseLength, courseStartTime, courseWeekday } from 'core_model';
import { ScheduleRepository, ScheduleRepositoryProvider, ScheduleSetupRepository } from 'data_schedule';

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
  @State courses: Array<Course> = [];
  @State isLoading: boolean = true;
  @State currentWeek: number = 1;
  onOpenSchedule: () => void = () => {};

  aboutToAppear(): void {
    const config = this.setupRepository.displayConfig();
    this.currentWeek = config?.currentWeek ?? 1;
    this.load();
  }

  private async load(): Promise<void> {
    const result = await this.scheduleRepository.getSchedule(false);
    this.courses = result.data ?? [];
    this.isLoading = false;
  }

  private todayCourses(): Array<Course> {
    const weekday = ((new Date().getDay() + 6) % 7) + 1;
    return this.courses.filter((course: Course): boolean =>
      courseWeekday(course) === weekday && (course.weekIndexes ?? []).includes(this.currentWeek))
      .sort((left: Course, right: Course): number => courseStartTime(left) - courseStartTime(right));
  }

  private currentMinutes(): number {
    const now = new Date();
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
    const now = new Date();
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
  private widgetGrid() {
    Grid() {
      ForEach(AhuCache.getHomeWidgetSlots(), (id: string, index: number) => {
        GridItem() {
          if (id.length > 0 && this.widgetById(id)) {
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
            .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
            .backgroundColor(AhuColors.card).borderRadius(24);
          } else {
            Column().width('100%').height('100%');
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

  build() {
    if (this.isLoading) {
      AhuLoading({ message: $r('app.string.home_loading') });
    } else {
      AhuScreen({ scrollable: true, clearBottomNav: true }) {
        this.glance(this.todayCourses());
        this.todayTimeline(this.todayCourses());
        this.widgetGrid();
      }
    }
  }
}
