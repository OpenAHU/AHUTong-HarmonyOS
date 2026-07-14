const HOME_WIDGET_SLOT_COUNT: number = 8;

export function normalizeHomeWidgetSlots(slots: Array<string>): Array<string> {
  const seen: Array<string> = [];
  return Array.from({ length: HOME_WIDGET_SLOT_COUNT }, (_: Object, index: number): string => {
    const id = (slots[index] ?? '').trim();
    if (id.length === 0 || seen.includes(id)) return '';
    seen.push(id);
    return id;
  });
}
