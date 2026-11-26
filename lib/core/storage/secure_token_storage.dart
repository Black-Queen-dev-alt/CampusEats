import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) =>
      _secureStorage.write(key: 'access_token', value: token);

  Future<void> saveRefreshToken(String token) =>
      _secureStorage.write(key: 'refresh_token', value: token);

  Future<String?> readAccessToken() => _secureStorage.read(key: 'access_token');

  Future<String?> readRefreshToken() => _secureStorage.read(key: 'refresh_token');

  Future<void> clearAll() => _secureStorage.deleteAll();
}
