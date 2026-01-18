/// Utility class for mapping weather codes to descriptions
class WeatherCodeMapper {
  WeatherCodeMapper._(); // Private constructor to prevent instantiation

  /// Map a weather code to a human-readable description
  static String mapWeatherCode(int code) {
    if (code == 0) return 'Clear sky';
    if (<int>{1, 2, 3}.contains(code)) return 'Partly cloudy';
    if (<int>{45, 48}.contains(code)) return 'Fog';
    if (<int>{51, 53, 55, 61, 63, 65}.contains(code)) return 'Rain';
    if (<int>{71, 73, 75}.contains(code)) return 'Snow';
    if (<int>{95, 96, 99}.contains(code)) return 'Thunderstorm';
    return 'Weather code $code';
  }

  /// Get an icon name for a weather code
  static String getIconForCode(int code, {required bool isDay}) {
    if (code == 0) return isDay ? 'clear_day' : 'clear_night';
    if (<int>{1, 2, 3}.contains(code)) {
      return isDay ? 'partly_cloudy_day' : 'partly_cloudy_night';
    }
    if (<int>{45, 48}.contains(code)) return 'fog';
    if (<int>{51, 53, 55, 61, 63, 65}.contains(code)) return 'rain';
    if (<int>{71, 73, 75}.contains(code)) return 'snow';
    if (<int>{95, 96, 99}.contains(code)) return 'thunderstorm';
    return 'unknown';
  }
}

