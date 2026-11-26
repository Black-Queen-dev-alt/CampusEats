import 'dart:async';

import 'package:dio/dio.dart';
import 'package:campus_eats_mobile/core/storage/secure_token_storage.dart';

/// Garantit qu'un SEUL appel /auth/refresh est en cours, même si
/// plusieurs requêtes reçoivent un 401 en même temps.
class RefreshCoordinator {
  RefreshCoordinator({
    required Dio dio,
    required SecureTokenStorage storage,
    this.onSessionExpired,
  }) : _dio = dio,
       _storage = storage;

  final Dio _dio;
  final SecureTokenStorage _storage;
  final void Function()? onSessionExpired;

  Future<bool>? _inFlight;

  /// Retourne true si un nouveau token est disponible.
  Future<bool> refresh() {
    return _inFlight ??= _doRefresh().whenComplete(() => _inFlight = null);
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) {
      onSessionExpired?.call();
      return false;
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      final access = data?['accessToken'] as String?;
      final refresh = data?['refreshToken'] as String?;
      if (access == null || refresh == null) {
        await _expire();
        return false;
      }
      // L'API fait une rotation stricte : on sauvegarde les DEUX tokens.
      await _storage.saveAccessToken(access);
      await _storage.saveRefreshToken(refresh);
      return true;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        await _expire();
      }
      // Autre erreur (réseau coupé...) : on garde la session, on échoue juste.
      return false;
    }
  }

  Future<void> _expire() async {
    await _storage.clearAll();
    onSessionExpired?.call();
  }
}
