import { http } from '@kit.NetworkKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';
import { AppErrorKind, AppResult, AppResults } from 'core_common';
import { CrawlerSession, MemoryCookieJar } from 'data_crawler';

export interface CardAccount { name: string; type: string; balance: number; }
export interface BathroomData {
  projectId: number; projectName: string; accountId: number; telPhone: string; identifier?: string;
  sex: string; name?: string; statusId: number; accountMoney: number; accountGivenMoney: number;
  alias?: string; tags?: string; isCard: number; cardStatusId: number; isUseCode: number;
  cardPhysicalId?: string; tsmAbstract: string; myCustomInfo?: string; message?: string;
}
export interface BathroomAccount { phone: string; cashAmount: string; giftAmount: string; data: BathroomData; }
interface TokenResponse { access_token?: string; }
interface AccountInfo { name: string; type: string; balance: number; }
interface CardData { accinfo?: Array<AccountInfo>; }
interface CardInfoData { card?: Array<CardData>; }
interface CardInfoResponse { code: number; msg?: string; data?: CardInfoData; }
interface PayResponse { code: number; msg?: string; data?: string; }
interface BathroomMap { showData?: Object; data?: BathroomData; }
interface BathroomResponse { code: number; msg?: string; message?: string; map?: BathroomMap; }
interface RawResponse { status: number; body: string; location: string; }
interface ResponseHeaders { location?: string; Location?: string; }

const APP_ID: string = '56321';
const SECRET_KEY: string = '0osTIhce7uPvDKHz6aa67bhCukaKoYl4';

class YcardClient {
  private readonly cookies: MemoryCookieJar = new MemoryCookieJar();
  private token: string = '';

  private cookieHeader(includeAcademic: boolean = false): string {
    const values: Array<string> = [];
    if (includeAcademic && CrawlerSession.academicCookies.header().length > 0)
      values.push(CrawlerSession.academicCookies.header());
    if (this.cookies.header().length > 0) values.push(this.cookies.header());
    return values.join('; ');
  }

  private location(headers: Object): string {
    const values = headers as ResponseHeaders;
    return values.location ?? values.Location ?? '';
  }

  private async request(url: string, method: http.RequestMethod = http.RequestMethod.GET,
    body?: string, includeAcademic: boolean = false, authorization?: string): Promise<AppResult<RawResponse>> {
    const request = http.createHttp();
    try {
      const headers: Record<string, string> = { 'Accept': 'application/json', 'User-Agent': 'AHUTong/1.0 (HarmonyOS)' };
      const cookie = this.cookieHeader(includeAcademic);
      if (cookie.length > 0) headers['Cookie'] = cookie;
      if (body !== undefined) headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8';
      if (authorization) headers['Authorization'] = authorization;
      else if (this.token.length > 0) headers['Synjones-Auth'] = `bearer ${this.token}`;
      const response = await request.request(url, { method: method, header: headers, extraData: body,
        expectDataType: http.HttpDataType.STRING, connectTimeout: 15_000, readTimeout: 30_000,
        usingCache: false, maxRedirects: 0 });
      this.cookies.save(response.cookies);
      return AppResults.success<RawResponse>({ status: response.responseCode as number,
        body: response.result as string, location: this.location(response.header) });
    } catch (error) {
      return AppResults.failure<RawResponse>(AppErrorKind.TRANSPORT, (error as Error).message ?? '校园卡网络请求失败');
    } finally { request.destroy(); }
  }

  private form(fields: Map<string, string>): string {
    const values: Array<string> = [];
    fields.forEach((value: string, key: string) =>
      values.push(`${encodeURIComponent(key)}=${encodeURIComponent(value)}`));
    return values.join('&');
  }

