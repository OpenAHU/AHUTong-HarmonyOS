import {
  AhuColors,
  AhuEmptyState,
  AhuLoading,
  AhuTypography
} from 'core_designsystem';
import { Course, courseLength, courseStartTime, courseWeekday } from 'core_model';
import {
  ScheduleDisplayConfig,
  ScheduleRepository,
  ScheduleRepositoryProvider,
  ScheduleSetupRepository
} from 'data_schedule';

const WEEKDAYS: Array<string> = ['一', '二', '三', '四', '五', '六', '日'];
const COURSE_COLORS: Array<string> = [
  '#82B1FF', '#80CBC4', '#FFAB91', '#CE93D8', '#FFD180', '#90CAF9', '#A5D6A7', '#F48FB1'
];

@Component
export struct WeeklySchedulePage {
  private readonly repository: ScheduleRepository = ScheduleRepositoryProvider.get();
  private readonly setupRepository: ScheduleSetupRepository = new ScheduleSetupRepository();
  @State courses: Array<Course> = [];
  @State selectedWeek: number = 1;
  @State currentWeek: number = 1;
  @State startDate: string = '';
  @State isLoading: boolean = true;
  @State errorMessage: string = '';

  aboutToAppear(): void {
    const config = this.setupRepository.displayConfig();
    if (config) {
      this.applyConfig(config);
    }
    this.load(false);
  }

  private applyConfig(config: ScheduleDisplayConfig): void {
    this.currentWeek = config.currentWeek;
    this.selectedWeek = config.currentWeek;
    this.startDate = config.startDate;
  }

