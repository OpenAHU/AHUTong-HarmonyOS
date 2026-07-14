import { AhuChip, AhuColors, AhuInsetCard, AhuLoading, AhuTypography } from 'core_designsystem';
import { AcademicCrawlerClient } from 'data_crawler';
import { AhuCache } from 'core_datastore';

interface Building { id: number; nameZh: string; }
interface RoomBuilding { id: number; nameZh: string; }
interface FreeRoom { id: number; nameZh: string; floor: number; remark?: string; building: RoomBuilding; }
interface FreeRoomResponse { roomList?: Array<FreeRoom>; }
interface DateTimeSegmentRequest {
  startDateTime: string; endDateTime: string; startTime: string; endTime: string;
  units: Array<string>; weekdays: Array<string>;
}
interface FreeRoomRequest {
  buildingId: string; campusId: string; dateTimeSegmentCmd: DateTimeSegmentRequest;
  hasDataPermission: boolean; roomId: string; seatsForLessonGte: string;
}

@Component
export struct FreeClassroomPage {
  private readonly client: AcademicCrawlerClient = new AcademicCrawlerClient();
  @State campusId: number = 1;
  @State buildings: Array<Building> = [];
  @State selectedBuildings: Array<number> = [];
  @State selectedUnits: Array<number> = [];
  @State startDate: string = '';
  @State endDate: string = '';
  @State rooms: Array<FreeRoom> = [];
  @State isLoadingBuildings: boolean = true;
  @State isSearching: boolean = false;
  @State errorMessage: string = '';
  @State filtersExpanded: boolean = true;
  onBack: () => void = () => {};

  aboutToAppear(): void {
    const today = this.formatDate(new Date());
    this.startDate = today; this.endDate = today; this.loadBuildings();
  }

  private async loadBuildings(): Promise<void> {
    this.isLoadingBuildings = true; this.errorMessage = ''; this.selectedBuildings = []; this.rooms = [];
    if (AhuCache.getMockData()) {
      const scenario = AhuCache.getMockScenario();
      if (scenario === 'network_error' || scenario === 'expired_login') {
        this.buildings = []; this.errorMessage = scenario === 'expired_login' ? 'Mock 场景：登录状态已过期' : 'Mock 场景：接口返回 500';
      } else if (scenario === 'empty_campus' || (scenario === 'longhe_only' && this.campusId !== 2)) {
        this.buildings = [];
      } else {
        const prefix = this.campusId === 2 ? '龙河' : '磬苑';
        this.buildings = [{ id: this.campusId * 100 + 1, nameZh: `${prefix}教学主楼` },
          { id: this.campusId * 100 + 2, nameZh: `${prefix}公共教学楼` }];
      }
      this.isLoadingBuildings = false; return;
    }
    const result = await this.client.getJson<Array<Building>>(
      `https://jw.ahu.edu.cn/student/ws/room/get-buildings?campusId=${this.campusId}&hasDataPermission=false`);
    if (result.isSuccess) this.buildings = (result.data ?? []).sort((a: Building, b: Building): number => a.nameZh.localeCompare(b.nameZh));
    else { this.buildings = []; this.errorMessage = result.error?.message ?? '教学楼加载失败'; }
    this.isLoadingBuildings = false;
  }

  private toggleBuilding(id: number): void {
    this.selectedBuildings = this.selectedBuildings.includes(id)
      ? this.selectedBuildings.filter((value: number): boolean => value !== id)
      : [...this.selectedBuildings, id];
  }
  private toggleUnit(unit: number): void {
    this.selectedUnits = this.selectedUnits.includes(unit)
      ? this.selectedUnits.filter((value: number): boolean => value !== unit)
      : [...this.selectedUnits, unit];
  }
  private toggleRange(start: number, end: number): void {
    const range = Array.from({ length: end - start + 1 }, (_: Object, index: number) => start + index);
    const selected = range.every((unit: number): boolean => this.selectedUnits.includes(unit));
    this.selectedUnits = selected
      ? this.selectedUnits.filter((unit: number): boolean => !range.includes(unit))
      : Array.from(new Set([...this.selectedUnits, ...range])).sort((a: number, b: number): number => a - b);
  }
  private formatDate(date: Date): string {
    return `${date.getFullYear()}-${`${date.getMonth() + 1}`.padStart(2, '0')}-${`${date.getDate()}`.padStart(2, '0')}`;
  }
  private quickDate(offset: number): void {
    const date = new Date(); date.setDate(date.getDate() + offset);
    this.startDate = this.formatDate(date); this.endDate = this.startDate;
  }
  private chooseDate(isStart: boolean): void {
    const today = new Date(); today.setHours(0, 0, 0, 0);
    const minimum = isStart ? today : new Date(`${this.startDate}T00:00:00`);
    const selected = new Date(`${isStart ? this.startDate : this.endDate}T00:00:00`);
    this.getUIContext().showDatePickerDialog({
      start: minimum, end: new Date(today.getFullYear() + 5, 11, 31), selected: selected,
      onDateAccept: (date: Date) => {
        const value = this.formatDate(date);
        if (isStart) {
          this.startDate = value;
          if (new Date(`${this.endDate}T00:00:00`).getTime() < date.getTime()) this.endDate = value;
        } else {
          this.endDate = value;
        }
      }
    });
  }

