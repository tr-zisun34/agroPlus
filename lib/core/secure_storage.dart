import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();

  static final SecureStorage instance = SecureStorage._();

  final _storage = const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _languageCodeKey = 'language_code';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> saveAccessToken(String accessToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> saveLanguageCode(String languageCode) async {
    await _storage.write(key: _languageCodeKey, value: languageCode);
  }

  Future<String?> getLanguageCode() => _storage.read(key: _languageCodeKey);
}
