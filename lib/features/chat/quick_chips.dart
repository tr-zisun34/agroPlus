import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class QuickChips extends StatelessWidget {
  const QuickChips({super.key, required this.onChipTap});

  final ValueChanged<String> onChipTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final suggestions = [l10n.quickChipProfit, l10n.quickChipSoil, l10n.quickChipCrop];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ActionChip(
            label: Text(suggestion),
            onPressed: () => onChipTap(suggestion),
          );
        },
      ),
    );
  }
}
