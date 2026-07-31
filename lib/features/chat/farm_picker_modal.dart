import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../dashboard/farm_provider.dart';
import 'chat_screen.dart';

Future<void> showFarmPickerModal(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const FarmPickerModal(),
  );
}

class FarmPickerModal extends StatelessWidget {
  const FarmPickerModal({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final farms = context.watch<FarmProvider>().farms;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.farmPickerTitle, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(l10n.farmPickerSubtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: farms.length,
                itemBuilder: (context, index) {
                  final farm = farms[index];
                  return _FarmPickerTile(
                    farm: farm,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(farmId: farm.id, farmName: farm.farmName),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmPickerTile extends StatelessWidget {
  const _FarmPickerTile({required this.farm, required this.onTap});

  final Farm farm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Icon(Icons.eco_outlined, color: colorScheme.onPrimaryContainer),
      ),
      title: Text(farm.farmName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${farm.district.name} · ${farm.sizeAcres} acres'),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
