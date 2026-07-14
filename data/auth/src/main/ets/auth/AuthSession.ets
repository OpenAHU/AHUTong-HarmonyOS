import { AhuCache } from 'core_datastore';

export class AuthSession {
  static isLoggedIn(): boolean {
    return AhuCache.isLogin();
  }

  static logout(): void {
    AhuCache.logout();
  }
}
