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
import { AhuCache } from 'core_datastore';
import { BackPressDispatcher } from 'core_common';

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
  @State selectedCourse?: Course = undefined;
  @State overviewSchedule: boolean = false;
  @State previewNextSemester: boolean = false;
  @State settingsVisible: boolean = false;
  @StorageLink('ahu_schedule_config_revision') @Watch('onScheduleConfigChanged') scheduleConfigRevision: number = 0;
  active: boolean = false;

  aboutToAppear(): void {
    BackPressDispatcher.register('weekly_schedule', () => this.handleBackPress());
    const config = this.setupRepository.displayConfig();
    if (config) {
      this.applyConfig(config);
    }
    this.load(false);
  }

  aboutToDisappear(): void { BackPressDispatcher.unregister('weekly_schedule'); }

  private onScheduleConfigChanged(): void {
    const config = this.setupRepository.displayConfig();
    if (config) this.applyConfig(config);
    this.load(false);
  }

  private handleBackPress(): boolean {
    if (!this.active) return false;
    if (this.selectedCourse) { this.selectedCourse = undefined; return true; }
    if (this.settingsVisible) { this.settingsVisible = false; return true; }
    return false;
  }

  private applyConfig(config: ScheduleDisplayConfig): void {
    this.currentWeek = config.currentWeek;
    this.selectedWeek = config.currentWeek;
    this.startDate = config.startDate;
  }

  private async load(refresh: boolean): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    const result = this.previewNextSemester ? await this.repository.getNextSchedule(refresh) :
      await this.repository.getSchedule(refresh);
    if (result.isSuccess) {
      this.courses = result.data ?? [];
    } else {
      this.errorMessage = result.error?.message ?? '课表加载失败';
    }
    this.isLoading = false;
  }

  private coursesOfDay(day: number): Array<Course> {
    return this.courses.filter((course: Course): boolean =>
      courseWeekday(course) === day && (this.overviewSchedule || (course.weekIndexes ?? []).includes(this.selectedWeek)));
  }

  private overviewGroups(day: number): Array<Array<Course>> {
    const groups: Array<Array<Course>> = [];
    this.coursesOfDay(day).forEach((course: Course) => {
      const group = groups.find((items: Array<Course>) => courseStartTime(items[0]) === courseStartTime(course) &&
        courseLength(items[0]) === courseLength(course));
      if (group) group.push(course); else groups.push([course]);
    });
    return groups;
  }

  private async toggleNextSemester(enabled: boolean): Promise<void> {
    if (this.previewNextSemester === enabled) return;
    this.previewNextSemester = enabled;
    this.selectedWeek = enabled ? 1 : this.currentWeek;
    await this.load(false);
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

  private weekDescription(course: Course): string {
    const weeks: Array<number> = course.weekIndexes ?? [];
    if (weeks.length === 0) {
      return '周次未知';
    }
    if (weeks.length === weeks[weeks.length - 1] - weeks[0] + 1) {
      return `第 ${weeks[0]}-${weeks[weeks.length - 1]} 周`;
    }
    const interval = weeks.length > 1 ? weeks[1] - weeks[0] : 0;
    if (interval === 2) {
      const parity = weeks[0] % 2 === 0 ? '双周' : '单周';
      return `第 ${weeks[0]}-${weeks[weeks.length - 1]} 周（${parity}）`;
    }
    return `第 ${weeks.join('、')} 周`;
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
          if (this.previewNextSemester) this.toggleNextSemester(false);
          else this.selectedWeek = this.currentWeek;
        });
      Button('⚙', { type: ButtonType.Circle }).width(40).height(40).fontSize(20)
        .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.card)
        .onClick(() => { this.settingsVisible = true; });
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
    .position({ x: 0, y: Math.max(0, courseStartTime(course) - 1) * 52 })
    .onClick(() => {
      this.selectedCourse = course;
    });
  }

  @Builder
  private overviewCourseGroup(courses: Array<Course>) {
    Column() {
      ForEach(courses, (course: Course) => {
        Column({ space: 2 }) {
          Text(course.name ?? '未命名课程').fontSize(10).fontWeight(FontWeight.Bold).fontColor('#17202A')
            .maxLines(courses.length <= 2 ? 2 : 1).textOverflow({ overflow: TextOverflow.Ellipsis });
          Text(`${course.startWeek}-${course.endWeek}周`).fontSize(9).fontColor('#17202A').maxLines(1);
          Text(this.shortLocation(course.location)).fontSize(9).fontWeight(FontWeight.Bold).fontColor('#17202A')
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis });
        }.width('100%').layoutWeight(1).padding(3).justifyContent(FlexAlign.Center)
          .backgroundColor(this.colorOf(course))
          .opacity((course.weekIndexes ?? []).includes(this.selectedWeek) ? 1 : 0.5)
          .onClick(() => { this.selectedCourse = course; });
      }, (course: Course, index: number) => `${course.courseId}-${course.startTime}-${index}`);
    }.width('100%').height(Math.max(48, courseLength(courses[0]) * 52 - 4))
      .borderRadius(8).clip(true)
      .position({ x: 0, y: Math.max(0, courseStartTime(courses[0]) - 1) * 52 });
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
              .fontColor(this.selectedWeek === this.currentWeek && index + 1 === ((AhuCache.now().getDay() + 6) % 7) + 1
                ? AhuColors.onPrimaryAction : AhuColors.onSurface);
            Text(this.dateLabel(index + 1))
              .fontSize(9)
              .fontColor(this.selectedWeek === this.currentWeek && index + 1 === ((AhuCache.now().getDay() + 6) % 7) + 1
                ? AhuColors.onPrimaryAction : AhuColors.onSurfaceSecondary);
          }
          .height(52)
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(this.selectedWeek === this.currentWeek && index + 1 === ((AhuCache.now().getDay() + 6) % 7) + 1
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
            if (this.overviewSchedule) {
              ForEach(this.overviewGroups(dayIndex + 1), (courses: Array<Course>) => {
                this.overviewCourseGroup(courses);
              }, (courses: Array<Course>) => `${courseStartTime(courses[0])}-${courseLength(courses[0])}`);
            } else {
              ForEach(this.coursesOfDay(dayIndex + 1), (course: Course) => {
                this.courseCard(course);
              }, (course: Course) => `${course.courseId}-${course.startTime}-${this.selectedWeek}`);
            }
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

  @Builder
  private detailOverlay(course: Course) {
    Stack({ alignContent: Alignment.Center }) {
      Row()
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
        .onClick(() => {
          this.selectedCourse = undefined;
        });
      Column({ space: 18 }) {
        Text(course.name ?? '未命名课程')
          .width('100%')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AhuColors.onSurface);
        Text(`${this.weekDescription(course)} · 星期${WEEKDAYS[courseWeekday(course) - 1] ?? ''} · ` +
          `第 ${courseStartTime(course)}-${courseStartTime(course) + courseLength(course) - 1} 节`)
          .fontSize(AhuTypography.body)
          .fontColor(AhuColors.onSurface);
        Divider().color(AhuColors.divider);
        Row({ space: 12 }) {
          Text('地点').fontColor(AhuColors.onSurfaceSecondary);
          Text(course.location ?? '未知').fontColor(AhuColors.onSurface).layoutWeight(1);
        }
        Row({ space: 12 }) {
          Text('教师').fontColor(AhuColors.onSurfaceSecondary);
          Text(course.teacher ?? '未知').fontColor(AhuColors.onSurface).layoutWeight(1);
        }
        Button('关闭', { type: ButtonType.Capsule })
          .alignSelf(ItemAlign.End)
          .fontColor(AhuColors.onPrimaryAction)
          .backgroundColor(AhuColors.primaryAction)
          .onClick(() => {
            this.selectedCourse = undefined;
          });
      }
      .width('86%')
      .padding(24)
      .backgroundColor(AhuColors.card)
      .borderRadius(28);
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  private scheduleSetting(title: string, description: string, selected: boolean,
    onChange: (value: boolean) => void) {
    Row({ space: 12 }) {
      Column({ space: 3 }) {
        Text(title).fontSize(AhuTypography.body).fontWeight(FontWeight.Medium).width('100%');
        Text(description).fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary).width('100%');
      }.layoutWeight(1).alignItems(HorizontalAlign.Start);
      Toggle({ type: ToggleType.Switch, isOn: selected }).onChange(onChange);
    }.width('100%');
  }

  @Builder
  private settingsOverlay() {
    Stack({ alignContent: Alignment.Center }) {
      Row().width('100%').height('100%').backgroundColor('#66000000')
        .onClick(() => { this.settingsVisible = false; });
      Column({ space: 18 }) {
        Text('课表设置').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold).width('100%');
        this.scheduleSetting('总览课表', '显示全部周次的课程，重叠课程会平分同一块时间区域',
          this.overviewSchedule, (value: boolean) => { this.overviewSchedule = value; });
        this.scheduleSetting('预览下学期课表', '切换到教务系统中的下学期课表',
          this.previewNextSemester, (value: boolean) => { this.toggleNextSemester(value); });
        Button('完成', { type: ButtonType.Capsule }).width('100%')
          .fontColor(AhuColors.onPrimaryAction).backgroundColor(AhuColors.primaryAction)
          .onClick(() => { this.settingsVisible = false; });
      }.width('88%').padding(24).backgroundColor(AhuColors.card).borderRadius(28);
    }.width('100%').height('100%');
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

      if (this.selectedCourse) {
        this.detailOverlay(this.selectedCourse);
      }
      if (this.settingsVisible) {
        this.settingsOverlay();
      }
    }
    .width('100%')
    .height('100%');
  }
}
