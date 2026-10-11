import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import 'farm_profile_card.dart';
import 'farm_provider.dart';
import 'live_conditions_card.dart';
import 'recommendation_card.dart';
import 'soil_reading_card.dart';
import 'weather_forecast_card.dart';

class FarmScreen extends StatelessWidget {
  const FarmScreen({super.key, required this.farmId, this.initialFarmName});

  final String farmId;
  final String? initialFarmName;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FarmDetailProvider(farmId)..initialize(),
      child: _FarmScreenBody(farmId: farmId, initialFarmName: initialFarmName),
    );
  }
}

class _FarmScreenBody extends StatelessWidget {
  const _FarmScreenBody({required this.farmId, this.initialFarmName});

  final String farmId;
  final String? initialFarmName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<FarmDetailProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(provider.farm?.farmName ?? initialFarmName ?? '')),
      body: provider.isLoadingFarm
          ? const Center(child: CircularProgressIndicator())
          : provider.farm == null
              ? Center(
                  child: Text(
                    provider.farmErrorMessage == 'farmDetailLoadError'
                        ? l10n.farmDetailLoadError
                        : provider.farmErrorMessage ?? '',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await provider.loadFarm();
                    await Future.wait([provider.loadConditions(), provider.loadRecommendation()]);
                  },
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      FarmProfileCard(farm: provider.farm!),
                      LiveConditionsCard(
                        isLoading: provider.isLoadingConditions,
                        errorMessage: provider.conditionsErrorMessage,
                        conditions: provider.conditions,
                        onRefresh: provider.loadConditions,
                      ),
                      WeatherForecastCard(
                        isLoading: provider.isLoadingForecast,
                        errorMessage: provider.forecastErrorMessage,
                        forecast: provider.forecast,
                      ),
                      SoilReadingCard(
                        farmId: farmId,
                        sizeAcres: provider.farm!.sizeAcres,
                        recommendation: provider.recommendation,
                      ),
                      RecommendationCard(
                        farmId: farmId,
                        farmName: provider.farm!.farmName,
                        recommendation: provider.recommendation,
                        budget: provider.farm!.budget,
                        croppingPattern: provider.farm!.croppingPattern,
                      ),
                    ],
                  ),
                ),
    );
  }
}
