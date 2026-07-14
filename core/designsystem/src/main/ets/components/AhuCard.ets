import { AhuColors, AhuDimens } from '../theme/AhuTokens';

@Component
export struct AhuCard {
  @Prop cornerRadius: number = AhuDimens.cardCorner;
  @Prop backgroundColor: ResourceColor = AhuColors.card;
  @BuilderParam content: () => void = () => {};

  build() {
    Column({ space: AhuDimens.contentHorizontal }) {
      this.content();
    }
    .width('100%')
    .padding({
      left: AhuDimens.cardPaddingHorizontal,
      right: AhuDimens.cardPaddingHorizontal,
      top: AhuDimens.cardPaddingVertical,
      bottom: AhuDimens.cardPaddingVertical
    })
    .backgroundColor(this.backgroundColor)
    .borderRadius(this.cornerRadius);
  }
}

@Component
export struct AhuInsetCard {
  @Prop cornerRadius: number = AhuDimens.cardCorner;
  @Prop backgroundColor: ResourceColor = AhuColors.card;
  @BuilderParam content: () => void = () => {};

  build() {
    Row() {
      AhuCard({
        cornerRadius: this.cornerRadius,
        backgroundColor: this.backgroundColor,
        content: this.content
      });
    }
    .width('100%')
    .padding({
      left: AhuDimens.contentHorizontal,
      right: AhuDimens.contentHorizontal
    });
  }
}
