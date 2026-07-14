import { AhuCache } from 'core_datastore';
import { AhuColors, AhuDimens, AhuTypography } from 'core_designsystem';

@Component
export struct LaunchConsentGate {
  @State currentStep: number = 0;
  rejectAction: () => void = () => {};

  @Builder
  private emptyContent() {}

  @BuilderParam content: () => void = this.emptyContent;

  aboutToAppear(): void {
    this.currentStep = this.findPendingStep();
  }

  private findPendingStep(): number {
    if (!AhuCache.isAgreementAccepted()) {
      return 0;
    }
    if (!AhuCache.isPrivacyAccepted()) {
      return 1;
    }
    if (!AhuCache.isBusinessAccepted()) {
      return 2;
    }
    return 3;
  }

  private title(): ResourceStr {
    if (this.currentStep === 0) {
      return $r('app.string.login_agreement_title');
    }
    if (this.currentStep === 1) {
      return $r('app.string.login_privacy_title');
    }
    return $r('app.string.login_business_title');
  }

  private body(): ResourceStr {
    if (this.currentStep === 0) {
      return $r('app.string.login_agreement_body');
    }
    if (this.currentStep === 1) {
      return $r('app.string.login_privacy_body');
    }
    return $r('app.string.login_business_body');
  }

  private acceptCurrent(): void {
    if (this.currentStep === 0) {
      AhuCache.setAgreementAccepted();
    } else if (this.currentStep === 1) {
      AhuCache.setPrivacyAccepted();
    } else {
      AhuCache.setBusinessAccepted();
    }
    this.currentStep = this.findPendingStep();
  }

  @Builder
  private consentContent() {
    Column({ space: 20 }) {
      Text(this.title())
        .width('100%')
        .fontSize(AhuTypography.sectionTitle)
        .fontWeight(FontWeight.Bold)
        .fontColor(AhuColors.onSurface)
        .textAlign(TextAlign.Start);

      Scroll() {
        Text(this.body())
          .width('100%')
          .fontSize(AhuTypography.body)
          .fontColor(AhuColors.onSurfaceSecondary)
          .lineHeight(25)
          .textAlign(TextAlign.Start);
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto);

      Row({ space: 12 }) {
        Button($r('app.string.login_disagree'), { type: ButtonType.Capsule })
          .layoutWeight(1)
          .fontSize(AhuTypography.body)
          .fontColor(AhuColors.onSurface)
          .backgroundColor(AhuColors.chipUnselected)
          .onClick(() => this.rejectAction());
        Button($r('app.string.login_agree'), { type: ButtonType.Capsule })
          .layoutWeight(1)
          .fontSize(AhuTypography.body)
          .fontColor(AhuColors.onPrimaryAction)
          .backgroundColor(AhuColors.primaryAction)
          .onClick(() => this.acceptCurrent());
      }
      .width('100%');
    }
    .width('100%')
    .height('100%')
    .padding({
      left: AhuDimens.cardPaddingHorizontal,
      right: AhuDimens.cardPaddingHorizontal,
      top: AhuDimens.cardPaddingVertical,
      bottom: AhuDimens.cardPaddingVertical
    })
    .backgroundColor(AhuColors.card)
    .borderRadius(AhuDimens.cardCorner);
  }

  build() {
    if (this.currentStep >= 3) {
      this.content();
    } else {
      Stack() {
        this.consentContent();
      }
      .width('100%')
      .height('100%')
      .padding({ left: 16, right: 16, top: 32, bottom: 32 })
      .backgroundColor(AhuColors.pageBackground);
    }
  }
}