  private resolveLocation(location: string, current: string): string {
    if (/^https?:\/\//i.test(location)) return location;
    const schemeEnd = current.indexOf('://');
    const pathStart = schemeEnd >= 0 ? current.indexOf('/', schemeEnd + 3) : -1;
    const origin = pathStart > 0 ? current.substring(0, pathStart) : current;
    return location.startsWith('/') ? `${origin}${location}` : `${origin}/${location}`;
  }

  private async ensureToken(): Promise<AppResult<boolean>> {
    if (this.token.length > 0) return AppResults.success<boolean>(true);
    let url = 'https://ycard.ahu.edu.cn/berserker-auth/cas/redirect/neusoftCas' +
      '?targetUrl=https%3A%2F%2Fycard.ahu.edu.cn%2Fplat%2F%3Fname%3DloginTransit';
    let ticket = '';
    for (let index = 0; index < 12; index++) {
      const match = url.match(/[?&]ticket=([^&]+)/);
      if (match && match.length > 1) { ticket = match[1]; break; }
      const response = await this.request(url, http.RequestMethod.GET, undefined, true);
      if (!response.isSuccess || !response.data)
        return AppResults.failure<boolean>(response.error?.kind ?? AppErrorKind.UNKNOWN,
          response.error?.message ?? '校园卡统一认证失败', response.error?.code);
      if (response.data.location.length === 0) break;
      url = this.resolveLocation(response.data.location, url);
    }
    if (ticket.length === 0)
      return AppResults.failure<boolean>(AppErrorKind.AUTHENTICATION, '未能获取校园卡登录票据，请重新登录后重试');
    const identity = decodeURIComponent(decodeURIComponent(ticket));
    const tokenFields = new Map<string, string>();
    tokenFields.set('username', identity); tokenFields.set('password', identity);
    tokenFields.set('grant_type', 'password'); tokenFields.set('scope', 'all');
    tokenFields.set('loginFrom', 'h5'); tokenFields.set('logintype', 'sso');
    tokenFields.set('device_token', 'h5'); tokenFields.set('synAccessSource', 'h5');
    const body = this.form(tokenFields);
    const tokenResponse = await this.request('https://ycard.ahu.edu.cn/berserker-auth/oauth/token',
      http.RequestMethod.POST, body, false,
      'Basic bW9iaWxlX3NlcnZpY2VfcGxhdGZvcm06bW9iaWxlX3NlcnZpY2VfcGxhdGZvcm1fc2VjcmV0');
    if (!tokenResponse.isSuccess || !tokenResponse.data || tokenResponse.data.status !== 200)
      return AppResults.failure<boolean>(AppErrorKind.AUTHENTICATION, '校园卡登录凭证暂未就绪');
    try { this.token = (JSON.parse(tokenResponse.data.body) as TokenResponse).access_token ?? ''; }
    catch (_) { this.token = ''; }
    return this.token.length > 0 ? AppResults.success<boolean>(true) :
      AppResults.failure<boolean>(AppErrorKind.AUTHENTICATION, '校园卡登录凭证解析失败');
  }

  async account(): Promise<AppResult<CardAccount>> {
    const ready = await this.ensureToken();
    if (!ready.isSuccess) return AppResults.failure<CardAccount>(ready.error?.kind ?? AppErrorKind.AUTHENTICATION,
      ready.error?.message ?? '校园卡登录凭证暂未就绪');
    const response = await this.request('https://ycard.ahu.edu.cn/berserker-app/ykt/tsm/queryCard?scene=cardRecharge&synAccessSource=h5');
    if (!response.isSuccess || !response.data || response.data.status !== 200)
      return AppResults.failure<CardAccount>(AppErrorKind.HTTP, '获取校园卡账户失败', response.data?.status);
    try {
      const parsed = JSON.parse(response.data.body) as CardInfoResponse;
      const cards: Array<CardData> = parsed.data?.card ?? [];
      if (cards.length === 0) return AppResults.failure<CardAccount>(AppErrorKind.PARSE, parsed.msg ?? '未获取到校园卡账户');
      const accounts: Array<AccountInfo> = cards[0].accinfo ?? [];
      if (accounts.length === 0) return AppResults.failure<CardAccount>(AppErrorKind.PARSE, parsed.msg ?? '未获取到校园卡账户');
      const account: AccountInfo = accounts[0];
      return AppResults.success<CardAccount>({ name: account.name, type: account.type, balance: account.balance / 100 });
    } catch (_) { return AppResults.failure<CardAccount>(AppErrorKind.PARSE, '校园卡账户数据解析失败'); }
  }

  async post(path: string, fields: Map<string, string>): Promise<AppResult<RawResponse>> {
    const ready = await this.ensureToken();
    if (!ready.isSuccess) return AppResults.failure<RawResponse>(ready.error?.kind ?? AppErrorKind.AUTHENTICATION,
      ready.error?.message ?? '校园卡登录凭证暂未就绪');
    return this.request(`https://ycard.ahu.edu.cn${path}`, http.RequestMethod.POST, this.form(fields));
  }
}

export class CardPaymentRepository {
  private readonly client: YcardClient = new YcardClient();

  getAccount(): Promise<AppResult<CardAccount>> { return this.client.account(); }

  private jsonField(source: string, name: string): string {
    const match = source.match(new RegExp(`"${name}"\\s*:\\s*"([^"]*)"`));
    return match && match.length > 1 ? match[1] : '';
  }