  private async search(): Promise<void> {
    const ids = this.selectedBuildings.length > 0 ? this.selectedBuildings : this.buildings.map((item: Building): number => item.id);
    if (ids.length === 0) { this.errorMessage = '当前校区暂无教学楼数据'; return; }
    const units = (this.selectedUnits.length > 0 ? this.selectedUnits : Array.from({ length: 13 }, (_: Object, i: number) => i + 1))
      .map((unit: number): string => `${unit}`);
    this.isSearching = true; this.errorMessage = ''; const rooms: Array<FreeRoom> = [];
    if (AhuCache.getMockData()) {
      const scenario = AhuCache.getMockScenario();
      if (scenario === 'network_error' || scenario === 'expired_login') {
        this.rooms = []; this.errorMessage = scenario === 'expired_login' ? 'Mock 场景：登录状态已过期' : 'Mock 场景：接口返回 500';
      } else {
        ids.forEach((buildingId: number) => {
          const building = this.buildings.find((item: Building) => item.id === buildingId);
          if (!building) return;
          rooms.push({ id: buildingId * 10 + 1, nameZh: '301', floor: 3, building: { id: building.id, nameZh: building.nameZh }, remark: '多媒体教室' });
          rooms.push({ id: buildingId * 10 + 2, nameZh: '302', floor: 3, building: { id: building.id, nameZh: building.nameZh } });
        });
        this.rooms = rooms;
      }
      this.filtersExpanded = false; this.isSearching = false; return;
    }
    for (let index = 0; index < ids.length; index++) {
      const request: FreeRoomRequest = { buildingId: `${ids[index]}`, campusId: `${this.campusId}`,
        dateTimeSegmentCmd: { startDateTime: this.startDate, endDateTime: this.endDate, startTime: '', endTime: '', units: units, weekdays: [] },
        hasDataPermission: false, roomId: '', seatsForLessonGte: '' };
      const body = JSON.stringify(request);
      const result = await this.client.postJson<FreeRoomResponse>('https://jw.ahu.edu.cn/student/ws/room-borrow/free-list', body);
      if (result.isSuccess) rooms.push(...(result.data?.roomList ?? []));
      else this.errorMessage = result.error?.message ?? '空闲教室查询失败';
    }
    const unique = new Map<string, FreeRoom>();
    rooms.forEach((room: FreeRoom) => unique.set(`${room.building.id}-${room.id}`, room));
    this.rooms = Array.from(unique.values()).sort((a: FreeRoom, b: FreeRoom): number =>
      a.building.nameZh.localeCompare(b.building.nameZh) || a.floor - b.floor || a.nameZh.localeCompare(b.nameZh));
    this.filtersExpanded = false; this.isSearching = false;
  }