  private async load(refresh: boolean): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    const result = await this.repository.getSchedule(refresh);
    if (result.isSuccess) {
      this.courses = result.data ?? [];
    } else {
      this.errorMessage = result.error?.message ?? '课表加载失败';
    }
    this.isLoading = false;
  }

  private coursesOfDay(day: number): Array<Course> {
    return this.courses.filter((course: Course): boolean =>
      courseWeekday(course) === day && (course.weekIndexes ?? []).includes(this.selectedWeek));
  }

  private colorOf(course: Course): string {
    const value = course.name ?? '';
    let hash = 0;
    for (let index = 0; index < value.length; index++) {
      hash = (hash * 31 + value.charCodeAt(index)) >>> 0;
    }
    return COURSE_COLORS[hash % COURSE_COLORS.length];
  }

  private shortLocation(location?: string): string {
    return (location ?? '未知')
      .replace('博学北楼', '博北')
      .replace('博学南楼', '博南')
      .replace('笃行南楼', '笃南')
      .replace('笃行北楼', '笃北')
      .replace('互联大楼', '互楼')
      .replace('体育场', '体');
  }

  private dateLabel(day: number): string {
    if (this.startDate.length === 0) {
      return '';
    }
    const date = new Date(`${this.startDate}T00:00:00`);
    date.setDate(date.getDate() + (this.selectedWeek - 1) * 7 + day - 1);
    return `${date.getMonth() + 1}`.padStart(2, '0') + '-' + `${date.getDate()}`.padStart(2, '0');
  }

  @Builder
  private weekSelector() {
    Row({ space: 8 }) {
      Scroll() {
        Row({ space: 8 }) {
          ForEach(Array.from({ length: 20 }, (_: Object, index: number) => index + 1), (week: number) => {
            Text(`${week}`)
              .fontSize(AhuTypography.body)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.selectedWeek === week ? AhuColors.onPrimaryAction : AhuColors.onSurface)
              .backgroundColor(this.selectedWeek === week ? AhuColors.chipSelected : Color.Transparent)
              .borderRadius(24)
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .onClick(() => {
                this.selectedWeek = week;
              });
          }, (week: number) => `${week}`);
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .layoutWeight(1);

      Button('今', { type: ButtonType.Circle })
        .width(40)
        .height(40)
        .fontSize(AhuTypography.label)
        .fontWeight(FontWeight.Bold)
        .fontColor(AhuColors.onSurface)
        .backgroundColor(AhuColors.card)
        .onClick(() => {
          this.selectedWeek = this.currentWeek;
        });
      Button('↻', { type: ButtonType.Circle })
        .width(40)
        .height(40)
        .fontSize(22)
        .fontColor(AhuColors.onSurface)
        .backgroundColor(AhuColors.card)
        .onClick(() => this.load(true));
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 4 });
  }

  @Builder
  private courseCard(course: Course) {
    Column({ space: 3 }) {
      Text(course.name ?? '未命名课程')
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor('#17202A')
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis });
      Text(this.shortLocation(course.location))
        .width('100%')
        .padding(2)
        .fontSize(10)
        .fontWeight(FontWeight.Bold)
        .fontColor('#17202A')
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .backgroundColor('#CCFFFFFF')
        .borderRadius(5);
    }
    .width('100%')
    .height(Math.max(48, courseLength(course) * 52 - 4))
    .padding(4)
    .justifyContent(FlexAlign.SpaceBetween)
    .backgroundColor(this.colorOf(course))
    .borderRadius(8)
    .position({ x: 0, y: Math.max(0, courseStartTime(course) - 1) * 52 });
  }

  @Builder
  private timetable() {
    Column() {
      Row() {
        Blank().width(36);
        ForEach(WEEKDAYS, (weekday: string, index: number) => {
          Column({ space: 2 }) {
            Text(weekday)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.selectedWeek === this.currentWeek && index + 1 === ((new Date().getDay() + 6) % 7) + 1
                ? AhuColors.onPrimaryAction : AhuColors.onSurface);
            Text(this.dateLabel(index + 1))
              .fontSize(9)
              .fontColor(this.selectedWeek === this.currentWeek && index + 1 === ((new Date().getDay() + 6) % 7) + 1
                ? AhuColors.onPrimaryAction : AhuColors.onSurfaceSecondary);
          }
          .height(52)
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(this.selectedWeek === this.currentWeek && index + 1 === ((new Date().getDay() + 6) % 7) + 1
            ? AhuColors.primaryAction : Color.Transparent)
          .borderRadius(8);
        }, (weekday: string) => weekday);
      }
      .width('100%');

      Row() {
        Column() {
          ForEach(Array.from({ length: 13 }, (_: Object, index: number) => index + 1), (period: number) => {
            Text(`${period}`)
              .height(52)
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor(AhuColors.onSurfaceSecondary)
              .textAlign(TextAlign.Center);
          }, (period: number) => `${period}`);
        }
        .width(36);
        ForEach(WEEKDAYS, (_: string, dayIndex: number) => {
          Stack() {
            ForEach(this.coursesOfDay(dayIndex + 1), (course: Course) => {
              this.courseCard(course);
            }, (course: Course) => `${course.courseId}-${course.startTime}-${this.selectedWeek}`);
          }
          .height(676)
          .layoutWeight(1)
          .margin({ left: 2, right: 2 });
        }, (_: string, dayIndex: number) => `${dayIndex}`);
      }
      .width('100%');
    }
    .width('100%')
    .padding({ left: 4, right: 4, top: 8, bottom: 16 })
    .backgroundColor(AhuColors.card)
    .borderRadius(24);
  }

  build() {
    Stack() {
      Column() {
        this.weekSelector();
        if (this.isLoading) {
          AhuLoading({ message: $r('app.string.schedule_loading') });
        } else if (this.errorMessage.length > 0) {
          Column({ space: 16 }) {
            Text(this.errorMessage)
              .fontSize(AhuTypography.body)
              .fontColor(AhuColors.error)
              .textAlign(TextAlign.Center);
            Button($r('app.string.schedule_retry'), { type: ButtonType.Capsule })
              .fontColor(AhuColors.onPrimaryAction)
              .backgroundColor(AhuColors.primaryAction)
              .onClick(() => this.load(false));
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center);
        } else if (this.courses.length === 0) {
          AhuEmptyState({ text: '本学期暂无课程' });
        } else {
          Scroll() {
            this.timetable();
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off);
        }
      }
      .width('100%')
      .height('100%')
      .padding({ bottom: 80 })
      .backgroundColor(AhuColors.pageBackground);
    }
    .width('100%')
    .height('100%');
  }
}
