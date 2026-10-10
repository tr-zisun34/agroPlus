import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../chat/chat_screen.dart';
import 'farm_provider.dart';
import 'recommendation_history_screen.dart';

class RecommendationCard extends StatefulWidget {
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
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard> {
  bool _isRevealed = false;

  @override
  void didUpdateWidget(covariant RecommendationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recommendation?.id != widget.recommendation?.id) {
      _isRevealed = false;
    }
  }

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
            if (widget.recommendation?.isComplete ?? false)
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RecommendationHistoryScreen(farmId: widget.farmId),
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
                      builder: (_) => ChatScreen(farmId: widget.farmId, farmName: widget.farmName),
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
    final recommendation = widget.recommendation;

    if (recommendation == null || !recommendation.isComplete) {
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

    if (recommendation.topCrops.isEmpty) {
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

    if (!_isRevealed) {
      return Center(
        child: FilledButton.icon(
          onPressed: () => setState(() => _isRevealed = true),
          icon: const Icon(Icons.eco_outlined, size: 18),
          label: Text(l10n.bestCropsButton),
        ),
      );
    }

    final showProfitNote = recommendation.topCrops.any((crop) => crop.yieldEstimate == null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final crop in recommendation.topCrops) _CropRow(crop: crop),
        if (showProfitNote) ...[
          const SizedBox(height: 8),
          Text(
            l10n.profitComingSoonNote,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _CropRow extends StatelessWidget {
  const _CropRow({required this.crop});

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
