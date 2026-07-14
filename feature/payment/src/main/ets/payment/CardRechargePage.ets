import { AhuColors, AhuInsetCard, AhuScreen, AhuTypography } from 'core_designsystem';
import { AhuCache } from 'core_datastore';
import { common, Want } from '@kit.AbilityKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { CardAccount, CardPaymentRepository, CardPaymentRepositoryProvider } from 'data_payment';
import { BackPressDispatcher } from 'core_common';

const ALIPAY_SCHEME: string =
  'alipays://platformapi/startapp?appId=2019090967125695&page=pages%2Findex%2Findex&chInfo=ch_share__chsub_CopyLink';
const ALIPAY_FALLBACK_URL: string = 'https://www.wmslz.com/s/M6KARh485j3';

@Component
export struct CardRechargePage {
  private readonly paymentRepository: CardPaymentRepository = CardPaymentRepositoryProvider.get();
  @State amount: string = '';
  @State showConfirm: boolean = false;
  @State opening: boolean = false;
  @State account?: CardAccount = undefined;
  @State accountLoading: boolean = true;
  @State accountError: string = '';
  @State paymentMessage: string = '';
  @State paymentSuccess: boolean = false;
  onBack: () => void = () => {};

  aboutToAppear(): void {
    BackPressDispatcher.register('card_recharge_page', () => this.handleBackPress());
    this.loadAccount();
  }
  aboutToDisappear(): void { BackPressDispatcher.unregister('card_recharge_page'); }

  private handleBackPress(): boolean {
    if (this.showConfirm && !this.opening) { this.showConfirm = false; return true; }
    if (this.opening) return true;
    this.onBack();
    return true;
  }

  private async loadAccount(): Promise<void> {
    this.accountLoading = true;
    this.accountError = '';
    const result = await this.paymentRepository.getAccount();
    if (result.isSuccess && result.data) this.account = result.data;
    else this.accountError = result.error?.message ?? '校园卡账户加载失败';
    this.accountLoading = false;
  }

  private validAmount(value: string): boolean {
    return /^\d*\.?\d{0,2}$/.test(value);
  }