  @Builder private chipRow(items: Array<number>) {
    Scroll() { Row({ space: 8 }) { ForEach(items, (unit: number) => { AhuChip({ text: `第 ${unit} 节`, selected: this.selectedUnits.includes(unit), clickAction: () => this.toggleUnit(unit) }); }, (unit: number) => `${unit}`); } }
      .scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off);
  }
  @Builder private filterContent() {
    Column({ space: 16 }) {
      AhuInsetCard() { Column({ space: 12 }) {
        Text('选择校区').fontSize(AhuTypography.body).fontWeight(FontWeight.Bold);
        Row({ space: 8 }) { AhuChip({ text: '磬苑校区', selected: this.campusId === 1, clickAction: () => { this.campusId = 1; this.loadBuildings(); } }); AhuChip({ text: '龙河校区', selected: this.campusId === 2, clickAction: () => { this.campusId = 2; this.loadBuildings(); } }); }
      }.alignItems(HorizontalAlign.Start); }
      AhuInsetCard() { Column({ space: 12 }) {
        Text('选择教学楼（不选即全部）').fontSize(AhuTypography.body).fontWeight(FontWeight.Bold);
        if (this.isLoadingBuildings) LoadingProgress().width(24).height(24).color(AhuColors.primaryAction);
        else Scroll() { Row({ space: 8 }) { ForEach(this.buildings, (item: Building) => { AhuChip({ text: item.nameZh, selected: this.selectedBuildings.includes(item.id), clickAction: () => this.toggleBuilding(item.id) }); }, (item: Building) => `${item.id}`); } }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off);
      }.alignItems(HorizontalAlign.Start); }
      AhuInsetCard() { Column({ space: 12 }) {
        Row({ space: 8 }) { Text('选择节次').fontSize(AhuTypography.body).fontWeight(FontWeight.Bold).layoutWeight(1); AhuChip({ text: '上午', selected: [1,2,3,4,5].every((v: number): boolean => this.selectedUnits.includes(v)), clickAction: () => this.toggleRange(1,5) }); AhuChip({ text: '下午', selected: [6,7,8,9,10].every((v: number): boolean => this.selectedUnits.includes(v)), clickAction: () => this.toggleRange(6,10) }); AhuChip({ text: '晚上', selected: [11,12,13].every((v: number): boolean => this.selectedUnits.includes(v)), clickAction: () => this.toggleRange(11,13) }); }
        this.chipRow(Array.from({ length: 13 }, (_: Object, i: number) => i + 1));
      }.alignItems(HorizontalAlign.Start); }
      AhuInsetCard() { Column({ space: 12 }) {
        Row({ space: 8 }) { Text('查询日期').fontSize(AhuTypography.body).fontWeight(FontWeight.Bold).layoutWeight(1);
          AhuChip({ text: '今天', selected: this.startDate === this.formatDate(new Date()) && this.endDate === this.startDate, clickAction: () => this.quickDate(0) });
          AhuChip({ text: '明天', selected: this.startDate === this.formatDate(new Date(Date.now() + 86_400_000)) && this.endDate === this.startDate, clickAction: () => this.quickDate(1) }); }
        Scroll() { Row({ space: 8 }) {
          AhuChip({ text: `开始 ${this.startDate}`, selected: true, clickAction: () => this.chooseDate(true) });
          AhuChip({ text: `结束 ${this.endDate}`, selected: true, clickAction: () => this.chooseDate(false) });
        } }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off);
        Text('可选择今天起五年内的日期范围').fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary);
      }.alignItems(HorizontalAlign.Start); }
    }
  }
  build() {
    Column({ space: 14 }) {
      Row({ space: 12 }) { Button('‹', { type: ButtonType.Circle }).width(40).height(40).fontSize(28).backgroundColor(AhuColors.card).onClick(() => this.onBack()); Text('空闲教室').fontSize(28).fontWeight(FontWeight.Bold).layoutWeight(1); }
        .padding({ left: 16, right: 16, top: 24 });
      Scroll() { Column({ space: 14 }) {
        if (this.filtersExpanded) this.filterContent();
        Row({ space: 8 }) { Button(this.isSearching ? '查询中' : '开始查询', { type: ButtonType.Capsule }).enabled(!this.isSearching && !this.isLoadingBuildings).layoutWeight(1).backgroundColor(AhuColors.primaryAction).onClick(() => this.search()); Button(this.filtersExpanded ? '收起' : '筛选', { type: ButtonType.Capsule }).backgroundColor(AhuColors.cardStrong).fontColor(AhuColors.onSurface).onClick(() => { this.filtersExpanded = !this.filtersExpanded; }); }.padding({ left: 16, right: 16 });
        if (this.isSearching) AhuLoading({ message: '正在查询空闲教室' });
        else AhuInsetCard() { Column({ space: 10 }) { Row() { Text('查询结果').fontWeight(FontWeight.Bold).layoutWeight(1); Text(`${this.rooms.length} 间`).fontColor(AhuColors.onSurfaceSecondary); }
          if (this.rooms.length === 0) Text(this.errorMessage.length > 0 ? this.errorMessage : '设置筛选条件后开始查询').fontColor(this.errorMessage.length > 0 ? AhuColors.error : AhuColors.onSurfaceSecondary);
          else ForEach(this.rooms, (room: FreeRoom) => { Column({ space: 4 }) { Text(room.nameZh).fontWeight(FontWeight.Bold); Text(`${room.building.nameZh} · ${room.floor} 层${room.remark ? ` · ${room.remark}` : ''}`).fontColor(AhuColors.onSurfaceSecondary); }.width('100%').padding(14).alignItems(HorizontalAlign.Start).backgroundColor(AhuColors.cardStrong).borderRadius(20); }, (room: FreeRoom) => `${room.building.id}-${room.id}`);
        }.width('100%'); }
      }.padding({ bottom: 24 }); }.layoutWeight(1).scrollBar(BarState.Off);
    }.width('100%').height('100%').backgroundColor(AhuColors.pageBackground);
  }
}
