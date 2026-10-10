import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import 'farm_provider.dart' show RecommendedCrop;
import 'recommendation_history_screen.dart' show formatAbsoluteDate;
import 'recommendation_provider.dart';

class RecommendationDetailScreen extends StatelessWidget {
  const RecommendationDetailScreen({super.key, required this.farmId, required this.recommendationId});

  final String farmId;
  final String recommendationId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecommendationHistoryProvider(farmId)..loadDetail(recommendationId),
      child: const _RecommendationDetailBody(),
    );
  }
}

class _RecommendationDetailBody extends StatelessWidget {
  const _RecommendationDetailBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<RecommendationHistoryProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recommendationDetailTitle)),
      body: _buildBody(context, l10n, provider),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, RecommendationHistoryProvider provider) {
    if (provider.isLoadingDetail) {
      return const Center(child: CircularProgressIndicator());
    }

    final detail = provider.detail;
    if (detail == null) {
      return Center(
        child: Text(
          provider.detailErrorMessage == 'recommendationLoadError'
              ? l10n.recommendationLoadError
              : provider.detailErrorMessage ?? '',
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(formatAbsoluteDate(detail.createdAt), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.compositeReadingLabel, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'N ${detail.compositeN!.toStringAsFixed(1)} · '
                  'P ${detail.compositeP!.toStringAsFixed(1)} · '
                  'K ${detail.compositeK!.toStringAsFixed(1)} · '
                  'pH ${detail.compositePh!.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.recommendationTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final crop in detail.topCrops) _DetailCropRow(crop: crop),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailCropRow extends StatelessWidget {
  const _DetailCropRow({required this.crop});

  final RecommendedCrop crop;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cropName = crop.crop.isEmpty ? crop.crop : crop.crop[0].toUpperCase() + crop.crop.substring(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              '${crop.rank}',
              style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(cropName, style: Theme.of(context).textTheme.titleSmall),
          ),
          Text(
            '${(crop.confidence * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
