import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../chat/chat_screen.dart';
import 'farm_provider.dart';
import 'recommendation_history_screen.dart';
import 'recommendation_list_screen.dart';

class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    super.key,
    required this.farmId,
    required this.farmName,
    required this.recommendation,
  });

  final String farmId;
  final String farmName;
  final Recommendation? recommendation;

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
            Text(l10n.recommendationTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildContent(context, l10n),
            if (recommendation?.isComplete ?? false)
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RecommendationHistoryScreen(farmId: farmId),
                      ),
                    );
                  },
                  child: Text(l10n.viewHistoryButton),
                ),
              ),
            const SizedBox(height: 8),
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(farmId: farmId, farmName: farmName),
                    ),
                  );
                },
                icon: const Icon(Icons.smart_toy_outlined, size: 18),
                label: Text(l10n.chatWithAgentButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;

    if (recommendation == null || !recommendation!.isComplete) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.insights_outlined, size: 48, color: colorScheme.outline),
            const SizedBox(height: 8),
            Text(
              l10n.recommendationDisabledHint,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (recommendation!.topCrops.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.hourglass_top_outlined, size: 48, color: colorScheme.outline),
            const SizedBox(height: 8),
            Text(
              l10n.recommendationPipelinePendingMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Center(
      child: FilledButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RecommendationListScreen(farmId: farmId, topCrops: recommendation!.topCrops),
            ),
          );
        },
        icon: const Icon(Icons.eco_outlined, size: 18),
        label: Text(l10n.bestCropsButton),
      ),
    );
  }
}
