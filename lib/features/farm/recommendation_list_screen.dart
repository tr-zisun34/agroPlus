import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'crop_harvest_detail_screen.dart';
import 'farm_provider.dart' show RecommendedCrop;

class RecommendationListScreen extends StatelessWidget {
  const RecommendationListScreen({super.key, required this.farmId, required this.topCrops});

  final String farmId;
  final List<RecommendedCrop> topCrops;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recommendationListTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.selectCropHint,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (final crop in topCrops) _CropListTile(farmId: farmId, crop: crop),
        ],
      ),
    );
  }
}

class _CropListTile extends StatelessWidget {
  const _CropListTile({required this.farmId, required this.crop});

  final String farmId;
  final RecommendedCrop crop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final cropName = crop.crop.isEmpty ? crop.crop : crop.crop[0].toUpperCase() + crop.crop.substring(1);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            '${crop.rank}',
            style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(cropName, style: Theme.of(context).textTheme.titleMedium),
        subtitle: crop.netProfit != null
            ? Text('${l10n.netProfitLabel}: ${crop.netProfit!.toStringAsFixed(0)} BDT')
            : Text(l10n.profitComingSoonNote),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${(crop.confidence * 100).toStringAsFixed(0)}%'),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CropHarvestDetailScreen(farmId: farmId, crop: crop.crop),
            ),
          );
        },
      ),
    );
  }
}
