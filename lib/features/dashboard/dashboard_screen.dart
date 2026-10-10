import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/language_toggle.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';
import '../chat/farm_picker_modal.dart';
import '../farm/farm_screen.dart';
import 'add_farm_modal.dart';
import 'farm_card.dart';
import 'farm_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoadingFarmer = true;
  String? _farmerName;
  String? _farmerErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadFarmer();
    // Deferred to a microtask: loadFarms() calls notifyListeners() before its first await,
    // and this screen can mount mid-build (e.g. right after login, inside Consumer<AuthProvider>),
    // which would otherwise trip "setState() called during build".
    Future.microtask(() {
      if (!mounted) return;
      context.read<FarmProvider>().loadFarms();
    });
  }

  Future<void> _loadFarmer() async {
    try {
      final response = await ApiClient.instance.dio.get('/farmers/me');
      setState(() {
        _farmerName = response.data['name'] as String;
        _isLoadingFarmer = false;
      });
    } on DioException {
      if (!mounted) return;
      setState(() {
        _farmerErrorMessage = AppLocalizations.of(context)!.profileLoadError;
        _isLoadingFarmer = false;
      });
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _confirmAndDeleteFarm(Farm farm) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteFarmTitle),
        content: Text(l10n.deleteFarmContent(farm.farmName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final error = await context.read<FarmProvider>().deleteFarm(farm.id);
    if (!mounted || error == null) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoadingFarmer ? l10n.dashboardTitle : (_farmerName ?? l10n.dashboardTitle)),
        actions: [
          const LanguageToggle(),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: l10n.logoutTooltip,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(l10n),
          Positioned(
            left: 16,
            bottom: 16,
            child: Consumer<FarmProvider>(
              builder: (context, farmProvider, _) => FloatingActionButton.extended(
                heroTag: 'chatWithAgentFab',
                onPressed: farmProvider.farms.isEmpty ? null : () => showFarmPickerModal(context),
                icon: const Icon(Icons.smart_toy_outlined),
                label: Text(l10n.chatWithAgentButton),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              heroTag: 'addFarmFab',
              onPressed: () => showAddFarmModal(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.addFarm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoadingFarmer) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_farmerErrorMessage != null) {
      return Center(child: Text(_farmerErrorMessage!));
    }

    return Consumer<FarmProvider>(
      builder: (context, farmProvider, _) {
        if (farmProvider.isLoadingFarms) {
          return const Center(child: CircularProgressIndicator());
        }

        if (farmProvider.farmsErrorMessage != null) {
          return Center(child: Text(farmProvider.farmsErrorMessage!));
        }

        if (farmProvider.farms.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.agriculture_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    l10n.emptyFarmsMessage,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: farmProvider.refresh,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: farmProvider.farms.length,
            itemBuilder: (context, index) {
              final farm = farmProvider.farms[index];
              return FarmCard(
                farm: farm,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FarmScreen(farmId: farm.id, initialFarmName: farm.farmName),
                    ),
                  );
                },
                onDelete: () => _confirmAndDeleteFarm(farm),
              );
            },
          ),
        );
      },
    );
  }
}
