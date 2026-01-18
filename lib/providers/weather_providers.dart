import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../models/weather.dart';
import '../repositories/weather_repository.dart';

/// Provider for WeatherRepository
final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  final double lat = double.tryParse(dotenv.env['WEATHER_LAT'] ?? '') ??
      AppConfig.defaultLatitude;
  final double lon = double.tryParse(dotenv.env['WEATHER_LON'] ?? '') ??
      AppConfig.defaultLongitude;

  return OpenMeteoWeatherRepository(latitude: lat, longitude: lon);
});

/// Provider for current weather summary
final weatherProvider = FutureProvider<WeatherSummary>((ref) async {
  final repository = ref.watch(weatherRepositoryProvider);
  return repository.getCurrentWeather();
});

/// Provider for detailed weather including forecast
final weatherDetailsProvider = FutureProvider<WeatherDetails>((ref) async {
  final repository = ref.watch(weatherRepositoryProvider);
  return repository.getWeatherDetails();
});

