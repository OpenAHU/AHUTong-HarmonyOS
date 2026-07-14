import { AhuColors, AhuInsetCard, AhuScreen, AhuTypography } from 'core_designsystem';
import { ForecastDay, HourlyForecast, LifeIndexItem, WeatherAlert, WeatherResponse } from 'core_model';
import { WeatherHomeConfig, WeatherRepository, WeatherRepositoryProvider } from 'data_weather';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { geoLocationManager } from '@kit.LocationKit';
import { BackPressDispatcher } from 'core_common';

interface NamedLifeIndex { name: string; value?: LifeIndexItem; }

@Component
export struct WeatherPage {
  private readonly repository: WeatherRepository = WeatherRepositoryProvider.get();
  @State weather?: WeatherResponse = undefined;
  @State loading: boolean = true;
  @State error: string = '';
  @State city: string = '';
  @State searching: boolean = false;
  @State showOnHome: boolean = false;
  @State showLocation: boolean = true;
  @State showTemperature: boolean = true;
  @State showCondition: boolean = true;
  @State showAqi: boolean = true;
  @State locating: boolean = false;
  @State locationMessage: string = '';
  onBack: () => void = () => {};

  aboutToAppear(): void {
    BackPressDispatcher.register('weather_page', () => this.handleBackPress());
    const config = this.repository.homeConfig();
    this.showOnHome = config.showOnHome; this.showLocation = config.showLocation;
    this.showTemperature = config.showTemperature; this.showCondition = config.showCondition;
    this.showAqi = config.showAqi; this.load();
  }
  aboutToDisappear(): void { BackPressDispatcher.unregister('weather_page'); }

  private handleBackPress(): boolean {
    if (this.searching) { this.searching = false; this.city = ''; return true; }
    this.onBack();
    return true;
  }

  private saveHomeConfig(): void {
    const config: WeatherHomeConfig = { showOnHome: this.showOnHome, showLocation: this.showLocation,
      showTemperature: this.showTemperature, showCondition: this.showCondition, showAqi: this.showAqi };
    this.repository.saveHomeConfig(config);
  }

  private async load(city?: string): Promise<void> {
    if (this.loading && this.weather) return;
    this.loading = true; this.error = '';
    const result = await this.repository.getWeather(city, true);
    if (result.isSuccess && result.data) this.weather = result.data;
    else this.error = result.error?.message ?? '天气加载失败';
    this.loading = false;
  }

