import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import 'recommendation_detail_screen.dart';
import 'recommendation_provider.dart';

String formatAbsoluteDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class RecommendationHistoryScreen extends StatelessWidget {
  const RecommendationHistoryScreen({super.key, required this.farmId});

  final String farmId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecommendationHistoryProvider(farmId)..loadList(),
      child: _RecommendationHistoryBody(farmId: farmId),
    );
  }
}

class _RecommendationHistoryBody extends StatelessWidget {
  const _RecommendationHistoryBody({required this.farmId});

  final String farmId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<RecommendationHistoryProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recommendationHistoryTitle)),
      body: _buildBody(context, l10n, provider),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, RecommendationHistoryProvider provider) {
    if (provider.isLoadingList) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.listErrorMessage != null) {
      return Center(
        child: Text(
          provider.listErrorMessage == 'recommendationLoadError'
              ? l10n.recommendationLoadError
              : provider.listErrorMessage!,
        ),
      );
    }

    if (provider.summaries.isEmpty) {
      return Center(child: Text(l10n.noHistoryMessage));
    }

    return ListView.builder(
      itemCount: provider.summaries.length,
      itemBuilder: (context, index) {
        final summary = provider.summaries[index];
        final cropName =
            summary.topCrop.isEmpty ? summary.topCrop : summary.topCrop[0].toUpperCase() + summary.topCrop.substring(1);

        return ListTile(
          leading: const Icon(Icons.eco_outlined),
          title: Text(cropName),
          subtitle: Text(formatAbsoluteDate(summary.createdAt)),
          trailing: Text('${(summary.topConfidence * 100).toStringAsFixed(0)}%'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RecommendationDetailScreen(farmId: farmId, recommendationId: summary.id),
              ),
            );
          },
        );
      },
    );
  }
}
