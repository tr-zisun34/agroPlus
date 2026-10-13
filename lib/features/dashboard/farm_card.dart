import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'farm_provider.dart';

String _formatRelativeDate(AppLocalizations l10n, DateTime? date) {
  if (date == null) return l10n.noChecksYet;

  final difference = DateTime.now().difference(date);
  if (difference.inDays >= 1) {
    return l10n.daysAgo(difference.inDays);
  }
  if (difference.inHours >= 1) {
    return l10n.hoursAgo(difference.inHours);
  }
  return l10n.justNow;
}

class FarmCard extends StatelessWidget {
  const FarmCard({super.key, required this.farm, this.onTap, this.onDelete});

  final Farm farm;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.eco_outlined, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farm.farmName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${farm.district.name} · ${farm.sizeAcres} acres',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatRelativeDate(l10n, farm.lastRecommendationAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    tooltip: l10n.deleteFarmTooltip,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
