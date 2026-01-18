import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../extensions/build_context_extensions.dart';
import '../../models/weather.dart';

/// Card widget to display weather information
class WeatherCard extends ConsumerWidget {
  const WeatherCard({
    required this.weather,
    super.key,
  });

  final AsyncValue<WeatherSummary> weather;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.appColors;

    return SizedBox(
      height: 140,
      child: Card(
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
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
          child: weather.when(
            data: (WeatherSummary w) => Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  w.isDay ? Icons.wb_sunny : Icons.nightlight,
                  size: 32,
                  color: appColors.primaryPurple,
                ),
                const SizedBox(height: 4),
                Text(
                  '${w.temperature.toStringAsFixed(0)}°F',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: appColors.primaryPurple,
                        height: 1.0,
                      ),
                ),
                Text(
                  w.description.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: appColors.primaryPurple,
                        height: 1.2,
                        fontSize: 9,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            loading: () => Center(
              child: CircularProgressIndicator(color: appColors.primaryPurple),
            ),
            error: (Object e, StackTrace st) => Center(
              child: Icon(
                Icons.error_outline,
                color: appColors.accentPink,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

