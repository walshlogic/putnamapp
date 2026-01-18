import 'dart:convert';
import 'package:http/http.dart' as http;

import '../exceptions/app_exceptions.dart';
import '../models/weather.dart';
import '../utils/weather_code_mapper.dart';

/// Abstract repository for weather data operations
abstract class WeatherRepository {
  /// Fetch current weather summary
  Future<WeatherSummary> getCurrentWeather();

  /// Fetch detailed weather including forecast
  Future<WeatherDetails> getWeatherDetails();
}

/// Open-Meteo API implementation of WeatherRepository
class OpenMeteoWeatherRepository implements WeatherRepository {
  OpenMeteoWeatherRepository({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  Future<WeatherSummary> getCurrentWeather() async {
    try {
      final Uri uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,is_day,weather_code&temperature_unit=fahrenheit',
      );

      final http.Response response = await http.get(uri);

      if (response.statusCode != 200) {
        throw NetworkException.fromHttpStatus(response.statusCode);
      }

      final Map<String, dynamic> jsonBody =
          json.decode(response.body) as Map<String, dynamic>;
      final Map<String, dynamic> current =
          jsonBody['current'] as Map<String, dynamic>;

      final double temperature = (current['temperature_2m'] as num).toDouble();
      final bool isDay = (current['is_day'] as num) == 1;
      final int weatherCode = (current['weather_code'] as num).toInt();

      return WeatherSummary(
        temperature: temperature,
        isDay: isDay,
        description: WeatherCodeMapper.mapWeatherCode(weatherCode),
      );
    } on http.ClientException catch (e) {
      throw NetworkException('Network request failed: $e');
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw DataParsingException('Failed to parse weather data', e);
    }
  }

  @override
  Future<WeatherDetails> getWeatherDetails() async {
    try {
      final Uri uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,is_day,weather_code&daily=temperature_2m_max,temperature_2m_min,weather_code&temperature_unit=fahrenheit&timezone=auto&forecast_days=10',
      );

      final http.Response response = await http.get(uri);

      if (response.statusCode != 200) {
        throw NetworkException.fromHttpStatus(response.statusCode);
      }

      final Map<String, dynamic> jsonBody =
          json.decode(response.body) as Map<String, dynamic>;

      // Current weather
      final Map<String, dynamic> current =
          jsonBody['current'] as Map<String, dynamic>;
      final double temperature = (current['temperature_2m'] as num).toDouble();
      final bool isDay = (current['is_day'] as num) == 1;
      final int weatherCode = (current['weather_code'] as num).toInt();

      final WeatherSummary currentWeather = WeatherSummary(
        temperature: temperature,
        isDay: isDay,
        description: WeatherCodeMapper.mapWeatherCode(weatherCode),
      );

      // Daily forecast
      final Map<String, dynamic> daily =
          jsonBody['daily'] as Map<String, dynamic>;
      final List<dynamic> dates = daily['time'] as List<dynamic>;
      final List<dynamic> maxTemps =
          daily['temperature_2m_max'] as List<dynamic>;
      final List<dynamic> minTemps =
          daily['temperature_2m_min'] as List<dynamic>;
      final List<dynamic> codes = daily['weather_code'] as List<dynamic>;

      final List<DailyForecast> forecast = <DailyForecast>[];
      for (int i = 0; i < dates.length && i < 10; i++) {
        final DateTime date = DateTime.parse(dates[i] as String);
        final int code = (codes[i] as num).toInt();
        forecast.add(
          DailyForecast(
            date: date,
            temperatureMax: (maxTemps[i] as num).toDouble(),
            temperatureMin: (minTemps[i] as num).toDouble(),
            weatherCode: code,
            description: WeatherCodeMapper.mapWeatherCode(code),
          ),
        );
      }

      return WeatherDetails(current: currentWeather, forecast: forecast);
    } on http.ClientException catch (e) {
      throw NetworkException('Network request failed: $e');
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw DataParsingException('Failed to parse weather details', e);
    }
  }
}

