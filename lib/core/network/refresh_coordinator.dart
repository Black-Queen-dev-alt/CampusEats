import 'package:campus_eats/core/network/api_client.dart';
import 'package:campus_eats/core/network/refresh_coordinator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:campus_eats/core/storage/secure_token_storage.dart';

class RefreshCoordinator {
  final Dio _dio;
  bool _isRefreshing = false;
  final List<Completer<void>> _waiting = [];

  RefreshCoordinator(this._dio);

  /// Called when a request receives a 401.
  /// Guarantees that only ONE refresh request is sent at a time.
  Future<void> refreshIfNeeded() async {
    if (_isRefreshing) {
      final completer = Completer<void>();
      _waiting.add(completer);
      return completer.future;
    }
    _isRefreshing = true;
    try {
      // Example endpoint – adapt to actual API.
      final response = await _dio.post('/auth/refresh');
      final newAccess = response.data['access_token'] as String?;
      final newRefresh = response.data['refresh_token'] as String?;
      final storage = SecureTokenStorage();
      if (newAccess != null) await storage.saveAccessToken(newAccess);
      if (newRefresh != null) await storage.saveRefreshToken(newRefresh);
      // Resolve all waiting futures.
      for (final c in _waiting) c.complete();
    } catch (e) {
      // On failure, clear session and propagate error.
      await SecureTokenStorage().clearAll();
      for (final c in _waiting) c.completeError(e);
      rethrow;
    } finally {
      _waiting.clear();
      _isRefreshing = false;
    }
  }
}
