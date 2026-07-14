import { VariantRoot } from 'entry/variant/Variant';

@Entry
@Component
struct Index {
  build() { Stack() { VariantRoot(); }.width('100%').height('100%'); }
}
