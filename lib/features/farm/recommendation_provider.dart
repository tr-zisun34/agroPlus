import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import 'farm_provider.dart' show Recommendation;

class RecommendationSummary {
  const RecommendationSummary({
    required this.id,
    required this.createdAt,
    required this.topCrop,
    required this.topConfidence,
  });

  final String id;
  final DateTime createdAt;
  final String topCrop;
  final double topConfidence;

  factory RecommendationSummary.fromJson(Map<String, dynamic> json) {
    return RecommendationSummary(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      topCrop: json['top_crop'] as String,
      topConfidence: (json['top_confidence'] as num).toDouble(),
    );
  }
}

class RecommendationHistoryProvider extends ChangeNotifier {
  RecommendationHistoryProvider(this.farmId);

  final String farmId;

  bool isLoadingList = true;
  String? listErrorMessage;
  List<RecommendationSummary> summaries = [];

  bool isLoadingDetail = true;
  String? detailErrorMessage;
  Recommendation? detail;

  Future<void> loadList() async {
    isLoadingList = true;
    listErrorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.instance.dio.get('/farms/$farmId/recommendations');
      summaries = (response.data as List)
          .map((item) => RecommendationSummary.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException {
      listErrorMessage = 'recommendationLoadError';
    }

    isLoadingList = false;
    notifyListeners();
  }

  Future<void> loadDetail(String recommendationId) async {
    isLoadingDetail = true;
    detailErrorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.instance.dio.get('/farms/$farmId/recommendations/$recommendationId');
      detail = Recommendation.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      detailErrorMessage = 'recommendationLoadError';
    }

    isLoadingDetail = false;
    notifyListeners();
  }
}
