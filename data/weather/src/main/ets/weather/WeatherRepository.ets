import { AppErrorKind, AppResult, AppResults } from 'core_common';
import { AhuCache } from 'core_datastore';
import { WeatherResponse } from 'core_model';
import { AhuHttpClient } from 'core_network';

export interface WeatherHomeConfig {
  showOnHome: boolean;
  showLocation: boolean;
  showTemperature: boolean;
  showCondition: boolean;
  showAqi: boolean;
}

export class WeatherRepository {
  private readonly client: AhuHttpClient = new AhuHttpClient();

  showOnHome(): boolean { return AhuCache.getWeatherShowOnHome(); }
  setShowOnHome(enabled: boolean): void { AhuCache.saveWeatherShowOnHome(enabled); }
  homeConfig(): WeatherHomeConfig {
    return {
      showOnHome: AhuCache.getWeatherShowOnHome(), showLocation: AhuCache.getWeatherShowLocation(),
      showTemperature: AhuCache.getWeatherShowTemperature(), showCondition: AhuCache.getWeatherShowCondition(),
      showAqi: AhuCache.getWeatherShowAqi()
    };
  }
  saveHomeConfig(config: WeatherHomeConfig): void {
    AhuCache.saveWeatherShowOnHome(config.showOnHome);
    AhuCache.saveWeatherShowLocation(config.showLocation);
    AhuCache.saveWeatherShowTemperature(config.showTemperature);
    AhuCache.saveWeatherShowCondition(config.showCondition);
    AhuCache.saveWeatherShowAqi(config.showAqi);
  }

  async getWeather(city?: string, forceRefresh: boolean = false): Promise<AppResult<WeatherResponse>> {
    const cached = AhuCache.getWeather();
    if (!forceRefresh && !city && cached) return AppResults.success<WeatherResponse>(cached);
    let query = 'extended=true&indices=true&forecast=true&hourly=true&lang=zh';
    if (city && city.trim().length > 0) query += `&city=${encodeURIComponent(city.trim())}`;
    else if (AhuCache.getWeatherAdcode()) query += `&adcode=${encodeURIComponent(AhuCache.getWeatherAdcode() ?? '')}`;
    const result = await this.client.request<WeatherResponse>({ url: `https://uapis.cn/api/v1/misc/weather?${query}`,
      connectTimeout: 10_000, readTimeout: 15_000 });
    if (result.isSuccess && result.data) { AhuCache.saveWeather(result.data); return result; }
    if (!city && cached) return AppResults.success<WeatherResponse>(cached);
    return AppResults.failure<WeatherResponse>(result.error?.kind ?? AppErrorKind.UNKNOWN,
      result.error?.message ?? '天气加载失败', result.error?.code);
  }
}

export class WeatherRepositoryProvider {
  private static readonly repository: WeatherRepository = new WeatherRepository();
  static get(): WeatherRepository { return WeatherRepositoryProvider.repository; }
}