  private toast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (_) {
    }
  }

  private async copyIdentity(): Promise<void> {
    const user = AhuCache.getCurrentUser();
    const text = `姓名：${user?.name ?? '未获取'}\n学号：${user?.xh ?? '未获取'}`;
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    try {
      await pasteboard.getSystemPasteboard().setData(data);
      this.toast('姓名和学号已复制');
    } catch (_) {
      this.toast('复制身份信息失败');
    }
  }

  private async startUri(uri: string): Promise<boolean> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const want: Want = { uri: uri };
    try {
      await context.startAbility(want);
      return true;
    } catch (_) {
      return false;
    }
  }

  private async openAlipay(): Promise<void> {
    if (this.opening) return;
    this.opening = true;
    await this.copyIdentity();
    const opened = await this.startUri(ALIPAY_SCHEME) || await this.startUri(ALIPAY_FALLBACK_URL);
    if (!opened) this.toast('无法打开支付宝校园卡');
    this.showConfirm = false;
    this.opening = false;
  }

  private async payByBankCard(): Promise<void> {
    if (this.opening || !this.account) return;
    this.opening = true;
    this.paymentMessage = '';
    const result = await this.paymentRepository.charge(this.amount, this.account.type);
    if (result.isSuccess) {
      this.paymentSuccess = true;
      this.paymentMessage = `充值成功，订单号：${result.data ?? '--'}`;
      await this.loadAccount();
    } else {
      this.paymentSuccess = false;
      this.paymentMessage = result.error?.message ?? '充值失败';
    }
    this.showConfirm = false;
    this.opening = false;
  }

  @Builder
  private confirmPanel() {
    Column({ space: 18 }) {
      Text('确认充值').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold);
      Text(`将打开支付宝校园卡页面，请在支付宝中再次核对金额 ¥ ${this.amount}`)
        .fontSize(AhuTypography.body).fontColor(AhuColors.onSurfaceSecondary).lineHeight(24);
      Text(`姓名：${AhuCache.getCurrentUser()?.name ?? '未获取'}  学号：${AhuCache.getCurrentUser()?.xh ?? '未获取'}`)
        .fontSize(AhuTypography.body).fontColor(AhuColors.onSurface);
      Button(this.opening ? '正在打开…' : '支付宝充值', { type: ButtonType.Capsule })
        .width('100%').enabled(!this.opening).fontColor(AhuColors.onPrimaryAction)
        .backgroundColor(AhuColors.primaryAction).onClick(() => this.openAlipay());
      Button(this.opening ? '正在支付…' : '银行卡充值', { type: ButtonType.Capsule })
        .width('100%').enabled(!this.opening && this.account !== undefined)
        .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.cardStrong)
        .onClick(() => this.payByBankCard());
      Button('取消', { type: ButtonType.Capsule }).width('100%')
        .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.chipUnselected)
        .onClick(() => this.showConfirm = false);
    }
    .width('88%').padding(24).backgroundColor(AhuColors.card).borderRadius(28);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      AhuScreen({ scrollable: true }) {
        Row({ space: 12 }) {
          Button('‹', { type: ButtonType.Circle }).width(40).height(40).fontSize(28)
            .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.card).onClick(() => this.onBack());
          Text('校园卡充值').fontSize(28).fontWeight(FontWeight.Bold).layoutWeight(1);
        }.width('100%').padding({ left: 16, right: 16, top: 20 });
        AhuInsetCard() {
          Column({ space: 14 }) {
            Text('校园卡账户').fontSize(AhuTypography.body).fontWeight(FontWeight.Bold);
            if (this.accountLoading) {
              LoadingProgress().width(28).height(28).color(AhuColors.primaryAction);
            } else if (this.account) {
              Text(`${this.account.name}  ${this.account.type}`)
                .fontSize(AhuTypography.body).fontColor(AhuColors.onSurfaceSecondary);
              Text(`账户余额  ¥ ${this.account.balance.toFixed(2)}`)
                .fontSize(AhuTypography.body).fontWeight(FontWeight.Bold);
            } else {
              Text(this.accountError).fontSize(AhuTypography.body).fontColor(AhuColors.error)
                .onClick(() => this.loadAccount());
            }
          }.width('100%').alignItems(HorizontalAlign.Start);
        }
        if (this.paymentMessage.length > 0) {
          AhuInsetCard() {
            Text(this.paymentMessage).fontSize(AhuTypography.body).fontWeight(FontWeight.Bold)
              .fontColor(this.paymentSuccess ? AhuColors.primaryAction : AhuColors.error)
              .onClick(() => this.paymentMessage = '');
          }
        }
        AhuInsetCard() {
          Column({ space: 12 }) {
            Text('充值金额').fontSize(AhuTypography.body).fontWeight(FontWeight.Bold);
            TextInput({ text: this.amount, placeholder: '请输入金额' })
              .type(InputType.NUMBER_DECIMAL).fontSize(AhuTypography.body)
              .backgroundColor(Color.Transparent)
              .onChange((value: string) => { if (this.validAmount(value)) this.amount = value; });
          }.width('100%').alignItems(HorizontalAlign.Start);
        }
        Button('确认', { type: ButtonType.Capsule }).alignSelf(ItemAlign.End).margin({ right: 16 })
          .fontColor(AhuColors.onPrimaryAction).backgroundColor(AhuColors.primaryAction)
          .enabled(this.amount.length > 0 && Number(this.amount) > 0)
          .onClick(() => this.showConfirm = true);
        Text('支付宝充值会复制当前姓名和学号，并跳转到支付宝校园卡页面完成支付。')
          .fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary)
          .padding({ left: 24, right: 24 }).lineHeight(20);
      }
      if (this.showConfirm) {
        Column() { this.confirmPanel(); }
          .width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
          .backgroundColor('#66000000').onClick(() => this.showConfirm = false);
      }
    }.width('100%').height('100%');
  }
}
