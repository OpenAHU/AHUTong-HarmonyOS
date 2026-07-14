let storage = new LocalStorage();

@Entry(storage)
@Component
struct ScheduleCard {
  @LocalStorageProp('remainingText') remainingText: string = '暂无课程';
  @LocalStorageProp('dateText') dateText: string = '';
  @LocalStorageProp('emptyText') emptyText: string = '点击打开安大通查看完整课表';
  @LocalStorageProp('course1Name') course1Name: string = '';
  @LocalStorageProp('course1Detail') course1Detail: string = '';
  @LocalStorageProp('course1State') course1State: string = '';
  @LocalStorageProp('course2Name') course2Name: string = '';
  @LocalStorageProp('course2Detail') course2Detail: string = '';
  @LocalStorageProp('course2State') course2State: string = '';
  @LocalStorageProp('course3Name') course3Name: string = '';
  @LocalStorageProp('course3Detail') course3Detail: string = '';
  @LocalStorageProp('course3State') course3State: string = '';
  @LocalStorageProp('themeColor') themeColor: string = '#FF4A90E2';

  @Builder
  private courseRow(name: string, detail: string, state: string) {
    Row({ space: 8 }) {
      Text(state === '正在上课' ? '●' : '○').fontSize(11).fontColor(state === '正在上课' ? this.themeColor : '#FF7A7A7A');
      Column({ space: 1 }) {
        Text(name).fontSize(14).fontWeight(state === '正在上课' ? FontWeight.Bold : FontWeight.Medium)
          .fontColor($r('app.color.schedule_card_text')).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis });
        Text(`${detail}${state === '正在上课' ? ' · 正在上课' : ''}`).fontSize(10).fontColor($r('app.color.schedule_card_secondary'))
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis });
      }.alignItems(HorizontalAlign.Start).layoutWeight(1);
    }.width('100%').padding({ left: 7, right: 7, top: 4, bottom: 4 })
      .backgroundColor(state === '正在上课' ? $r('app.color.schedule_card_ongoing') : Color.Transparent).borderRadius(12);
  }

  build() {
    Column({ space: 5 }) {
      Row({ space: 7 }) {
        Text(this.remainingText).fontSize(15).fontWeight(FontWeight.Bold).fontColor($r('app.color.schedule_card_text'));
        Text(this.dateText).fontSize(11).fontColor($r('app.color.schedule_card_secondary')).layoutWeight(1);
        FormLink({ action: 'message', abilityName: 'ScheduleFormAbility', params: { action: 'refresh' } }) {
          Text('刷新').fontSize(11).fontColor(Color.White).padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(this.themeColor).borderRadius(10);
        }
      }.width('100%');
      FormLink({ action: 'router', abilityName: 'EntryAbility', params: { route: 'schedule' } }) {
        Column({ space: 2 }) {
          if (this.course1Name.length > 0) this.courseRow(this.course1Name, this.course1Detail, this.course1State);
          if (this.course2Name.length > 0) this.courseRow(this.course2Name, this.course2Detail, this.course2State);
          if (this.course3Name.length > 0) this.courseRow(this.course3Name, this.course3Detail, this.course3State);
          if (this.course1Name.length === 0) {
            Column({ space: 4 }) {
              Text('没课啦').fontSize(17).fontWeight(FontWeight.Bold).fontColor($r('app.color.schedule_card_text'));
              Text(this.emptyText).fontSize(10).fontColor($r('app.color.schedule_card_secondary')).textAlign(TextAlign.Center);
            }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center);
          }
        }.width('100%').layoutWeight(1);
      }
    }.width('100%').height('100%').padding(12).backgroundColor($r('app.color.schedule_card_background')).borderRadius(28);
  }
}
