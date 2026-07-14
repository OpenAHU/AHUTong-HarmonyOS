import { AhuChip, AhuColors, AhuEmptyState, AhuInsetCard, AhuLoading, AhuTypography } from 'core_designsystem';
import { Grade, GradeItem, TermGrade } from 'core_model';
import { GradeRepository, GradeRepositoryProvider } from 'data_grade';

@Component
export struct GradePage {
  private readonly repository: GradeRepository = GradeRepositoryProvider.get();
  @State grade?: Grade = undefined;
  @State selectedTerm: string = '';
  @State query: string = '';
  @State isLoading: boolean = true;
  @State errorMessage: string = '';
  onBack: () => void = () => {};

  aboutToAppear(): void {
    this.load(false);
  }

  private async load(refresh: boolean): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    const result = await this.repository.getGrade(refresh);
    if (result.isSuccess && result.data) {
      this.grade = result.data;
      const terms = result.data.termGradeList ?? [];
      if (this.selectedTerm.length === 0 && terms.length > 0) {
        this.selectedTerm = this.termKey(terms[0]);
      }
    } else {
      this.errorMessage = result.error?.message ?? '成绩加载失败';
    }
    this.isLoading = false;
  }

  private termKey(term: TermGrade): string {
    return `${term.schoolYear ?? ''}-${term.schoolTerm ?? ''}`;
  }

  private selected(): TermGrade | undefined {
    return (this.grade?.termGradeList ?? []).find((term: TermGrade): boolean => this.termKey(term) === this.selectedTerm);
  }

  private visibleItems(): Array<GradeItem> {
    const normalized = this.query.trim().toLowerCase();
    const all = normalized.length === 0
      ? this.selected()?.termGradeList ?? []
      : (this.grade?.termGradeList ?? []).flatMap((term: TermGrade): Array<GradeItem> => term.termGradeList ?? []);
    if (normalized.length === 0) {
      return all;
    }
    return all.filter((item: GradeItem): boolean =>
      `${item.course ?? ''} ${item.courseNum ?? ''} ${item.courseType ?? ''}`.toLowerCase().includes(normalized));
  }

  @Builder
  private header() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Button('‹', { type: ButtonType.Circle })
          .width(40).height(40).fontSize(28)
          .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.card)
          .onClick(() => this.onBack());
        Text('成绩单').fontSize(28).fontWeight(FontWeight.Bold).fontColor(AhuColors.onSurface).layoutWeight(1);
        Button('↻', { type: ButtonType.Circle })
          .width(40).height(40).fontSize(22)
          .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.card)
          .onClick(() => this.load(true));
      }
      TextInput({ text: this.query, placeholder: '搜索课程、课程号或课程性质' })
        .width('100%').height(48).borderRadius(24)
        .backgroundColor(AhuColors.card).fontColor(AhuColors.onSurface)
        .onChange((value: string) => { this.query = value; });
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 24 });
  }

  @Builder
  private summary() {
    AhuInsetCard() {
      Row() {
        Column({ space: 4 }) {
          Text('本学期 GPA').fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary);
          Text(this.selected()?.termGradePointAverage ?? '--').fontSize(28).fontWeight(FontWeight.Bold);
        }.layoutWeight(1).alignItems(HorizontalAlign.Start);
        Column({ space: 4 }) {
          Text('总 GPA').fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary);
          Text(this.grade?.totalGradePointAverage ?? '--').fontSize(28).fontWeight(FontWeight.Bold);
        }.layoutWeight(1).alignItems(HorizontalAlign.Start);
        Column({ space: 4 }) {
          Text('总学分').fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary);
          Text(this.grade?.totalCredit ?? '--').fontSize(28).fontWeight(FontWeight.Bold);
        }.layoutWeight(1).alignItems(HorizontalAlign.Start);
      }.width('100%');
    }
  }

  @Builder
  private gradeCard(item: GradeItem) {
    AhuInsetCard({ cornerRadius: 8 }) {
      Column({ space: 7 }) {
        Text(item.course ?? '').fontSize(AhuTypography.body).fontWeight(FontWeight.Bold).fontColor(AhuColors.onSurface);
        Text(`成绩 ${item.grade ?? '--'} · 绩点 ${item.gradePoint ?? '--'} · 学分 ${item.credit ?? '--'}`)
          .fontSize(AhuTypography.body).fontColor(AhuColors.onSurface);
        Text(`${item.courseType ?? ''} (${item.courseNum ?? ''})`)
          .fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary);
        if ((item.gradeDetail ?? '').length > 0) {
          Text((item.gradeDetail ?? '').replace(/<[^>]*>/g, '').trim())
            .fontSize(12).fontColor(AhuColors.primaryAction);
        }
      }.width('100%').alignItems(HorizontalAlign.Start);
    }
  }

  build() {
    Column({ space: 16 }) {
      this.header();
      if (this.isLoading) {
        AhuLoading({ message: '正在加载成绩' });
      } else if (this.errorMessage.length > 0) {
        Column({ space: 14 }) {
          Text(this.errorMessage).fontColor(AhuColors.error).textAlign(TextAlign.Center);
          Button('重试').onClick(() => this.load(false));
        }.layoutWeight(1).justifyContent(FlexAlign.Center);
      } else {
        Scroll() {
          Column({ space: 14 }) {
            if (this.query.length === 0) {
              Scroll() {
                Row({ space: 8 }) {
                  ForEach(this.grade?.termGradeList ?? [], (term: TermGrade) => {
                    AhuChip({
                      text: `${term.schoolYear} 第 ${term.schoolTerm} 学期`,
                      selected: this.selectedTerm === this.termKey(term),
                      clickAction: () => { this.selectedTerm = this.termKey(term); }
                    });
                  }, (term: TermGrade) => this.termKey(term));
                }
              }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).padding({ left: 16, right: 16 });
              this.summary();
            }
            if (this.visibleItems().length === 0) {
              AhuEmptyState({ text: this.query.length > 0 ? '未找到相关课程' : '本学期暂无成绩' });
            } else {
              ForEach(this.visibleItems(), (item: GradeItem) => { this.gradeCard(item); },
                (item: GradeItem) => `${item.semesterId}-${item.courseNum}`);
            }
          }.width('100%').padding({ bottom: 24 });
        }.width('100%').layoutWeight(1).scrollBar(BarState.Off);
      }
    }
    .width('100%').height('100%').backgroundColor(AhuColors.pageBackground);
  }
}
