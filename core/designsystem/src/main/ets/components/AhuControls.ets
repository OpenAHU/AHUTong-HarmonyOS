import { AhuColors, AhuTypography } from '../theme/AhuTokens';

@Component
export struct AhuPrimaryButton {
  @Prop text: string = '';
  @Prop enabled: boolean = true;
  onClick: () => void = () => {};

  build() {
    Button(this.text, { type: ButtonType.Capsule, stateEffect: true })
      .fontSize(AhuTypography.body)
      .fontWeight(FontWeight.Medium)
      .fontColor(AhuColors.onPrimaryAction)
      .backgroundColor(AhuColors.primaryAction)
      .opacity(this.enabled ? 1 : 0.4)
      .enabled(this.enabled)
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .onClick(() => this.onClick());
  }
}

@Component
export struct AhuChip {
  @Prop text: string = '';
  @Prop selected: boolean = false;
  onClick: () => void = () => {};

  build() {
    Text(this.text)
      .fontSize(AhuTypography.label)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.selected ? AhuColors.onPrimaryAction : AhuColors.onSurface)
      .backgroundColor(this.selected ? AhuColors.chipSelected : AhuColors.chipUnselected)
      .borderRadius(24)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .onClick(() => this.onClick());
  }
}
