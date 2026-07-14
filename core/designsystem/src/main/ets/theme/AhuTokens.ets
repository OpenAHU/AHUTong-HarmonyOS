export class AhuColors {
  static readonly pageBackground: Resource = $r('app.color.ahu_page_background');
  static readonly card: Resource = $r('app.color.ahu_card');
  static readonly cardStrong: Resource = $r('app.color.ahu_card_strong');
  static readonly accentSurface: Resource = $r('app.color.ahu_accent_surface');
  static get primaryAction(): ResourceColor {
    const custom = AppStorage.get<string>('ahu_theme_color') ?? '';
    return custom.length > 0 ? custom : $r('app.color.ahu_primary_action');
  }
  static readonly onPrimaryAction: Resource = $r('app.color.ahu_on_primary_action');
  static readonly onSurface: Resource = $r('app.color.ahu_on_surface');
  static readonly onSurfaceSecondary: Resource = $r('app.color.ahu_on_surface_secondary');
  static readonly chipSelected: Resource = $r('app.color.ahu_chip_selected');
  static readonly chipUnselected: Resource = $r('app.color.ahu_chip_unselected');
  static readonly divider: Resource = $r('app.color.ahu_divider');
  static readonly error: Resource = $r('app.color.ahu_error');
}

export class AhuDimens {
  static readonly titleHorizontal: number = 24;
  static readonly titleTop: number = 32;
  static readonly contentHorizontal: number = 16;
  static readonly sectionSpacing: number = 24;
  static readonly bottomNavClearance: number = 96;
  static readonly cardCorner: number = 32;
  static readonly cardCornerMedium: number = 16;
  static readonly listItemCorner: number = 4;
  static readonly cardPaddingHorizontal: number = 24;
  static readonly cardPaddingVertical: number = 16;
}

export class AhuTypography {
  static readonly pageTitle: number = 28;
  static readonly sectionTitle: number = 20;
  static readonly body: number = 16;
  static readonly label: number = 14;
}
