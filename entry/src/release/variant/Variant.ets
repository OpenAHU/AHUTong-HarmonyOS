import { AppRoot } from 'entry/ets/pages/AppRoot';
import { AhuCache } from 'core_datastore';

@Component
export struct VariantRoot {
  aboutToAppear(): void {
    if (AhuCache.getMockData()) AhuCache.endMockSession();
  }

  build() { AppRoot({ debugEnabled: false }); }
}
