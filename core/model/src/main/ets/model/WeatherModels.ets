export interface WeatherResponse {
  province?: string; city?: string; district?: string; adcode?: string; weather?: string; weather_icon?: string;
  temperature?: number; wind_direction?: string; wind_power?: string; humidity?: number; report_time?: string;
  feels_like?: number; visibility?: number; pressure?: number; uv?: number; precipitation?: number; cloud?: number;
  aqi?: number; aqi_level?: number; aqi_category?: string; aqi_primary?: string;
  air_pollutants?: AirPollutants; alerts?: Array<WeatherAlert>; temp_max?: number; temp_min?: number;
  forecast?: Array<ForecastDay>; hourly_forecast?: Array<HourlyForecast>; life_indices?: LifeIndices;
}

export interface AirPollutants { pm25?: number; pm10?: number; o3?: number; no2?: number; so2?: number; co?: number; }
export interface WeatherAlert { title?: string; type?: string; level?: string; text?: string; publish_time?: string; publisher?: string; guidance?: Array<string>; }
export interface ForecastDay {
  date?: string; week?: string; temp_max?: number; temp_min?: number; weather_day?: string; weather_night?: string;
  wind_dir_day?: string; wind_dir_night?: string; wind_scale_day?: string; wind_scale_night?: string;
  wind_speed_day?: number; humidity?: number; precip?: number; visibility?: number; uv_index?: number;
  sunrise?: string; sunset?: string;
}
export interface HourlyForecast {
  time?: string; temperature?: number; weather?: string; wind_direction?: string; wind_speed?: number;
  wind_scale?: string; humidity?: number; precip?: number; feels_like?: number; visibility?: number; pop?: number; uv_index?: number;
}
export interface LifeIndexItem { level?: string; brief?: string; advice?: string; }
export interface LifeIndices {
  clothing?: LifeIndexItem; uv?: LifeIndexItem; car_wash?: LifeIndexItem; drying?: LifeIndexItem;
  air_conditioner?: LifeIndexItem; cold_risk?: LifeIndexItem; exercise?: LifeIndexItem; comfort?: LifeIndexItem;
  travel?: LifeIndexItem; fishing?: LifeIndexItem; allergy?: LifeIndexItem; sunscreen?: LifeIndexItem;
  mood?: LifeIndexItem; beer?: LifeIndexItem; umbrella?: LifeIndexItem; traffic?: LifeIndexItem;
  air_purifier?: LifeIndexItem; pollen?: LifeIndexItem;
}
