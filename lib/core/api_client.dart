import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'secure_storage.dart';

String _resolveBaseUrl() {
  if (kIsWeb) return 'http://localhost:8000';
  if (Platform.isAndroid) return 'http://10.0.2.2:8000';
  return 'http://localhost:8000';
}

class ApiClient {
  ApiClient._() : dio = Dio(BaseOptions(baseUrl: _resolveBaseUrl())) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.instance.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final isRefreshCall = error.requestOptions.path == '/auth/refresh';

          if (isUnauthorized && !isRefreshCall) {
            final newAccessToken = await _tryRefreshAccessToken();
            if (newAccessToken != null) {
              final retryOptions = error.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              try {
                final response = await dio.fetch(retryOptions);
                return handler.resolve(response);
              } on DioException catch (retryError) {
                return handler.next(retryError);
              }
            }
            await SecureStorage.instance.clear();
          }

          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();

  final Dio dio;

  Future<String?> _tryRefreshAccessToken() async {
    final refreshToken = await SecureStorage.instance.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final plainDio = Dio(BaseOptions(baseUrl: _resolveBaseUrl()));
      final response = await plainDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final newAccessToken = response.data['access_token'] as String;
      await SecureStorage.instance.saveAccessToken(newAccessToken);
      return newAccessToken;
    } on DioException {
      return null;
    }
  }
}
