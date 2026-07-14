import { AhuColors, AhuInsetCard, AhuScreen, AhuTypography } from 'core_designsystem';
import {
  CardPaymentRepository, CardPaymentRepositoryProvider, ElectricityOption, ElectricityRoomInfo
} from 'data_payment';
import { AhuCache } from 'core_datastore';
import { BackPressDispatcher } from 'core_common';

interface ElectricitySelection {
  campus: ElectricityOption; building: ElectricityOption; floor: ElectricityOption; room: ElectricityOption;
}
interface ElectricityHistory { selection: ElectricitySelection; label: string; updatedAt: number; }

@Component
export struct ElectricityRechargePage {
  private readonly repository: CardPaymentRepository = CardPaymentRepositoryProvider.get();
  @State campuses: Array<ElectricityOption> = [];
  @State buildings: Array<ElectricityOption> = [];
  @State floors: Array<ElectricityOption> = [];
  @State rooms: Array<ElectricityOption> = [];
  @State campus?: ElectricityOption = undefined;
  @State building?: ElectricityOption = undefined;
  @State floor?: ElectricityOption = undefined;
  @State room?: ElectricityOption = undefined;
  @State roomInfo?: ElectricityRoomInfo = undefined;
  @State amount: string = '';
  @State password: string = '';
  @State loading: boolean = false;
  @State paying: boolean = false;
  @State error: string = '';
  @State result: string = '';
  @State showConfirm: boolean = false;
  @State history: Array<ElectricityHistory> = [];
  @State showHistoryOptions: boolean = false;
  @State infoClickCount: number = 0;
  @State infoMessage: string = '';
  @State showResetRecord: boolean = false;
  onBack: () => void = () => {};

  aboutToAppear(): void {
    BackPressDispatcher.register('electricity_recharge_page', () => this.handleBackPress());
    this.history = this.readHistory();
    this.showHistoryOptions = this.history.length === 2;
    if (this.history.length === 1) this.restore(this.history[0]); else this.loadCampuses();
  }
  aboutToDisappear(): void { BackPressDispatcher.unregister('electricity_recharge_page'); }

  private handleBackPress(): boolean {
    if (this.showResetRecord) { this.showResetRecord = false; return true; }
    if (this.showConfirm && !this.paying) { this.showConfirm = false; return true; }
    if (this.paying) return true;
    this.onBack();
    return true;
  }
  private validAmount(value: string): boolean { return /^\d*\.?\d{0,2}$/.test(value); }

  private currentDateLabel(): string {
    const now = AhuCache.now();
    return `${now.getFullYear()}年${`${now.getMonth() + 1}`.padStart(2, '0')}月${`${now.getDate()}`.padStart(2, '0')}日`;
  }

  private revealChargeInfo(): void {
    this.infoClickCount++;
    if (this.infoClickCount === 1) this.infoMessage = '点击五次查看累计充值记录，长按清空记录';
    else if (this.infoClickCount === 2) this.infoMessage = '再点击三次即可查看累计充值记录';
    else if (this.infoClickCount === 3) this.infoMessage = '再点击两次即可查看累计充值记录';
    else if (this.infoClickCount === 4) this.infoMessage = '再点击一次即可查看累计充值记录';
    else {
      const info = AhuCache.getElectricityChargeInfo();
      this.infoMessage = info ? `从${info.firstChargeDate}起累计电费充值金额为：${info.totalAmount.toFixed(2)}元` :
        '暂无充值记录';
    }
  }

  private readHistory(): Array<ElectricityHistory> {
    const raw = AhuCache.getElectricityRoomHistory();
    if (raw.length === 0) return [];
    try { return (JSON.parse(raw) as Array<ElectricityHistory>).slice(0, 2); } catch (_) { return []; }
  }

  private saveCurrentHistory(): void {
    if (!this.campus || !this.building || !this.floor || !this.room) return;
    const selection: ElectricitySelection = { campus: this.campus, building: this.building, floor: this.floor, room: this.room };
    const current: ElectricityHistory = { selection: selection,
      label: (this.roomInfo?.data.roomName ?? this.room.name).replace(/^房间\s*/, '').trim(), updatedAt: Date.now() };
    const key = `${this.campus.value}/${this.building.value}/${this.floor.value}/${this.room.value}`;
    this.history = [current, ...this.history.filter((item: ElectricityHistory) => {
      const saved = item.selection; return `${saved.campus.value}/${saved.building.value}/${saved.floor.value}/${saved.room.value}` !== key;
    })].slice(0, 2);
    AhuCache.saveElectricityRoomHistory(JSON.stringify(this.history));
  }

  private async restore(item: ElectricityHistory): Promise<void> {
    this.error = ''; this.loading = true;
    try {
      this.campuses = (await this.repository.getElectricityOptions(0)).data ?? [];
      await this.selectCampus(item.selection.campus);
      await this.selectBuilding(item.selection.building);
      await this.selectFloor(item.selection.floor);
      await this.selectRoom(item.selection.room);
    } catch (error) { this.error = (error as Error).message ?? '历史房间恢复失败'; }
    finally { this.loading = false; }
  }

