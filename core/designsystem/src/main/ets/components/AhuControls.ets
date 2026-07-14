import { AhuColors, AhuTypography } from '../theme/AhuTokens';

@Component
export struct AhuPrimaryButton {
  @Prop text: string = '';
  @Prop isEnabled: boolean = true;
  clickAction: () => void = () => {};

  build() {
    Button(this.text, { type: ButtonType.Capsule, stateEffect: true })
      .fontSize(AhuTypography.body)
      .fontWeight(FontWeight.Medium)
      .fontColor(AhuColors.onPrimaryAction)
      .backgroundColor(AhuColors.primaryAction)
      .opacity(this.isEnabled ? 1 : 0.4)
      .enabled(this.isEnabled)
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .onClick(() => this.clickAction());
  }
}

@Component
export struct AhuChip {
  @Prop text: string = '';
  @Prop selected: boolean = false;
  clickAction: () => void = () => {};

  build() {
    Text(this.text)
      .fontSize(AhuTypography.label)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.selected ? AhuColors.onPrimaryAction : AhuColors.onSurface)
      .backgroundColor(this.selected ? AhuColors.chipSelected : AhuColors.chipUnselected)
      .borderRadius(24)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .onClick(() => this.clickAction());
  }
}