  private async locate(): Promise<void> {
    if (this.locating) return;
    this.locating = true; this.locationMessage = '';
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const permissions: Array<Permissions> = ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION'];
      const result = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(context, permissions);
      if (!result.authResults.some((value: number) => value === 0)) throw new Error('定位权限未授予');
      const location = await geoLocationManager.getCurrentLocation();
      const addresses = await geoLocationManager.getAddressesFromLocation({ latitude: location.latitude,
        longitude: location.longitude, maxItems: 1, locale: 'zh' });
      const address = addresses.length > 0 ? addresses[0] : undefined;
      const city = address?.locality ?? address?.subAdministrativeArea ?? address?.subLocality;
      if (!city || city.length === 0) throw new Error('无法识别所在城市');
      this.locationMessage = `已定位到 ${city}`;
      await this.load(city);
    } catch (error) {
      this.locationMessage = `${(error as Error).message ?? '定位失败'}，已使用缓存或 IP 定位`;
      await this.load();
    } finally { this.locating = false; }
  }

  private location(): string {
    return this.weather?.district ?? this.weather?.city ?? this.weather?.province ?? '当前位置';
  }

  private number(value?: number, suffix: string = ''): string {
    return value === undefined ? '--' : `${Math.round(value)}${suffix}`;
  }

  private lifeIndices(weather: WeatherResponse): Array<NamedLifeIndex> {
    const item = weather.life_indices;
    const values: Array<NamedLifeIndex> = [
      { name: '穿衣', value: item?.clothing }, { name: '紫外线', value: item?.uv },
      { name: '洗车', value: item?.car_wash }, { name: '运动', value: item?.exercise },
      { name: '舒适度', value: item?.comfort }, { name: '出行', value: item?.travel },
      { name: '感冒', value: item?.cold_risk }, { name: '雨伞', value: item?.umbrella }
    ];
    return values.filter((value: NamedLifeIndex) => value.value !== undefined);
  }

  private umbrellaText(weather: WeatherResponse): string {
    const rain = (value?: string): boolean => /雨|雪|雷|冰雹/.test(value ?? '');
    const hourlyRain = weather.hourly_forecast?.slice(0, 6).some((item: HourlyForecast) => rain(item.weather)) ?? false;
    const dailyRain = weather.forecast?.slice(0, 1).some((item: ForecastDay) => rain(item.weather_day) || rain(item.weather_night)) ?? false;
    return rain(weather.weather) || hourlyRain || dailyRain ? '建议带伞' : '暂时不用带伞';
  }

  @Builder
  private weatherSetting(label: string, enabled: boolean, onChange: (value: boolean) => void) {
    Row() {
      Text(label).fontSize(AhuTypography.body).fontColor(AhuColors.onSurface).layoutWeight(1);
      Toggle({ type: ToggleType.Switch, isOn: enabled }).onChange(onChange);
    }.width('100%').padding({ top: 2, bottom: 2 });
  }

  build() {
    AhuScreen({ scrollable: true }) {
      Row({ space: 10 }) {
        Button('‹', { type: ButtonType.Circle }).width(40).height(40).fontSize(28)
          .fontColor(AhuColors.onSurface).backgroundColor(AhuColors.card).onClick(() => this.onBack());
        Text(this.location()).fontSize(28).fontWeight(FontWeight.Bold).layoutWeight(1);
        Button(this.searching ? '取消' : '城市', { type: ButtonType.Capsule }).backgroundColor(AhuColors.card)
          .fontColor(AhuColors.onSurface).onClick(() => { this.searching = !this.searching; this.city = ''; });
        Button(this.locating ? '定位中' : '定位', { type: ButtonType.Capsule }).enabled(!this.locating && !this.loading)
          .backgroundColor(AhuColors.card).fontColor(AhuColors.onSurface).onClick(() => this.locate());
        Button('刷新', { type: ButtonType.Capsule }).enabled(!this.loading).backgroundColor(AhuColors.card)
          .fontColor(AhuColors.onSurface).onClick(() => this.load());
      }.width('100%').padding({ left: 16, right: 16, top: 20 });
      if (this.searching) {
        Row({ space: 8 }) {
          TextInput({ text: this.city, placeholder: '输入城市，如 合肥' }).layoutWeight(1)
            .onChange((value: string) => this.city = value);
          Button('查询', { type: ButtonType.Capsule }).enabled(this.city.trim().length > 0 && !this.loading)
            .onClick(() => { this.load(this.city); this.searching = false; });
        }.padding({ left: 16, right: 16 });
      }
      if (this.locationMessage.length > 0) Text(this.locationMessage).fontSize(AhuTypography.label)
        .fontColor(AhuColors.onSurfaceSecondary).padding({ left: 20, right: 20 });
      Column({ space: 8 }) {
        Text('天气设置').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold).width('100%');
        Text('选择要在首页卡片上显示的信息：').fontSize(AhuTypography.label)
          .fontColor(AhuColors.onSurfaceSecondary).width('100%');
        this.weatherSetting('在首页显示天气', this.showOnHome, (value: boolean) => {
          this.showOnHome = value; this.saveHomeConfig();
        });
        this.weatherSetting('显示城市名', this.showLocation, (value: boolean) => {
          this.showLocation = value; this.saveHomeConfig();
        });
        this.weatherSetting('显示温度', this.showTemperature, (value: boolean) => {
          this.showTemperature = value; this.saveHomeConfig();
        });
        this.weatherSetting('显示天气状况', this.showCondition, (value: boolean) => {
          this.showCondition = value; this.saveHomeConfig();
        });
        this.weatherSetting('显示空气质量', this.showAqi, (value: boolean) => {
          this.showAqi = value; this.saveHomeConfig();
        });
      }.width('100%').padding({ left: 20, right: 20 });
      if (this.loading && !this.weather) {
        Column({ space: 12 }) { LoadingProgress().width(48).height(48).color(AhuColors.primaryAction); Text('正在获取天气…'); }
          .width('100%').padding(48);
      } else if (!this.weather) {
        AhuInsetCard() { Column({ space: 12 }) { Text(this.error); Button('重试').onClick(() => this.load()); } }
      } else {
        AhuInsetCard() {
          Column({ space: 12 }) {
            Row() {
              Column({ space: 4 }) {
                Text(`${this.number(this.weather.temperature)}°`).fontSize(54).fontWeight(FontWeight.Bold);
                Text(this.weather.weather ?? '--').fontSize(AhuTypography.sectionTitle);
              }.layoutWeight(1).alignItems(HorizontalAlign.Start);
              Column({ space: 6 }) {
                Text(`体感 ${this.number(this.weather.feels_like)}°`);
                Text(`${this.number(this.weather.temp_min)}° / ${this.number(this.weather.temp_max)}°`);
                Text(this.umbrellaText(this.weather)).fontColor(AhuColors.primaryAction);
              }.alignItems(HorizontalAlign.End);
            }.width('100%');
            Row() {
              Text(`湿度 ${this.number(this.weather.humidity, '%')}`).layoutWeight(1).fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary);
              Text(`${this.weather.wind_direction ?? '--'}风 ${this.weather.wind_power ?? '--'}`).layoutWeight(1).fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary);
              Text(`能见度 ${this.number(this.weather.visibility, 'km')}`).layoutWeight(1).fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary);
            }.width('100%');
            if (this.weather.report_time) Text(`更新于 ${this.weather.report_time}`).fontSize(AhuTypography.label)
              .fontColor(AhuColors.onSurfaceSecondary);
          }.alignItems(HorizontalAlign.Start);
        }
        if (this.weather.alerts && this.weather.alerts.length > 0) {
          ForEach(this.weather.alerts, (item: WeatherAlert) => { AhuInsetCard() {
            Column({ space: 6 }) { Text(item.title ?? '天气预警').fontWeight(FontWeight.Bold).fontColor(AhuColors.error);
              Text(item.text ?? '').fontSize(AhuTypography.label).maxLines(4); }.alignItems(HorizontalAlign.Start);
          } }, (item: WeatherAlert, index: number) => `${item.title ?? ''}:${index}`);
        }
        if (this.weather.forecast && this.weather.forecast.length > 0) {
          Text('未来天气').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold).padding({ left: 18, right: 18 });
          Scroll() { Row({ space: 10 }) { ForEach(this.weather.forecast, (day: ForecastDay) => {
            Column({ space: 7 }) {
              Text(day.week ?? day.date ?? '--').fontWeight(FontWeight.Medium);
              Text(day.weather_day ?? '--').fontSize(AhuTypography.label);
              Text(`${this.number(day.temp_min)}° / ${this.number(day.temp_max)}°`).fontSize(AhuTypography.label);
            }.width(116).padding(14).backgroundColor(AhuColors.card).borderRadius(20);
          }, (day: ForecastDay, index: number) => `${day.date ?? ''}:${index}`); } }
            .scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).padding({ left: 16, right: 16 });
        }
        if (this.weather.aqi !== undefined) {
          AhuInsetCard() { Row() {
            Column({ space: 5 }) { Text('空气质量').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold);
              Text(this.weather.aqi_category ?? '--').fontColor(AhuColors.onSurfaceSecondary); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
            Text(`${this.weather.aqi}`).fontSize(38).fontWeight(FontWeight.Bold).fontColor(AhuColors.primaryAction);
          }.width('100%'); }
        }
        if (this.weather.hourly_forecast && this.weather.hourly_forecast.length > 0) {
          Text('逐小时预报').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold).padding({ left: 18, right: 18 });
          Scroll() { Row({ space: 10 }) { ForEach(this.weather.hourly_forecast, (hour: HourlyForecast) => {
            Column({ space: 6 }) { Text(hour.time?.slice(-5) ?? '--'); Text(`${this.number(hour.temperature)}°`).fontWeight(FontWeight.Bold);
              Text(hour.weather ?? '--').fontSize(AhuTypography.label); Text(`降水 ${this.number(hour.pop, '%')}`).fontSize(AhuTypography.label); }
              .width(94).padding(12).backgroundColor(AhuColors.card).borderRadius(18);
          }, (hour: HourlyForecast, index: number) => `${hour.time ?? ''}:${index}`); } }
            .scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).padding({ left: 16, right: 16 });
        }
        if (this.lifeIndices(this.weather).length > 0) {
          Text('生活指数').fontSize(AhuTypography.sectionTitle).fontWeight(FontWeight.Bold).padding({ left: 18, right: 18 });
          Grid() { ForEach(this.lifeIndices(this.weather), (item: NamedLifeIndex) => { GridItem() {
            Column({ space: 5 }) { Text(item.name).fontWeight(FontWeight.Bold); Text(item.value?.brief ?? item.value?.level ?? '--')
              .fontSize(AhuTypography.label).fontColor(AhuColors.onSurfaceSecondary).maxLines(2); }
              .width('100%').height(86).padding(12).backgroundColor(AhuColors.card).borderRadius(18).alignItems(HorizontalAlign.Start);
          } }, (item: NamedLifeIndex) => item.name); }.columnsTemplate('1fr 1fr').columnsGap(10).rowsGap(10)
            .padding({ left: 16, right: 16 });
        }
        if (this.error.length > 0) Text(`当前显示缓存：${this.error}`).fontSize(AhuTypography.label)
          .fontColor(AhuColors.error).padding({ left: 18, right: 18 });
      }
    }
  }
}
