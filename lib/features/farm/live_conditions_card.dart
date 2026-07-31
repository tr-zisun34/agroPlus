import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'farm_provider.dart';

String _formatLastUpdated(AppLocalizations l10n, DateTime fetchedAt) {
  final difference = DateTime.now().difference(fetchedAt);
  if (difference.inMinutes < 1) return l10n.justNow;
  if (difference.inMinutes < 60) return l10n.minutesAgo(difference.inMinutes);
  return l10n.hoursAgo(difference.inHours);
}

class LiveConditionsCard extends StatelessWidget {
  const LiveConditionsCard({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.conditions,
    required this.onRefresh,
  });

  final bool isLoading;
  final String? errorMessage;
  final Conditions? conditions;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l10n.liveConditionsTitle, style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(
                  onPressed: isLoading ? null : onRefresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: l10n.refreshTooltip,
                ),
              ],
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  errorMessage == 'conditionsLoadError' ? l10n.conditionsLoadError : errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
            else if (conditions != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ConditionValue(
                    icon: Icons.thermostat_outlined,
                    label: l10n.temperatureLabel,
                    value: '${conditions!.temperature.toStringAsFixed(1)}°C',
                  ),
                  _ConditionValue(
                    icon: Icons.water_drop_outlined,
                    label: l10n.humidityLabel,
                    value: '${conditions!.humidity.toStringAsFixed(0)}%',
                  ),
                  _ConditionValue(
                    icon: Icons.grain_outlined,
                    label: l10n.rainfallLabel,
                    value: '${conditions!.rainfall.toStringAsFixed(1)} mm',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.lastUpdatedLabel(_formatLastUpdated(l10n, conditions!.fetchedAt)),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConditionValue extends StatelessWidget {
  const _ConditionValue({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