  async getBathroomAccount(bathroom: string, phone: string): Promise<AppResult<BathroomAccount>> {
    const feeItem = bathroom === '竹园/龙河' ? '409' : bathroom === '桔园/蕙园' ? '430' : '';
    if (feeItem.length === 0) return AppResults.failure<BathroomAccount>(AppErrorKind.PARSE, '暂不支持该浴室');
    const fields = new Map<string, string>();
    fields.set('feeitemid', feeItem); fields.set('type', 'IEC'); fields.set('level', '1'); fields.set('telPhone', phone);
    const response = await this.client.post('/charge/feeitem/getThirdData', fields);
    if (!response.isSuccess || !response.data || response.data.status !== 200)
      return AppResults.failure<BathroomAccount>(response.error?.kind ?? AppErrorKind.HTTP,
        response.error?.message ?? '获取浴室账户失败', response.data?.status);
    try {
      const parsed = JSON.parse(response.data.body) as BathroomResponse;
      if (!parsed.map?.data) return AppResults.failure<BathroomAccount>(AppErrorKind.PARSE,
        parsed.message ?? parsed.msg ?? '未查询到浴室账户');
      const showJson = parsed.map.showData ? JSON.stringify(parsed.map.showData) : '';
      return AppResults.success<BathroomAccount>({
        phone: this.jsonField(showJson, '手机号') || parsed.map.data.telPhone,
        cashAmount: this.jsonField(showJson, '现金金额（单位：元）'),
        giftAmount: this.jsonField(showJson, '赠送金额（单位：元）'), data: parsed.map.data
      });
    } catch (_) { return AppResults.failure<BathroomAccount>(AppErrorKind.PARSE, '浴室账户数据解析失败'); }
  }

  async chargeBathroom(bathroom: string, amount: string, password: string,
    account: BathroomAccount): Promise<AppResult<string>> {
    const feeItem = bathroom === '竹园/龙河' ? '409' : bathroom === '桔园/蕙园' ? '430' : '';
    if (feeItem.length === 0) return AppResults.failure<string>(AppErrorKind.PARSE, '暂不支持该浴室');
    account.data.myCustomInfo = `手机号：${account.data.telPhone}`;
    const orderFields = new Map<string, string>();
    orderFields.set('feeitemid', feeItem); orderFields.set('tranamt', amount); orderFields.set('flag', 'choose');
    orderFields.set('source', 'app'); orderFields.set('paystep', '0'); orderFields.set('abstracts', '');
    orderFields.set('third_party', JSON.stringify(account.data));
    const order = await this.client.post('/blade-pay/pay', orderFields);
    if (!order.isSuccess || !order.data || order.data.status !== 200)
      return AppResults.failure<string>(order.error?.kind ?? AppErrorKind.HTTP,
        order.error?.message ?? '创建浴室充值订单失败', order.data?.status);
    const orderMatch = order.data.body.match(/"orderid"\s*:\s*"([^"]+)"/);
    if (!orderMatch || orderMatch.length < 2)
      return AppResults.failure<string>(AppErrorKind.PARSE, '未能获取浴室充值订单号');
    const orderId = orderMatch[1];
    const mapString = '1690457382';
    let cipher = '';
    for (let index = 0; index < password.length; index++) {
      const mapped = mapString.indexOf(password.charAt(index));
      cipher += mapped >= 0 ? `${mapped}` : password.charAt(index);
    }
    const payFields = new Map<string, string>();
    payFields.set('orderid', orderId); payFields.set('paystep', '2'); payFields.set('paytype', 'ACCOUNTTSM');
    payFields.set('paytypeid', '64'); payFields.set('userAgent', 'h5'); payFields.set('ccctype', '000');
    payFields.set('password', cipher); payFields.set('uuid', 'da07e4442e4841cca1655cb29653a023'); payFields.set('isWX', '0');
    const payment = await this.client.post('/blade-pay/pay', payFields);
    if (!payment.isSuccess || !payment.data || payment.data.status !== 200)
      return AppResults.failure<string>(payment.error?.kind ?? AppErrorKind.HTTP,
        payment.error?.message ?? '浴室充值失败', payment.data?.status);
    try {
      const parsed = JSON.parse(payment.data.body) as PayResponse;
      return parsed.code === 200 ? AppResults.success<string>(parsed.data ?? orderId) :
        AppResults.failure<string>(AppErrorKind.HTTP, parsed.msg ?? '浴室充值失败', parsed.code);
    } catch (_) { return AppResults.failure<string>(AppErrorKind.PARSE, '浴室支付结果解析失败'); }
  }

  private timestamp(): string {
    const date = new Date();
    const part = (value: number): string => `${value}`.padStart(2, '0');
    return `${date.getFullYear()}${part(date.getMonth() + 1)}${part(date.getDate())}` +
      `${part(date.getHours())}${part(date.getMinutes())}${part(date.getSeconds())}`;
  }

