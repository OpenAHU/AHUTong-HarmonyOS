import { AhuColors, AhuLoading } from 'core_designsystem';
import { AuthRepositoryProvider, AuthSession } from 'data_auth';
import { LaunchConsentGate } from './LaunchConsentGate';
import { LoginPage } from './LoginPage';
import { AhuCache } from 'core_datastore';
import { AppSessionState } from 'core_common';

@Component
export struct AppLaunchGate {
  @State loggedIn: boolean = false;
  @State restoring: boolean = true;
  @StorageLink('ahu_logout_revision') logoutRevision: number = 0;
  rejectAction: () => void = () => {};
  private readonly sessionExpiredListener: () => void = (): void => {
    this.loggedIn = false;
  };

  @Builder
  private emptyContent() {}

  @BuilderParam content: () => void = this.emptyContent;

  async aboutToAppear(): Promise<void> {
    AppSessionState.subscribe(this.sessionExpiredListener);
    if (!AuthSession.isLoggedIn()) {
      this.restoring = false;
      return;
    }
    if (AhuCache.getMockData()) {
      this.loggedIn = true;
      this.restoring = false;
      return;
    }
    const result = await AuthRepositoryProvider.get().restoreSession();
    this.loggedIn = result.isSuccess;
    this.restoring = false;
  }

  aboutToDisappear(): void {
    AppSessionState.unsubscribe(this.sessionExpiredListener);
  }

  @Builder
  private authenticatedContent() {
    if (this.restoring) {
      Column() {
        AhuLoading({ message: $r('app.string.login_restoring_session') });
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor(AhuColors.pageBackground);
    } else if (this.logoutRevision >= 0 && this.loggedIn && AuthSession.isLoggedIn()) {
      this.content();
    } else {
      LoginPage({
        onLoggedIn: () => {
          this.loggedIn = true;
        }
      });
    }
  }

  build() {
    Stack() {
      LaunchConsentGate({
        rejectAction: this.rejectAction,
        content: this.authenticatedContent
      });
    }
    .width('100%')
    .height('100%');
  }
}
