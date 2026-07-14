import { AppResult } from 'core_common';
import { AhuColors, AhuDimens, AhuPageHeader, AhuTypography } from 'core_designsystem';
import { User } from 'core_model';
import { AuthRepositoryProvider } from 'data_auth';
import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export enum LoginState {
  IDLE = 'idle',
  IN_PROGRESS = 'in_progress',
  FAILED = 'failed',
  SUCCEEDED = 'succeeded'
}

@Component
export struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State focusIndex: number = 0;
  @State state: LoginState = LoginState.IDLE;
  @State statusMessage: string = '';
  onLoggedIn: () => void = () => {};

  aboutToAppear(): void {
    this.setPrivacyMode(true);
  }

  aboutToDisappear(): void {
    this.setPrivacyMode(false);
  }

  private async setPrivacyMode(enabled: boolean): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const appWindow = await window.getLastWindow(context);
      await appWindow.setWindowPrivacyMode(enabled);
    } catch (_) {}
  }

  private async submit(): Promise<void> {
    if (this.state === LoginState.IN_PROGRESS) {
      return;
    }
    if (this.username.trim().length === 0 || this.password.length === 0) {
      this.showFailure('请将信息填写完整');
      return;
    }

    this.state = LoginState.IN_PROGRESS;
    this.statusMessage = '';
    try {
      const result: AppResult<User> = await AuthRepositoryProvider.get().login(this.username, this.password);
      if (result.isSuccess && result.data) {
        this.state = LoginState.SUCCEEDED;
        this.statusMessage = `欢迎，${result.data.name}！`;
        setTimeout(() => this.onLoggedIn(), 500);
      } else {
        this.showFailure(result.error?.message ?? '登录失败');
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : '登录失败';
      this.showFailure(message);
    }
  }

  private showFailure(message: string): void {
    this.state = LoginState.FAILED;
    this.statusMessage = message;
    setTimeout(() => {
      if (this.state === LoginState.FAILED) {
        this.state = LoginState.IDLE;
      }
    }, 1200);
  }

  @Builder
  private loginStatus() {
    if (this.state === LoginState.IDLE) {
      Button($r('app.string.login_action'), { type: ButtonType.Capsule })
        .fontSize(AhuTypography.body)
        .fontColor(AhuColors.onPrimaryAction)
        .backgroundColor(AhuColors.primaryAction)
        .padding({ left: 24, right: 24, top: 14, bottom: 14 })
        .onClick(() => this.submit());
    } else {
      Row({ space: 14 }) {
        if (this.state === LoginState.IN_PROGRESS) {
          LoadingProgress()
            .width(28)
            .height(28)
            .color(AhuColors.onPrimaryAction);
        } else {
          SymbolGlyph(this.state === LoginState.SUCCEEDED ? $r('sys.symbol.checkmark') : $r('sys.symbol.xmark'))
            .fontSize(28)
            .fontColor([AhuColors.onPrimaryAction]);
        }
        Text(this.state === LoginState.IN_PROGRESS ? $r('app.string.login_logging_in') : this.statusMessage)
          .fontSize(AhuTypography.body)
          .fontWeight(FontWeight.Bold)
          .fontColor(AhuColors.onPrimaryAction)
          .maxLines(2);
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16, bottom: 16 })
      .backgroundColor(this.state === LoginState.FAILED ? AhuColors.error : AhuColors.primaryAction)
      .borderRadius(AhuDimens.cardCornerMedium);
    }
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Scroll() {
        Column({ space: AhuDimens.contentHorizontal }) {
          AhuPageHeader({ title: $r('app.string.login_title') });

          Stack({ alignContent: Alignment.Center }) {
            Image(this.focusIndex === 0 ? $r('app.media.emoji_username') : $r('app.media.emoji_password'))
              .height(128)
              .objectFit(ImageFit.Contain);
            if (this.focusIndex === 1) {
              Row() {
                Image($r('app.media.emoji_left_hand'))
                  .width(72)
                  .objectFit(ImageFit.Contain);
                Blank();
                Image($r('app.media.emoji_right_hand'))
                  .width(72)
                  .objectFit(ImageFit.Contain);
              }
              .width(220)
              .translate({ y: 62 });
            }
          }
          .width('100%')
          .height(150);

          TextInput({ placeholder: $r('app.string.login_username_hint'), text: this.username })
            .height(64)
            .margin({ left: AhuDimens.contentHorizontal, right: AhuDimens.contentHorizontal })
            .padding({ left: AhuDimens.titleHorizontal, right: AhuDimens.titleHorizontal })
            .fontSize(AhuTypography.body)
            .fontColor(AhuColors.onSurface)
            .placeholderColor(AhuColors.onSurfaceSecondary)
            .backgroundColor(AhuColors.card)
            .borderRadius(32)
            .type(InputType.Normal)
            .contentType(ContentType.USER_NAME)
            .enableAutoFill(true)
            .onFocus(() => {
              this.focusIndex = 0;
            })
            .onChange((value: string) => {
              this.username = value;
            });

          TextInput({ placeholder: $r('app.string.login_password_hint'), text: this.password })
            .height(64)
            .margin({ left: AhuDimens.contentHorizontal, right: AhuDimens.contentHorizontal })
            .padding({ left: AhuDimens.titleHorizontal, right: AhuDimens.titleHorizontal })
            .fontSize(AhuTypography.body)
            .fontColor(AhuColors.onSurface)
            .placeholderColor(AhuColors.onSurfaceSecondary)
            .backgroundColor(AhuColors.card)
            .borderRadius(32)
            .type(InputType.Password)
            .contentType(ContentType.PASSWORD)
            .enableAutoFill(true)
            .showPasswordIcon(true)
            .onFocus(() => {
              this.focusIndex = 1;
            })
            .onChange((value: string) => {
              this.password = value;
            });
        }
        .width('100%')
        .padding({ bottom: 112 });
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off);

      Row() {
        this.loginStatus();
      }
      .padding(AhuDimens.contentHorizontal);
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AhuColors.pageBackground);
  }
}
