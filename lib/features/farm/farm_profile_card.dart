import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../dashboard/farm_provider.dart';

class FarmProfileCard extends StatelessWidget {
  const FarmProfileCard({super.key, required this.farm});

  final Farm farm;

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
            Text(l10n.farmProfileTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _InfoRow(label: l10n.farmNameLabel, value: farm.farmName),
            _InfoRow(label: l10n.locationLabel, value: farm.location),
            _InfoRow(label: l10n.districtLabel, value: farm.district.name),
            _InfoRow(label: l10n.areaLabel, value: '${farm.sizeAcres}'),
            _InfoRow(label: l10n.soilTypeLabel, value: farm.soilType),
            _InfoRow(label: l10n.waterAvailabilityLabel, value: farm.waterAvailability),
            _InfoRow(label: l10n.budgetLabel, value: '${farm.budget}'),
            _InfoRow(label: l10n.targetSeasonLabel, value: farm.targetSeason),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
