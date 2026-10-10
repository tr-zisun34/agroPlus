import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import 'crop_detail_provider.dart';

const _fertilizerDisplayNames = {
  'urea': 'Urea',
  'tsp': 'TSP',
  'dap': 'DAP',
  'mop': 'MoP',
  'gypsum': 'Gypsum',
  'zinc': 'Zinc',
};

class CropHarvestDetailScreen extends StatelessWidget {
  const CropHarvestDetailScreen({super.key, required this.farmId, required this.crop});

  final String farmId;
  final String crop;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CropDetailProvider(farmId, crop)..load(),
      child: _CropHarvestDetailBody(crop: crop),
    );
  }
}

class _CropHarvestDetailBody extends StatelessWidget {
  const _CropHarvestDetailBody({required this.crop});

  final String crop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<CropDetailProvider>();
    final cropName = crop.isEmpty ? crop : crop[0].toUpperCase() + crop.substring(1);

    return Scaffold(
      appBar: AppBar(title: Text(cropName)),
      body: _buildBody(context, l10n, provider),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, CropDetailProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final detail = provider.detail;
    if (detail == null) {
      return Center(
        child: Text(
          provider.errorMessage == 'cropDetailLoadError' ? l10n.cropDetailLoadError : provider.errorMessage ?? '',
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (detail.seasonLabel != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.growingSeasonLabel, style: Theme.of(context).textTheme.bodySmall),
                        Text(detail.seasonLabel!, style: Theme.of(context).textTheme.titleSmall),
                      ],
                    ),
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
                Text(l10n.yieldAndCostTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _DetailRow(label: l10n.yieldEstimateLabel, value: '${detail.yieldEstimate.toStringAsFixed(0)} kg'),
                _DetailRow(label: l10n.marketPriceLabel, value: '${detail.priceBdtPerKg.toStringAsFixed(2)} BDT/kg'),
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
                Text(l10n.costBreakdownTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (detail.seedCost != null)
                  _DetailRow(label: l10n.seedCostLabel, value: '${detail.seedCost!.toStringAsFixed(0)} BDT')
                else
                  _UnavailableNote(text: l10n.seedCostUnavailableNote),
                if (detail.fertilizerCost != null) ...[
                  _DetailRow(
                    label: l10n.fertilizerCostLabel,
                    value: '${detail.fertilizerCost!.toStringAsFixed(0)} BDT',
                  ),
                  if (detail.fertilizerBreakdown != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final entry in detail.fertilizerBreakdown!.entries)
                            _FertilizerItemRow(fertilizerKey: entry.key, item: entry.value),
                        ],
                      ),
                    ),
                ] else
                  _UnavailableNote(text: l10n.fertilizerCostUnavailableNote),
                if (detail.otherCost != null)
                  _DetailRow(label: l10n.otherCostLabel, value: '${detail.otherCost!.toStringAsFixed(0)} BDT'),
                const Divider(height: 24),
                _DetailRow(label: l10n.totalCostLabel, value: '${detail.totalCost.toStringAsFixed(0)} BDT', emphasize: true),
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
                Text(l10n.profitEstimateTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _DetailRow(label: l10n.grossRevenueLabel, value: '${detail.grossRevenue.toStringAsFixed(0)} BDT'),
                _DetailRow(label: l10n.totalCostLabel, value: '- ${detail.totalCost.toStringAsFixed(0)} BDT'),
                const Divider(height: 24),
                _DetailRow(
                  label: l10n.netProfitLabel,
                  value: '${detail.netProfit.toStringAsFixed(0)} BDT',
                  emphasize: true,
                  isNegative: detail.netProfit < 0,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FertilizerItemRow extends StatelessWidget {
  const _FertilizerItemRow({required this.fertilizerKey, required this.item});

  final String fertilizerKey;
  final FertilizerLineItem item;

  @override
  Widget build(BuildContext context) {
    final name = _fertilizerDisplayNames[fertilizerKey] ?? fertilizerKey;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$name · ${item.qtyKg.toStringAsFixed(1)} kg × ${item.priceBdtPerKg.toStringAsFixed(2)} BDT/kg',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text('${item.costBdt.toStringAsFixed(0)} BDT', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _UnavailableNote extends StatelessWidget {
  const _UnavailableNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.emphasize = false, this.isNegative = false});

  final String label;
  final String value;
  final bool emphasize;
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final valueStyle = emphasize
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isNegative ? colorScheme.error : colorScheme.primary,
            )
        : Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
