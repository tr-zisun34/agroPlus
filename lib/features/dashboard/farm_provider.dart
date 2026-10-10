import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';

class District {
  const District({required this.id, required this.name});

  final String id;
  final String name;

  factory District.fromJson(Map<String, dynamic> json) {
    return District(id: json['id'] as String, name: json['name'] as String);
  }
}

class Farm {
  const Farm({
    required this.id,
    required this.farmName,
    required this.location,
    required this.district,
    required this.sizeAcres,
    required this.soilType,
    required this.waterAvailability,
    required this.budget,
    required this.targetSeason,
    required this.createdAt,
    this.lastRecommendationAt,
  });

  final String id;
  final String farmName;
  final String location;
  final District district;
  final double sizeAcres;
  final String soilType;
  final String waterAvailability;
  final double budget;
  final String targetSeason;
  final DateTime createdAt;
  final DateTime? lastRecommendationAt;

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'] as String,
      farmName: json['farm_name'] as String,
      location: json['location'] as String,
      district: District.fromJson(json['district'] as Map<String, dynamic>),
      sizeAcres: (json['size_acres'] as num).toDouble(),
      soilType: json['soil_type'] as String,
      waterAvailability: json['water_availability'] as String,
      budget: (json['budget'] as num).toDouble(),
      targetSeason: json['target_season'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastRecommendationAt: json['last_recommendation_at'] != null
          ? DateTime.parse(json['last_recommendation_at'] as String)
          : null,
    );
  }
}

class FarmProvider extends ChangeNotifier {
  bool isLoadingFarms = true;
  String? farmsErrorMessage;
  List<Farm> farms = [];

  bool areDistrictsLoaded = false;
  List<District> districts = [];

  Future<void> loadFarms() async {
    isLoadingFarms = true;
    farmsErrorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.instance.dio.get('/farms');
      farms = (response.data as List)
          .map((item) => Farm.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException {
      farmsErrorMessage = 'Could not load your farms.';
    }

    isLoadingFarms = false;
    notifyListeners();
  }

  Future<void> refresh() => loadFarms();

  Future<void> loadDistricts() async {
    if (areDistrictsLoaded) return;

    final response = await ApiClient.instance.dio.get('/districts');
    districts = (response.data as List)
        .map((item) => District.fromJson(item as Map<String, dynamic>))
        .toList();
    areDistrictsLoaded = true;
    notifyListeners();
  }

  Future<String?> addFarm({
    required String farmName,
    required String location,
    required String districtId,
    required double sizeAcres,
    required String soilType,
    required String waterAvailability,
    required double budget,
    required String targetSeason,
  }) async {
    try {
      await ApiClient.instance.dio.post(
        '/farms',
        data: {
          'farm_name': farmName,
          'location': location,
          'district_id': districtId,
          'size_acres': sizeAcres,
          'soil_type': soilType,
          'water_availability': waterAvailability,
          'budget': budget,
          'target_season': targetSeason,
        },
      );
      await refresh();
      return null;
    } on DioException catch (e) {
      final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
      return detail?.toString() ?? 'Could not add farm. Please try again.';
    }
  }

  Future<String?> updateFarm({
    required String farmId,
    required String farmName,
    required String location,
    required String districtId,
    required double sizeAcres,
    required String soilType,
    required String waterAvailability,
    required double budget,
    required String targetSeason,
  }) async {
    try {
      await ApiClient.instance.dio.patch(
        '/farms/$farmId',
        data: {
          'farm_name': farmName,
          'location': location,
          'district_id': districtId,
          'size_acres': sizeAcres,
          'soil_type': soilType,
          'water_availability': waterAvailability,
          'budget': budget,
          'target_season': targetSeason,
        },
      );
      await refresh();
      return null;
    } on DioException catch (e) {
      final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
      return detail?.toString() ?? 'Could not update farm. Please try again.';
    }
  }

  Future<String?> deleteFarm(String farmId) async {
    try {
      await ApiClient.instance.dio.delete('/farms/$farmId');
      farms = farms.where((farm) => farm.id != farmId).toList();
      notifyListeners();
      return null;
    } on DioException catch (e) {
      final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
      return detail?.toString() ?? 'Could not delete farm. Please try again.';
    }
  }
}
