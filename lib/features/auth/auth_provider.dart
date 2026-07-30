import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import '../../core/secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isCheckingAuth = true;

  bool get isLoggedIn => _isLoggedIn;
  bool get isCheckingAuth => _isCheckingAuth;

  Future<void> checkAuthStatus() async {
    final token = await SecureStorage.instance.getAccessToken();
    _isLoggedIn = token != null;
    _isCheckingAuth = false;
    notifyListeners();
  }

  Future<String?> login({required String email, required String password}) async {
    try {
      final response = await ApiClient.instance.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      await _storeTokensAndSetLoggedIn(response.data);
      return null;
    } on DioException catch (e) {
      return _extractErrorMessage(e);
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await ApiClient.instance.dio.post(
        '/auth/register',
        data: {'name': name, 'email': email, 'phone': phone, 'password': password},
      );
      await _storeTokensAndSetLoggedIn(response.data);
      return null;
    } on DioException catch (e) {
      return _extractErrorMessage(e);
    }
  }

  Future<void> logout() async {
    await SecureStorage.instance.clear();
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> _storeTokensAndSetLoggedIn(Map<String, dynamic> data) async {
    await SecureStorage.instance.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    _isLoggedIn = true;
    notifyListeners();
  }

  String _extractErrorMessage(DioException e) {
    final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
    return detail?.toString() ?? 'Something went wrong. Please try again.';
  }
}