  private selectHistory(item: ElectricityHistory): void {
    this.showHistoryOptions = false;
    this.restore(item);
  }

  private async loadCampuses(): Promise<void> {
    this.loading = true; this.error = '';
    const response = await this.repository.getElectricityOptions(0);
    if (response.isSuccess && response.data) this.campuses = response.data;
    else this.error = response.error?.message ?? '加载校区失败';
    this.loading = false;
  }

  private async selectCampus(item: ElectricityOption): Promise<void> {
    this.campus = item; this.building = undefined; this.floor = undefined; this.room = undefined; this.roomInfo = undefined;
    this.buildings = []; this.floors = []; this.rooms = []; this.loading = true; this.error = '';
    const response = await this.repository.getElectricityOptions(1, item.value);
    if (response.isSuccess && response.data) this.buildings = response.data;
    else this.error = response.error?.message ?? '加载楼栋失败';
    this.loading = false;
  }

  private async selectBuilding(item: ElectricityOption): Promise<void> {
    if (!this.campus) return;
    this.building = item; this.floor = undefined; this.room = undefined; this.roomInfo = undefined;
    this.floors = []; this.rooms = []; this.loading = true; this.error = '';
    const response = await this.repository.getElectricityOptions(2, this.campus.value, item.value);
    if (response.isSuccess && response.data) this.floors = response.data;
    else this.error = response.error?.message ?? '加载楼层失败';
    this.loading = false;
  }

  private async selectFloor(item: ElectricityOption): Promise<void> {
    if (!this.campus || !this.building) return;
    this.floor = item; this.room = undefined; this.roomInfo = undefined; this.rooms = []; this.loading = true; this.error = '';
    const response = await this.repository.getElectricityOptions(3, this.campus.value, this.building.value, item.value);
    if (response.isSuccess && response.data) this.rooms = response.data;
    else this.error = response.error?.message ?? '加载房间失败';
    this.loading = false;
  }

  private async selectRoom(item: ElectricityOption): Promise<void> {
    if (!this.campus || !this.building || !this.floor) return;
    this.room = item; this.roomInfo = undefined; this.loading = true; this.error = '';
    const response = await this.repository.getElectricityRoom(
      this.campus.value, this.building.value, this.floor.value, item.value);
    if (response.isSuccess && response.data) this.roomInfo = response.data;
    else this.error = response.error?.message ?? '加载电量信息失败';
    this.loading = false;
  }

  private async pay(): Promise<void> {
    if (!this.roomInfo || this.password.length !== 6 || this.paying) return;
    this.paying = true; this.error = ''; this.result = '';
    const response = await this.repository.chargeElectricity(this.amount, this.password, this.roomInfo);
    if (response.isSuccess) {
      this.result = `充值成功，订单号：${response.data ?? '--'}`;
      const paid = Number(this.amount);
      const saved = AhuCache.getElectricityChargeInfo();
      AhuCache.saveElectricityChargeInfo({ totalAmount: (saved?.totalAmount ?? 0) + paid,
        firstChargeDate: saved?.firstChargeDate ?? this.currentDateLabel() });
      this.saveCurrentHistory();
      if (this.room) await this.selectRoom(this.room);
    } else this.error = response.error?.message ?? '电费充值失败';
    this.password = ''; this.showConfirm = false; this.paying = false;
  }

