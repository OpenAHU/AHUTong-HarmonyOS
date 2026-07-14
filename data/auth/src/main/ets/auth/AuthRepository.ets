import { AppErrorKind, AppResult, AppResults } from 'core_common';
import { AhuCache, SecureCredentialStore } from 'core_datastore';
import { User } from 'core_model';
import { CampusNativeGateway } from 'core_sdk_api';
import {
  AcademicReloginHandler,
  CrawlerAuthenticator,
  CrawlerSession,
  PortalCrawlerAuthenticator
} from 'data_crawler';

export interface AuthRepository {
  login(username: string, password: string): Promise<AppResult<User>>;
  restoreSession(): Promise<AppResult<User>>;
  logout(): Promise<void>;
}

export class DefaultAuthRepository implements AuthRepository {
  private readonly gateway: CampusNativeGateway;
  private readonly crawler: CrawlerAuthenticator;
  private readonly credentialStore: SecureCredentialStore;

  constructor(gateway: CampusNativeGateway, crawler: CrawlerAuthenticator = new PortalCrawlerAuthenticator(),
    credentialStore: SecureCredentialStore = new SecureCredentialStore()) {
    this.gateway = gateway;
    this.crawler = crawler;
    this.credentialStore = credentialStore;
  }

  async login(username: string, password: string): Promise<AppResult<User>> {
    const normalizedUsername = username.trim();
    if (normalizedUsername.length === 0 || password.length === 0) {
      return AppResults.failure<User>(AppErrorKind.AUTHENTICATION, '请将信息填写完整');
    }

    AhuCache.clearCurrentUser();
    this.gateway.clearSession();
    this.crawler.clearSession();
    const result = this.gateway.isNativeLoaded()
      ? await this.gateway.login(normalizedUsername, password)
      : await this.crawler.login(normalizedUsername, password);
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
    try {
      await this.credentialStore.save(normalizedUsername, password);
    } catch (_) {
      this.gateway.clearSession();
      this.crawler.clearSession();
      AhuCache.clearCurrentUser();
      return AppResults.failure<User>(AppErrorKind.UNKNOWN, '安全保存登录凭据失败');
    }
    return result;
  }

  async restoreSession(): Promise<AppResult<User>> {
    const cachedUser = AhuCache.getCurrentUser();
    const credential = await this.credentialStore.load();
    if (!cachedUser || !credential) {
      AhuCache.clearCurrentUser();
      return AppResults.failure<User>(AppErrorKind.AUTHENTICATION, '没有可恢复的登录会话');
    }
    this.gateway.clearSession();
    this.crawler.clearSession();
    const result = this.gateway.isNativeLoaded()
      ? await this.gateway.login(credential.username, credential.password)
      : await this.crawler.login(credential.username, credential.password);
    if (!result.isSuccess || !result.data) {
      AhuCache.clearCurrentUser();
      return result;
    }
    AhuCache.saveCurrentUser(result.data);
    return result;
  }

  async logout(): Promise<void> {
    this.gateway.clearSession();
    this.crawler.clearSession();
    AhuCache.logout();
    await this.credentialStore.remove();
  }
}

export class AuthRepositoryProvider {
  private static repository?: AuthRepository;

  static initialize(gateway: CampusNativeGateway): void {
    AuthRepositoryProvider.repository = new DefaultAuthRepository(gateway);
    const handler = new RepositoryReloginHandler(AuthRepositoryProvider.repository);
    CrawlerSession.setAcademicReloginHandler(handler);
    CrawlerSession.setPortalReloginHandler(handler);
  }

  static get(): AuthRepository {
    if (!AuthRepositoryProvider.repository) {
      throw new Error('AuthRepositoryProvider is not initialized');
    }
    return AuthRepositoryProvider.repository;
  }
}

class RepositoryReloginHandler implements AcademicReloginHandler {
  private readonly repository: AuthRepository;

  constructor(repository: AuthRepository) {
    this.repository = repository;
  }

  async relogin(): Promise<boolean> {
    const result = await this.repository.restoreSession();
    return result.isSuccess;
  }
}
