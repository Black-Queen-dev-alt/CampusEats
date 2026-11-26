import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Implémentation très simple de stockage sécurisé en mémoire (pour le
/// prototype). En production, utilisez `flutter_secure_storage`.
class SecureTokenStorage {
  final _storage = const FlutterSecureStorage();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  Future<void> saveAccessToken(String token) => _storage.write(key: _accessKey, value: token);
  Future<void> saveRefreshToken(String token) => _storage.write(key: _refreshKey, value: token);

  Future<void> clearAll() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
