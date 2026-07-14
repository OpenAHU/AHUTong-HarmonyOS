import { describe, it, expect } from '@ohos/hypium';
import { AppSessionState } from '../main/ets/common/AppResult';

export default function localUnitTest() {
  describe('appSessionState', () => {
    it('notifiesEachSubscriberOnce', 0, () => {
      let firstCount = 0;
      let secondCount = 0;
      const first = (): void => { firstCount++; };
      const second = (): void => { secondCount++; };
      AppSessionState.subscribe(first);
      AppSessionState.subscribe(first);
      AppSessionState.subscribe(second);
      AppSessionState.expire();
      expect(firstCount).assertEqual(1);
      expect(secondCount).assertEqual(1);
      expect(AppSessionState.sessionExpired).assertTrue();
      AppSessionState.unsubscribe(first);
      AppSessionState.unsubscribe(second);
      AppSessionState.activate();
    });

    it('stopsNotificationsAfterUnsubscribe', 0, () => {
      let count = 0;
      const listener = (): void => { count++; };
      AppSessionState.subscribe(listener);
      AppSessionState.unsubscribe(listener);
      AppSessionState.expire();
      expect(count).assertEqual(0);
      AppSessionState.activate();
      expect(AppSessionState.sessionExpired).assertFalse();
    });
  });
}
