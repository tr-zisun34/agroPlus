import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import '../dashboard/farm_provider.dart' show Farm;

class Conditions {
  const Conditions({
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.fetchedAt,
  });

  final double temperature;
  final double humidity;
  final double rainfall;
  final DateTime fetchedAt;

  factory Conditions.fromJson(Map<String, dynamic> json) {
    return Conditions(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      rainfall: (json['rainfall'] as num).toDouble(),
      fetchedAt: DateTime.parse(json['fetched_at'] as String),
    );
  }
}

class ForecastDay {
  const ForecastDay({
    required this.date,
    required this.tempMaxC,
    required this.tempMinC,
    required this.precipitationMm,
  });

  final String date;
  final double tempMaxC;
  final double tempMinC;
  final double precipitationMm;

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    return ForecastDay(
      date: json['date'] as String,
      tempMaxC: (json['temp_max_c'] as num).toDouble(),
      tempMinC: (json['temp_min_c'] as num).toDouble(),
      precipitationMm: (json['precipitation_mm'] as num).toDouble(),
    );
  }
}

class SoilPoint {
  const SoilPoint({required this.pointLabel, required this.n, required this.p, required this.k, required this.ph});

  final String pointLabel;
  final double n;
  final double p;
  final double k;
  final double ph;

  factory SoilPoint.fromJson(Map<String, dynamic> json) {
    return SoilPoint(
      pointLabel: json['point_label'] as String,
      n: (json['n'] as num).toDouble(),
      p: (json['p'] as num).toDouble(),
      k: (json['k'] as num).toDouble(),
      ph: (json['ph'] as num).toDouble(),
    );
  }
}

class RecommendedCrop {
  const RecommendedCrop({
    required this.rank,
    required this.crop,
    required this.confidence,
    this.yieldEstimate,
    this.netProfit,
    this.totalCost,
  });

  final int rank;
  final String crop;
  final double confidence;
  final double? yieldEstimate;
  final double? netProfit;
  final double? totalCost;

  factory RecommendedCrop.fromJson(Map<String, dynamic> json) {
    return RecommendedCrop(
      rank: json['rank'] as int,
      crop: json['crop'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      yieldEstimate: (json['yield_estimate'] as num?)?.toDouble(),
      netProfit: (json['net_profit'] as num?)?.toDouble(),
      totalCost: (json['total_cost'] as num?)?.toDouble(),
    );
  }
}

class Recommendation {
  const Recommendation({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.points,
    required this.topCrops,
    this.compositeN,
    this.compositeP,
    this.compositeK,
    this.compositePh,
  });

  final String id;
  final String status;
  final DateTime createdAt;
  final List<SoilPoint> points;
  final List<RecommendedCrop> topCrops;
  final double? compositeN;
  final double? compositeP;
  final double? compositeK;
  final double? compositePh;

  bool get isComplete => status == 'complete';

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      points: (json['points'] as List)
          .map((item) => SoilPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
      topCrops: (json['top_crops'] as List)
          .map((item) => RecommendedCrop.fromJson(item as Map<String, dynamic>))
          .toList(),
      compositeN: (json['composite_n'] as num?)?.toDouble(),
      compositeP: (json['composite_p'] as num?)?.toDouble(),
      compositeK: (json['composite_k'] as num?)?.toDouble(),
      compositePh: (json['composite_ph'] as num?)?.toDouble(),
    );
  }
}

class FarmDetailProvider extends ChangeNotifier {
  FarmDetailProvider(this.farmId);

  final String farmId;

  bool isLoadingFarm = true;
  String? farmErrorMessage;
  Farm? farm;

  bool isLoadingConditions = true;
  String? conditionsErrorMessage;
  Conditions? conditions;

  bool isLoadingRecommendation = true;
  String? recommendationErrorMessage;
  Recommendation? recommendation;

  bool isLoadingForecast = true;
  String? forecastErrorMessage;
  List<ForecastDay> forecast = [];

  bool get isReady => !isLoadingFarm && !isLoadingConditions;

  Future<void> initialize() async {
    await loadFarm();
    if (farm != null) {
      await Future.wait([loadConditions(), loadRecommendation(), loadForecast()]);
    } else {
      isLoadingConditions = false;
      isLoadingRecommendation = false;
      isLoadingForecast = false;
      notifyListeners();
    }
  }

  Future<void> loadFarm() async {
    isLoadingFarm = true;
    farmErrorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.instance.dio.get('/farms/$farmId');
      farm = Farm.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      farmErrorMessage = 'farmDetailLoadError';
    }

    isLoadingFarm = false;
    notifyListeners();
  }

  Future<void> loadConditions() async {
    isLoadingConditions = true;
    conditionsErrorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.instance.dio.get('/farms/$farmId/conditions');
      conditions = Conditions.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      conditionsErrorMessage = 'conditionsLoadError';
    }

    isLoadingConditions = false;
    notifyListeners();
  }

  Future<void> loadForecast() async {
    isLoadingForecast = true;
    forecastErrorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.instance.dio.get('/farms/$farmId/forecast');
      forecast = (response.data as List)
          .map((item) => ForecastDay.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException {
      forecastErrorMessage = 'forecastLoadError';
    }

    isLoadingForecast = false;
    notifyListeners();
  }

  Future<void> loadRecommendation() async {
    isLoadingRecommendation = true;
    recommendationErrorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.instance.dio.get('/farms/$farmId/recommendations/current');
      recommendation = response.data == null
          ? null
          : Recommendation.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      recommendationErrorMessage = 'recommendationLoadError';
    }

    isLoadingRecommendation = false;
    notifyListeners();
  }

  Future<String?> savePoint({
    required String pointLabel,
    required double n,
    required double p,
    required double k,
    required double ph,
  }) async {
    try {
      final response = await ApiClient.instance.dio.put(
        '/farms/$farmId/recommendations/current/points/$pointLabel',
        data: {'n': n, 'p': p, 'k': k, 'ph': ph},
      );
      recommendation = Recommendation.fromJson(response.data as Map<String, dynamic>);
      notifyListeners();
      return null;
    } on DioException catch (e) {
      final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
      return detail?.toString() ?? 'savePointError';
    }
  }
}
