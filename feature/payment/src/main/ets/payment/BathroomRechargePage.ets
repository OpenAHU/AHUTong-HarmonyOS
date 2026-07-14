import { AhuColors, AhuInsetCard, AhuScreen, AhuTypography } from 'core_designsystem';
import { BathroomAccount, CardPaymentRepository, CardPaymentRepositoryProvider } from 'data_payment';
import { AhuCache } from 'core_datastore';
import { BackPressDispatcher } from 'core_common';

@Component
export struct BathroomRechargePage {
  private readonly repository: CardPaymentRepository = CardPaymentRepositoryProvider.get();
  @State bathroom: string = '竹园/龙河';
  @State phone: string = '';
  @State amount: string = '';
  @State password: string = '';
  @State account?: BathroomAccount = undefined;
  @State loading: boolean = false;
  @State paying: boolean = false;
  @State error: string = '';
  @State result: string = '';
  @State showConfirm: boolean = false;
  @State lastPhone?: string = undefined;
  onBack: () => void = () => {};

  aboutToAppear(): void {
    BackPressDispatcher.register('bathroom_recharge_page', () => this.handleBackPress());
    this.lastPhone = AhuCache.getBathroomLastPhone();
  }
  aboutToDisappear(): void { BackPressDispatcher.unregister('bathroom_recharge_page'); }

  private handleBackPress(): boolean {
    if (this.showConfirm && !this.paying) { this.showConfirm = false; return true; }
    if (this.paying) return true;
    this.onBack();
    return true;
  }

  private validAmount(value: string): boolean { return /^\d*\.?\d{0,2}$/.test(value); }

  private async query(): Promise<void> {
    if (this.phone.trim().length === 0 || this.loading) return;
    this.loading = true; this.error = ''; this.result = ''; this.account = undefined;
    const response = await this.repository.getBathroomAccount(this.bathroom, this.phone.trim());
    if (response.isSuccess && response.data) this.account = response.data;
    else this.error = response.error?.message ?? '浴室账户查询失败';
    this.loading = false;
  }

  private async pay(): Promise<void> {
    if (!this.account || this.paying || this.password.length !== 6) return;
    this.paying = true; this.error = ''; this.result = '';
    const response = await this.repository.chargeBathroom(this.bathroom, this.amount, this.password, this.account);
    if (response.isSuccess) {
      this.result = `充值成功，订单号：${response.data ?? '--'}`;
      AhuCache.saveBathroomLastPhone(this.phone.trim()); this.lastPhone = this.phone.trim();
      await this.query();
    } else this.error = response.error?.message ?? '浴室充值失败';
    this.password = ''; this.showConfirm = false; this.paying = false;
  }

  @Builder
  private confirmPanel() {
    Column({ space: 16 }) {
      Text('输入校园卡密码').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold);
      Text(`为 ${this.phone} 充值 ¥ ${this.amount}`)
        .fontSize(AhuTypography.body).fontColor(AhuColors.onSurfaceSecondary);
      TextInput({ text: this.password, placeholder: '6 位数字密码' })
        .type(InputType.NUMBER_PASSWORD).maxLength(6).onChange((value: string) => {
          if (/^\d{0,6}$/.test(value)) this.password = value;
        });
      Button(this.paying ? '正在支付…' : '确认支付', { type: ButtonType.Capsule })
        .width('100%').enabled(!this.paying && this.password.length === 6)
        .fontColor(AhuColors.onPrimaryAction).backgroundColor(AhuColors.primaryAction).onClick(() => this.pay());
      Button('取消', { type: ButtonType.Capsule }).width('100%').enabled(!this.paying)
        .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.chipUnselected).onClick(() => this.showConfirm = false);
    }.width('88%').padding(24).backgroundColor(AhuColors.card).borderRadius(28);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      AhuScreen({ scrollable: true }) {
        Row({ space: 12 }) {
          Button('‹', { type: ButtonType.Circle }).width(40).height(40).fontSize(28)
            .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.card).onClick(() => this.onBack());
          Text('浴室缴费').fontSize(28).fontWeight(FontWeight.Bold).layoutWeight(1);
        }.width('100%').padding({ left: 16, right: 16, top: 20 });
        AhuInsetCard() {
          Column({ space: 14 }) {
            Text('浴室账户').fontSize(AhuTypography.body).fontWeight(FontWeight.Bold);
            Select([{ value: '竹园/龙河' }, { value: '桔园/蕙园' }])
              .selected(this.bathroom === '竹园/龙河' ? 0 : 1).value(this.bathroom)
              .onSelect((_: number, value: string) => { this.bathroom = value; this.account = undefined; });
            Row({ space: 10 }) {
              TextInput({ text: this.phone, placeholder: '请输入手机号' }).layoutWeight(1)
                .type(InputType.PhoneNumber).onChange((value: string) => this.phone = value);
              Button(this.loading ? '查询中' : '查询', { type: ButtonType.Capsule })
                .enabled(!this.loading && this.phone.trim().length > 0).backgroundColor(AhuColors.primaryAction)
                .onClick(() => this.query());
            }.width('100%');
            if (this.lastPhone) {
              Button(`上次充值：${this.lastPhone}`, { type: ButtonType.Capsule })
                .alignSelf(ItemAlign.End).height(34).fontSize(AhuTypography.label)
                .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.chipSelected)
                .onClick(() => {
                  this.phone = this.lastPhone ?? ''; this.lastPhone = undefined; this.query();
                });
            }
            if (this.loading) LoadingProgress().width(28).height(28).color(AhuColors.primaryAction);
            if (this.account) {
              Text(`手机号：${this.account.phone}`).fontSize(AhuTypography.body);
              Text(`现金余额：¥ ${this.account.cashAmount || (this.account.data.accountMoney / 100).toFixed(2)}`)
                .fontSize(AhuTypography.body);
              Text(`赠送余额：¥ ${this.account.giftAmount || (this.account.data.accountGivenMoney / 100).toFixed(2)}`)
                .fontSize(AhuTypography.body);
            }
          }.width('100%').alignItems(HorizontalAlign.Start);
        }
        AhuInsetCard() {
          Column({ space: 12 }) {
            Text('缴费金额').fontSize(AhuTypography.body).fontWeight(FontWeight.Bold);
            TextInput({ text: this.amount, placeholder: '请输入金额' }).type(InputType.NUMBER_DECIMAL)
              .onChange((value: string) => { if (this.validAmount(value)) this.amount = value; });
          }.width('100%').alignItems(HorizontalAlign.Start);
        }
        if (this.error.length > 0) Text(this.error).fontColor(AhuColors.error).padding({ left: 24, right: 24 });
        if (this.result.length > 0) Text(this.result).fontColor(AhuColors.primaryAction).padding({ left: 24, right: 24 });
        Button('确认', { type: ButtonType.Capsule }).alignSelf(ItemAlign.End).margin({ right: 16 })
          .enabled(this.account !== undefined && Number(this.amount) > 0 && !this.paying)
          .fontColor(AhuColors.onPrimaryAction).backgroundColor(AhuColors.primaryAction)
          .onClick(() => this.showConfirm = true);
      }
      if (this.showConfirm) {
        Column() { this.confirmPanel(); }.width('100%').height('100%')
          .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center).backgroundColor('#66000000');
      }
    }.width('100%').height('100%');
  }
}
