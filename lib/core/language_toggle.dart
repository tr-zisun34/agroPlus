import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import 'locale_provider.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final isBangla = localeProvider.locale.languageCode == 'bn';

    return Tooltip(
      message: AppLocalizations.of(context)!.languageToggleTooltip,
      child: TextButton(
        onPressed: () => context.read<LocaleProvider>().toggleLocale(),
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 18),
            const SizedBox(width: 6),
            Text(
              isBangla ? 'বাং' : 'EN',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
