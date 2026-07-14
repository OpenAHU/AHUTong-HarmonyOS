import { AhuChip, AhuColors, AhuDimens, AhuPageHeader, AhuTypography } from 'core_designsystem';
import { ScheduleSetupRepository, ScheduleSetupValues } from 'data_schedule';

@Component
export struct ScheduleSetupPage {
  private readonly repository: ScheduleSetupRepository = new ScheduleSetupRepository();
  @State schoolYear: string = '';
  @State schoolTerm: string = '1';
  @State currentWeek: string = '1';
  @State errorMessage: string = '';
  onSetup: () => void = () => {};

  aboutToAppear(): void {
    const defaults = this.repository.defaultValues();
    this.schoolYear = defaults.schoolYear;
    this.schoolTerm = defaults.schoolTerm;
    this.currentWeek = `${defaults.currentWeek}`;
  }

  private save(): void {
    if (!/^\d{4}-\d{4}$/.test(this.schoolYear.trim())) {
      this.errorMessage = '学年格式应为 2025-2026';
      return;
    }
    const week = Number.parseInt(this.currentWeek, 10);
    if (!Number.isFinite(week) || week < 1 || week > 30) {
      this.errorMessage = '当前周应为 1 至 30';
      return;
    }
    const values: ScheduleSetupValues = {
      schoolYear: this.schoolYear,
      schoolTerm: this.schoolTerm,
      currentWeek: week
    };
    this.repository.save(values);
    this.onSetup();
  }

  @Builder
  private label(text: ResourceStr) {
    Text(text)
      .width('100%')
      .padding({ left: AhuDimens.titleHorizontal, right: AhuDimens.titleHorizontal })
      .fontSize(AhuTypography.body)
      .fontWeight(FontWeight.Bold)
      .fontColor(AhuColors.onSurface);
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Scroll() {
        Column({ space: AhuDimens.contentHorizontal }) {
          AhuPageHeader({ title: $r('app.string.schedule_setup_title') });
          Blank().height(8);
          this.label($r('app.string.schedule_school_year'));
          TextInput({ text: this.schoolYear })
            .height(64)
            .margin({ left: AhuDimens.contentHorizontal, right: AhuDimens.contentHorizontal })
            .padding({ left: AhuDimens.titleHorizontal, right: AhuDimens.titleHorizontal })
            .fontSize(AhuTypography.body)
            .fontColor(AhuColors.onSurface)
            .backgroundColor(AhuColors.card)
            .borderRadius(32)
            .onChange((value: string) => {
              this.schoolYear = value;
            });

          this.label($r('app.string.schedule_school_term'));
          Row({ space: 8 }) {
            ForEach(['1', '2', '3'], (term: string) => {
              AhuChip({
                text: term,
                selected: this.schoolTerm === term,
                clickAction: () => {
                  this.schoolTerm = term;
                }
              });
            });
          }
          .margin({ left: AhuDimens.contentHorizontal, right: AhuDimens.contentHorizontal })
          .padding(8)
          .backgroundColor(AhuColors.card)
          .borderRadius(32);

          this.label($r('app.string.schedule_current_week'));
          TextInput({ text: this.currentWeek })
            .height(64)
            .margin({ left: AhuDimens.contentHorizontal, right: AhuDimens.contentHorizontal })
            .padding({ left: AhuDimens.titleHorizontal, right: AhuDimens.titleHorizontal })
            .fontSize(AhuTypography.body)
            .fontColor(AhuColors.onSurface)
            .backgroundColor(AhuColors.card)
            .borderRadius(32)
            .type(InputType.Number)
            .onChange((value: string) => {
              this.currentWeek = value;
            });

          if (this.errorMessage.length > 0) {
            Text(this.errorMessage)
              .margin({ left: AhuDimens.titleHorizontal, right: AhuDimens.titleHorizontal })
              .fontSize(AhuTypography.label)
              .fontColor(AhuColors.error);
          }
        }
        .width('100%')
        .padding({ bottom: 104 });
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off);

      Button($r('app.string.schedule_setup_confirm'), { type: ButtonType.Capsule })
        .margin(AhuDimens.contentHorizontal)
        .padding({ left: 24, right: 24, top: 14, bottom: 14 })
        .fontSize(AhuTypography.body)
        .fontColor(AhuColors.onPrimaryAction)
        .backgroundColor(AhuColors.primaryAction)
        .onClick(() => this.save());
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AhuColors.pageBackground);
  }
}
