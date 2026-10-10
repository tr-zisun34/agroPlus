import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';

class FertilizerLineItem {
  const FertilizerLineItem({required this.qtyKg, required this.priceBdtPerKg, required this.costBdt});

  final double qtyKg;
  final double priceBdtPerKg;
  final double costBdt;

  factory FertilizerLineItem.fromJson(Map<String, dynamic> json) {
    return FertilizerLineItem(
      qtyKg: (json['qty_kg'] as num).toDouble(),
      priceBdtPerKg: (json['price_bdt_per_kg'] as num).toDouble(),
      costBdt: (json['cost_bdt'] as num).toDouble(),
    );
  }
}

class CropEconomicsDetail {
  const CropEconomicsDetail({
    required this.crop,
    required this.yieldEstimate,
    required this.priceBdtPerKg,
    required this.grossRevenue,
    required this.totalCost,
    required this.netProfit,
    this.seedCost,
    this.fertilizerCost,
    this.fertilizerBreakdown,
    this.otherCost,
    this.seasonLabel,
  });

  final String crop;
  final double yieldEstimate;
  final double priceBdtPerKg;
  final double grossRevenue;
  final double totalCost;
  final double netProfit;
  final double? seedCost;
  final double? fertilizerCost;
  final Map<String, FertilizerLineItem>? fertilizerBreakdown;
  final double? otherCost;
  final String? seasonLabel;

  factory CropEconomicsDetail.fromJson(Map<String, dynamic> json) {
    final breakdownJson = json['fertilizer_breakdown'] as Map<String, dynamic>?;
    return CropEconomicsDetail(
      crop: json['crop'] as String,
      yieldEstimate: (json['yield_estimate'] as num).toDouble(),
      priceBdtPerKg: (json['price_bdt_per_kg'] as num).toDouble(),
      grossRevenue: (json['gross_revenue'] as num).toDouble(),
      totalCost: (json['total_cost'] as num).toDouble(),
      netProfit: (json['net_profit'] as num).toDouble(),
      seedCost: (json['seed_cost'] as num?)?.toDouble(),
      fertilizerCost: (json['fertilizer_cost'] as num?)?.toDouble(),
      fertilizerBreakdown: breakdownJson?.map(
        (key, value) => MapEntry(key, FertilizerLineItem.fromJson(value as Map<String, dynamic>)),
      ),
      otherCost: (json['other_cost'] as num?)?.toDouble(),
      seasonLabel: json['season_label'] as String?,
    );
  }
}

class CropDetailProvider extends ChangeNotifier {
  CropDetailProvider(this.farmId, this.crop);

  final String farmId;
  final String crop;

  bool isLoading = true;
  String? errorMessage;
  CropEconomicsDetail? detail;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.instance.dio.get('/farms/$farmId/recommendations/current/crops/$crop');
      detail = CropEconomicsDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      errorMessage = 'cropDetailLoadError';
    }

    isLoading = false;
    notifyListeners();
  }
}