  private nonce(): string {
    const charset = '0123456789abcdefghijklmnopqrstuvwxyz';
    try {
      const bytes = cryptoFramework.createRandom().generateRandomSync(11).data;
      let result = '';
      for (let index = 0; index < bytes.length; index++) result += charset.charAt(bytes[index] % charset.length);
      return result;
    } catch (_) {
      return `${Date.now().toString(36)}00000000000`.substring(0, 11);
    }
  }

  private sha256(value: string): string {
    try {
      const md = cryptoFramework.createMd('SHA256');
      md.updateSync({ data: new util.TextEncoder().encodeInto(value) });
      const bytes = md.digestSync().data;
      let result = '';
      for (let index = 0; index < bytes.length; index++) result += bytes[index].toString(16).padStart(2, '0');
      return result.toUpperCase();
    } catch (_) {
      return '';
    }
  }

  async charge(amount: string, cardType: string): Promise<AppResult<string>> {
    const time = this.timestamp();
    const nonce = this.nonce();
    const orderFields = new Map<string, string>();
    orderFields.set('feeitemid', '401'); orderFields.set('appid', APP_ID); orderFields.set('tranamt', amount);
    orderFields.set('source', 'app'); orderFields.set('yktcard', cardType); orderFields.set('synAccessSource', 'h5');
    orderFields.set('APP_ID', APP_ID); orderFields.set('TIMESTAMP', time); orderFields.set('SIGN_TYPE', 'SHA256');
    orderFields.set('NONCE', nonce); orderFields.set('SIGN', this.sha256(
      `APP_ID=${APP_ID}&NONCE=${nonce}&SIGN_TYPE=SHA256&TIMESTAMP=${time}` +
      `&appid=${APP_ID}&feeitemid=401&source=app&synAccessSource=h5&tranamt=${amount}&yktcard=${cardType}&SECRET_KEY=${SECRET_KEY}`));
    const order = await this.client.post('/charge/order/thirdOrder', orderFields);
    if (!order.isSuccess || !order.data)
      return AppResults.failure<string>(order.error?.kind ?? AppErrorKind.UNKNOWN, order.error?.message ?? '创建订单失败');
    const orderMatch = order.data.location.match(/[?&]orderid=([^&]+)/);
    if (!orderMatch || orderMatch.length < 2)
      return AppResults.failure<string>(AppErrorKind.PARSE, '未能获取充值订单号');
    const orderId = decodeURIComponent(orderMatch[1]);
    const payTime = this.timestamp();
    const payNonce = this.nonce();
    const redirectUrl = 'https://ycard.ahu.edu.cn/payment/?name=result';
    const payFields = new Map<string, string>();
    payFields.set('paytypeid', '63'); payFields.set('paytype', 'BANKCARD'); payFields.set('paystep', '2');
    payFields.set('orderid', orderId); payFields.set('redirect_url', redirectUrl); payFields.set('userAgent', 'h5');
    payFields.set('APP_ID', APP_ID); payFields.set('TIMESTAMP', payTime); payFields.set('SIGN_TYPE', 'SHA256');
    payFields.set('NONCE', payNonce); payFields.set('synAccessSource', 'h5');
    payFields.set('SIGN', this.sha256(`APP_ID=${APP_ID}&NONCE=${payNonce}&SIGN_TYPE=SHA256&TIMESTAMP=${payTime}` +
      `&orderid=${orderId}&paystep=2&paytype=BANKCARD&paytypeid=63&redirect_url=${redirectUrl}` +
      `&userAgent=h5&SECRET_KEY=${SECRET_KEY}`));
    const payment = await this.client.post('/blade-pay/pay', payFields);
    if (!payment.isSuccess || !payment.data || payment.data.status !== 200)
      return AppResults.failure<string>(payment.error?.kind ?? AppErrorKind.HTTP,
        payment.error?.message ?? '银行卡支付失败', payment.data?.status);
    try {
      const parsed = JSON.parse(payment.data.body) as PayResponse;
      return parsed.code === 200 ? AppResults.success<string>(parsed.data ?? orderId) :
        AppResults.failure<string>(AppErrorKind.HTTP, parsed.msg ?? '银行卡支付失败', parsed.code);
    } catch (_) { return AppResults.failure<string>(AppErrorKind.PARSE, '支付结果解析失败'); }
  }
}

export class CardPaymentRepositoryProvider {
  private static readonly repository: CardPaymentRepository = new CardPaymentRepository();
  static get(): CardPaymentRepository { return CardPaymentRepositoryProvider.repository; }
}
