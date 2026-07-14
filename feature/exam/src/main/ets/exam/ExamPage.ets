import { AhuColors, AhuEmptyState, AhuInsetCard, AhuLoading, AhuTypography } from 'core_designsystem';
import { Exam } from 'core_model';
import { ExamRepository, ExamRepositoryProvider } from 'data_exam';

@Component
export struct ExamPage {
  private readonly repository: ExamRepository = ExamRepositoryProvider.get();
  @State exams: Array<Exam> = [];
  @State query: string = '';
  @State isLoading: boolean = true;
  @State errorMessage: string = '';
  onBack: () => void = () => {};

  aboutToAppear(): void { this.load(false); }
  private async load(refresh: boolean): Promise<void> {
    this.isLoading = true; this.errorMessage = '';
    const result = await this.repository.getExams(refresh);
    if (result.isSuccess) this.exams = result.data ?? [];
    else this.errorMessage = result.error?.message ?? '考试信息加载失败';
    this.isLoading = false;
  }
  private visible(): Array<Exam> {
    const query = this.query.trim().toLowerCase();
    return this.exams.filter((exam: Exam): boolean => query.length === 0 || (exam.course ?? '').toLowerCase().includes(query))
      .sort((left: Exam, right: Exam): number => {
        const statusOrder = this.statusOrder(left) - this.statusOrder(right);
        return statusOrder !== 0 ? statusOrder : (left.time ?? '').localeCompare(right.time ?? '');
      });
  }
  private statusOrder(exam: Exam): number {
    const status = this.status(exam);
    return status === '进行中' ? 0 : status === '未开始' ? 1 : status === '已结束' ? 2 : 3;
  }
  private status(exam: Exam): string {
    const match = (exam.time ?? '').match(/(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2})~(\d{2}:\d{2})/);
    if (!match) return exam.finished ? '已结束' : '时间待定';
    const now = Date.now();
    const start = new Date(`${match[1]}T${match[2]}:00`).getTime();
    const end = new Date(`${match[1]}T${match[3]}:00`).getTime();
    return now < start ? '未开始' : now > end ? '已结束' : '进行中';
  }
  private statusColor(status: string): string {
    return status === '未开始' ? '#4CAF50' : status === '进行中' ? '#FFC107' : '#808080';
  }
  @Builder private header() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Button('‹', { type: ButtonType.Circle }).width(40).height(40).fontSize(28).backgroundColor(AhuColors.card).onClick(() => this.onBack());
        Text('考场查询').fontSize(28).fontWeight(FontWeight.Bold).layoutWeight(1).fontColor(AhuColors.onSurface);
        Button('↻', { type: ButtonType.Circle }).width(40).height(40).fontSize(22).backgroundColor(AhuColors.card).onClick(() => this.load(true));
      }
      TextInput({ text: this.query, placeholder: '搜索课程名称' }).height(48).borderRadius(24).backgroundColor(AhuColors.card)
        .onChange((value: string) => { this.query = value; });
    }.padding({ left: 16, right: 16, top: 24 });
  }
  @Builder private examCard(exam: Exam) {
    AhuInsetCard({ cornerRadius: 8 }) {
      Column({ space: 9 }) {
        Row({ space: 8 }) {
          Text(exam.course ?? '').fontSize(AhuTypography.body).fontWeight(FontWeight.Bold).layoutWeight(1).maxLines(1);
          Text(this.status(exam)).fontSize(12).fontColor('#FFFFFF').padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(this.statusColor(this.status(exam))).borderRadius(12);
        }.width('100%');
        Text(`考试时间：${exam.time ?? '待定'}`).fontColor(AhuColors.onSurface);
        Text(`考试地点：${exam.location ?? '待定'} · 座位号：${exam.seatNum || '待定'}`).fontColor(AhuColors.onSurfaceSecondary);
      }.width('100%').alignItems(HorizontalAlign.Start);
    }
  }
  build() {
    Column({ space: 16 }) {
      this.header();
      if (this.isLoading) AhuLoading({ message: '正在加载考试信息' });
      else if (this.errorMessage.length > 0) {
        Column({ space: 12 }) { Text(this.errorMessage).fontColor(AhuColors.error); Button('重试').onClick(() => this.load(false)); }
          .layoutWeight(1).justifyContent(FlexAlign.Center);
      } else if (this.visible().length === 0) AhuEmptyState({ text: this.query.length > 0 ? '没有匹配的考试' : '暂无考试安排' });
      else {
        Scroll() { Column({ space: 3 }) { ForEach(this.visible(), (exam: Exam) => { this.examCard(exam); },
          (exam: Exam) => `${exam.course}-${exam.time}`); }.padding({ bottom: 24 }); }.layoutWeight(1).scrollBar(BarState.Off);
      }
    }.width('100%').height('100%').backgroundColor(AhuColors.pageBackground);
  }
}
