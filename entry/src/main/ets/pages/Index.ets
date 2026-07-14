import { VariantRoot } from 'entry/variant/Variant';
import { BackPressDispatcher } from 'core_common';

@Entry
@Component
struct Index {
  onBackPress(): boolean { return BackPressDispatcher.handle(); }
  build() { Stack() { VariantRoot(); }.width('100%').height('100%'); }
}
