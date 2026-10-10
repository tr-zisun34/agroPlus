import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import 'farm_provider.dart';

class WeatherForecastCard extends StatelessWidget {
  const WeatherForecastCard({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.forecast,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<ForecastDay> forecast;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!isLoading && errorMessage == null && forecast.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.forecastTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage != null)
              Text(
                errorMessage == 'forecastLoadError' ? l10n.forecastLoadError : errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: forecast.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 16),
                  itemBuilder: (context, index) => _ForecastDayColumn(day: forecast[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ForecastDayColumn extends StatelessWidget {
  const _ForecastDayColumn({required this.day});

  final ForecastDay day;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final weekday = DateFormat.E().format(DateTime.parse(day.date));

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(weekday, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Icon(Icons.wb_sunny_outlined, color: colorScheme.primary, size: 20),
        const SizedBox(height: 6),
        Text(
          '${day.tempMaxC.toStringAsFixed(0)}° / ${day.tempMinC.toStringAsFixed(0)}°',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grain_outlined, size: 12, color: colorScheme.outline),
            const SizedBox(width: 2),
            Text('${day.precipitationMm.toStringAsFixed(0)}mm', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
