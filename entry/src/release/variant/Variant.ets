import { AppRoot } from 'entry/ets/pages/AppRoot';

@Component
export struct VariantRoot {
  build() { AppRoot({ debugEnabled: false }); }
}
