import { AppErrorKind, AppResult, AppResults } from 'core_common';
import { AhuCache } from 'core_datastore';
import { User } from 'core_model';
import { CampusNativeGateway } from 'core_sdk_api';

export interface AuthRepository {
  login(username: string, password: string): Promise<AppResult<User>>;
  logout(): void;
}

export class DefaultAuthRepository implements AuthRepository {
  private readonly gateway: CampusNativeGateway;

  constructor(gateway: CampusNativeGateway) {
    this.gateway = gateway;
  }

  async login(username: string, password: string): Promise<AppResult<User>> {
    const normalizedUsername = username.trim();
    if (normalizedUsername.length === 0 || password.length === 0) {
      return AppResults.failure<User>(AppErrorKind.AUTHENTICATION, '请将信息填写完整');
    }

    AhuCache.clearCurrentUser();
    this.gateway.clearSession();
    const result = await this.gateway.login(normalizedUsername, password);
    if (!result.isSuccess) {
      return result;
    }
    if (!result.data) {
      return AppResults.failure<User>(AppErrorKind.PARSE, '登录结果缺少用户信息');
    }

    AhuCache.saveCurrentUser(result.data);
    AhuCache.setAgreementAccepted();
    AhuCache.setPrivacyAccepted();
    AhuCache.setBusinessAccepted();
    return result;
  }

  logout(): void {
    this.gateway.clearSession();
    AhuCache.logout();
  }
}

export class AuthRepositoryProvider {
  private static repository?: AuthRepository;

  static initialize(gateway: CampusNativeGateway): void {
    AuthRepositoryProvider.repository = new DefaultAuthRepository(gateway);
  }

  static get(): AuthRepository {
    if (!AuthRepositoryProvider.repository) {
      throw new Error('AuthRepositoryProvider is not initialized');
    }
    return AuthRepositoryProvider.repository;
  }
}
