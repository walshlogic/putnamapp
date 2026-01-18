import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../extensions/build_context_extensions.dart';
import '../models/weather.dart';
import '../providers/weather_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';

class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.appColors;
    final weatherDetails = ref.watch(weatherDetailsProvider);

    return Scaffold(
      appBar: const PutnamAppBar(showBackButton: true),
      drawer: const AppDrawer(),
      endDrawer: const SettingsDrawer(),
      body: Column(
        children: <Widget>[
          Expanded(
            child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weatherDetailsProvider);
        },
        child: weatherDetails.when(
          data: (WeatherDetails details) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                // Current weather
                Card(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          appColors.weatherGradientStart.withValues(alpha: 0.3),
                          appColors.weatherGradientEnd.withValues(alpha: 0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: <Widget>[
                        Icon(
                          details.current.isDay ? Icons.wb_sunny : Icons.nightlight,
                          size: 80,
                          color: appColors.primaryPurple,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${details.current.temperature.toStringAsFixed(0)}°F',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: appColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          details.current.description.toUpperCase(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: appColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '10-DAY FORECAST',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                // Forecast list
                ...details.forecast.map((DailyForecast day) {
                  final String dayName = DateFormat('EEE, MMM d').format(day.date);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: appColors.lightPurple,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getWeatherIcon(day.weatherCode),
                              size: 28,
                              color: appColors.primaryPurple,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  dayName,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  day.description.toUpperCase(),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: appColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${day.temperatureMax.toStringAsFixed(0)}° / ${day.temperatureMin.toStringAsFixed(0)}°',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: appColors.primaryPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.error_outline, size: 48, color: appColors.accentPink),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load weather: $e',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ),
            ),
          ),
        ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (<int>{1, 2, 3}.contains(code)) return Icons.wb_cloudy;
    if (<int>{45, 48}.contains(code)) return Icons.cloud;
    if (<int>{51, 53, 55, 61, 63, 65}.contains(code)) return Icons.water_drop;
    if (<int>{71, 73, 75}.contains(code)) return Icons.ac_unit;
    if (<int>{95, 96, 99}.contains(code)) return Icons.thunderstorm;
    return Icons.wb_cloudy;
  }
}

