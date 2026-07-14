const COOKIE_ATTRIBUTES: Array<string> = [
  'path', 'domain', 'expires', 'max-age', 'secure', 'httponly', 'samesite', 'priority'
];

export class MemoryCookieJar {
  private values: Map<string, string> = new Map<string, string>();

  save(responseCookies: string): void {
    if (responseCookies.length === 0) {
      return;
    }
    const segments = responseCookies.split(/[;,]/);
    for (let index = 0; index < segments.length; index++) {
      const segment = segments[index].trim();
      const equals = segment.indexOf('=');
      if (equals <= 0) {
        continue;
      }
      const name = segment.substring(0, equals).trim();
      const value = segment.substring(equals + 1).trim();
      if (COOKIE_ATTRIBUTES.includes(name.toLowerCase())) {
        continue;
      }
      if (value.length === 0) {
        this.values.delete(name);
      } else {
        this.values.set(name, value);
      }
    }
  }

  header(): string {
    const pairs: Array<string> = [];
    this.values.forEach((value: string, name: string) => {
      pairs.push(`${name}=${value}`);
    });
    return pairs.join('; ');
  }

  clear(): void {
    this.values.clear();
  }
}

export class CrawlerSession {
  static readonly portalCookies: MemoryCookieJar = new MemoryCookieJar();
  static readonly academicCookies: MemoryCookieJar = new MemoryCookieJar();
  private static academicReloginHandler?: AcademicReloginHandler;
  private static portalReloginHandler?: AcademicReloginHandler;

  static setAcademicReloginHandler(handler: AcademicReloginHandler): void {
    CrawlerSession.academicReloginHandler = handler;
  }

  static async reauthenticateAcademic(): Promise<boolean> {
    if (!CrawlerSession.academicReloginHandler) {
      return false;
    }
    return CrawlerSession.academicReloginHandler.relogin();
  }

  static setPortalReloginHandler(handler: AcademicReloginHandler): void {
    CrawlerSession.portalReloginHandler = handler;
  }

  static async reauthenticatePortal(): Promise<boolean> {
    return CrawlerSession.portalReloginHandler?.relogin() ?? false;
  }

  static clearAll(): void {
    CrawlerSession.portalCookies.clear();
    CrawlerSession.academicCookies.clear();
  }
}

export interface AcademicReloginHandler {
  relogin(): Promise<boolean>;
}
