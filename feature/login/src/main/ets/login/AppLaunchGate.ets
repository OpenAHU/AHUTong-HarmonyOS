import { AuthSession } from 'data_auth';
import { LaunchConsentGate } from './LaunchConsentGate';
import { LoginPage } from './LoginPage';

@Component
export struct AppLaunchGate {
  @State loggedIn: boolean = false;
  rejectAction: () => void = () => {};

  @Builder
  private emptyContent() {}

  @BuilderParam content: () => void = this.emptyContent;

  aboutToAppear(): void {
    this.loggedIn = AuthSession.isLoggedIn();
  }

  @Builder
  private authenticatedContent() {
    if (this.loggedIn) {
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
