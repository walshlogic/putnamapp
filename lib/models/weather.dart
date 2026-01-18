/// Represents current weather summary
class WeatherSummary {
  WeatherSummary({
    required this.temperature,
    required this.isDay,
    required this.description,
  });

  final double temperature; // Fahrenheit
  final bool isDay;
  final String description;
}

/// Represents a daily weather forecast
class DailyForecast {
  DailyForecast({
    required this.date,
    required this.temperatureMax,
    required this.temperatureMin,
    required this.weatherCode,
    required this.description,
  });

  final DateTime date;
  final double temperatureMax;
  final double temperatureMin;
  final int weatherCode;
  final String description;
}

/// Represents detailed weather information including forecast
class WeatherDetails {
  WeatherDetails({
    required this.current,
    required this.forecast,
  });

  final WeatherSummary current;
  final List<DailyForecast> forecast;
}