  @Builder
  private optionGroup(title: string, items: Array<ElectricityOption>, selected?: ElectricityOption,
    action: (item: ElectricityOption) => void = (_: ElectricityOption) => {}) {
    if (items.length > 0) {
      Column({ space: 8 }) {
        Text(title).fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary);
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(items, (item: ElectricityOption) => {
            Button(item.name, { type: ButtonType.Capsule }).margin({ right: 8, bottom: 8 })
              .fontColor(selected?.value === item.value ? AhuColors.onPrimaryAction : AhuColors.onSurface)
              .backgroundColor(selected?.value === item.value ? AhuColors.primaryAction : AhuColors.chipUnselected)
              .onClick(() => action(item));
          }, (item: ElectricityOption) => item.value);
        }.width('100%');
      }.width('100%').alignItems(HorizontalAlign.Start);
    }
  }

  @Builder
  private confirmPanel() {
    Column({ space: 16 }) {
      Text('输入校园卡密码').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold);
      Text(`为 ${this.room?.name ?? '当前房间'} 充值 ¥ ${this.amount}`)
        .fontSize(AhuTypography.body).fontColor(AhuColors.onSurfaceSecondary);
      TextInput({ text: this.password, placeholder: '6 位数字密码' }).type(InputType.NUMBER_PASSWORD).maxLength(6)
        .onChange((value: string) => { if (/^\d{0,6}$/.test(value)) this.password = value; });
      Button(this.paying ? '正在支付…' : '确认支付', { type: ButtonType.Capsule }).width('100%')
        .enabled(!this.paying && this.password.length === 6).fontColor(AhuColors.onPrimaryAction)
        .backgroundColor(AhuColors.primaryAction).onClick(() => this.pay());
      Button('取消', { type: ButtonType.Capsule }).width('100%').enabled(!this.paying)
        .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.chipUnselected).onClick(() => this.showConfirm = false);
    }.width('88%').padding(24).backgroundColor(AhuColors.card).borderRadius(28);
  }

  @Builder
  private resetRecordPanel() {
    Column({ space: 16 }) {
      Text('确认操作').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold).width('100%');
      Text('您确定要将累计充值金额清零吗？此操作不可撤销。').fontSize(AhuTypography.body)
        .fontColor(AhuColors.onSurfaceSecondary).width('100%');
      Row({ space: 12 }) {
        Button('取消', { type: ButtonType.Capsule }).layoutWeight(1)
          .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.card)
          .onClick(() => { this.showResetRecord = false; });
        Button('确认', { type: ButtonType.Capsule }).layoutWeight(1).backgroundColor(AhuColors.error)
          .onClick(() => {
            AhuCache.clearElectricityChargeInfo(); this.infoMessage = '累计记录已清零';
            this.infoClickCount = 0; this.showResetRecord = false;
          });
      }.width('100%');
    }.width('88%').padding(24).backgroundColor(AhuColors.card).borderRadius(28);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      AhuScreen({ scrollable: true }) {
        Row({ space: 12 }) {
          Button('‹', { type: ButtonType.Circle }).width(40).height(40).fontSize(28)
            .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.card).onClick(() => this.onBack());
          Text('电费充值').fontSize(28).fontWeight(FontWeight.Bold).layoutWeight(1);
        }.width('100%').padding({ left: 16, right: 16, top: 20 });
        AhuInsetCard() {
          Column({ space: 12 }) {
            Text('选择宿舍').fontSize(AhuTypography.body).fontWeight(FontWeight.Bold);
            if (this.showHistoryOptions && this.history.length === 2) {
              Column({ space: 7 }) {
                Text('最近房间').fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary);
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(this.history, (item: ElectricityHistory) => {
                    Button(item.label, { type: ButtonType.Capsule }).margin({ right: 8, bottom: 6 })
                      .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.chipUnselected)
                      .onClick(() => this.selectHistory(item));
                  }, (item: ElectricityHistory) => `${item.updatedAt}`);
                }.width('100%');
              }.width('100%').alignItems(HorizontalAlign.Start);
            }
            this.optionGroup('校区', this.campuses, this.campus, (item: ElectricityOption) => this.selectCampus(item));
            this.optionGroup('楼栋', this.buildings, this.building, (item: ElectricityOption) => this.selectBuilding(item));
            this.optionGroup('楼层', this.floors, this.floor, (item: ElectricityOption) => this.selectFloor(item));
            this.optionGroup('房间', this.rooms, this.room, (item: ElectricityOption) => this.selectRoom(item));
            if (this.loading) LoadingProgress().width(28).height(28).color(AhuColors.primaryAction);
            if (this.roomInfo) {
              Row({ space: 12 }) {
                Text('信息').fontSize(AhuTypography.body).fontWeight(FontWeight.Medium);
                Text(this.roomInfo.info.length > 0 ? this.roomInfo.info : '已获取当前房间信息')
                  .fontSize(AhuTypography.body).fontColor(AhuColors.onSurface).layoutWeight(1);
              }.width('100%').onClick(() => this.revealChargeInfo())
                .gesture(LongPressGesture({ repeat: false, duration: 500 })
                  .onAction(() => { this.showResetRecord = true; }));
              if (this.infoMessage.length > 0) {
                Text(this.infoMessage).fontSize(AhuTypography.label).fontColor(AhuColors.primaryAction).width('100%');
              }
            }
          }.width('100%').alignItems(HorizontalAlign.Start);
        }
        AhuInsetCard() {
          Column({ space: 12 }) {
            Text('充值金额').fontSize(AhuTypography.body).fontWeight(FontWeight.Bold);
            TextInput({ text: this.amount, placeholder: '请输入金额' }).type(InputType.NUMBER_DECIMAL)
              .onChange((value: string) => { if (this.validAmount(value)) this.amount = value; });
          }.width('100%').alignItems(HorizontalAlign.Start);
        }
        if (this.error.length > 0) Text(this.error).fontColor(AhuColors.error).padding({ left: 24, right: 24 });
        if (this.result.length > 0) Text(this.result).fontColor(AhuColors.primaryAction).padding({ left: 24, right: 24 });
        Button('确认', { type: ButtonType.Capsule }).alignSelf(ItemAlign.End).margin({ right: 16 })
          .enabled(this.roomInfo !== undefined && Number(this.amount) > 0 && !this.paying)
          .fontColor(AhuColors.onPrimaryAction).backgroundColor(AhuColors.primaryAction).onClick(() => this.showConfirm = true);
      }
      if (this.showConfirm) {
        Column() { this.confirmPanel(); }.width('100%').height('100%')
          .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center).backgroundColor('#66000000');
      }
      if (this.showResetRecord) {
        Column() { this.resetRecordPanel(); }.width('100%').height('100%')
          .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center).backgroundColor('#66000000');
      }
    }.width('100%').height('100%');
  }
}
