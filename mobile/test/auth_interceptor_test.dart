import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_eats_mobile/core/network/auth_interceptor.dart';
import 'package:campus_eats_mobile/core/network/refresh_coordinator.dart';
import 'package:campus_eats_mobile/core/storage/secure_token_storage.dart';

/// Stockage en mémoire (pas de plugin natif dans les tests).
class MemoryTokenStorage extends SecureTokenStorage {
  String? access;
  String? refresh;

  @override
  Future<void> saveAccessToken(String token) async => access = token;

  @override
  Future<void> saveRefreshToken(String token) async => refresh = token;

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> clearAll() async {
    access = null;
    refresh = null;
  }
}

/// Faux serveur : accepte uniquement le token "new-access".
class FakeServer implements HttpClientAdapter {
  int refreshCalls = 0;
  int refreshStatus = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/auth/refresh') {
      refreshCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (refreshStatus != 200) return _json(refreshStatus, _error('refus'));
      return _json(200, {
        'success': true,
        'data': {'accessToken': 'new-access', 'refreshToken': 'new-refresh'},
      });
    }
    if (options.headers['Authorization'] == 'Bearer new-access') {
      return _json(200, {'success': true});
    }
    return _json(401, _error('expiré'));
  }

  Map<String, Object?> _error(String message) => {
    'success': false,
    'error': {'code': 'UNAUTHORIZED', 'message': message, 'details': null},
  };

  ResponseBody _json(int status, Object body) {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late FakeServer server;
  late MemoryTokenStorage storage;
  late Dio dio;
  late int expiredCount;

  setUp(() async {
    server = FakeServer();
    storage = MemoryTokenStorage();
    await storage.saveAccessToken('old-access');
    await storage.saveRefreshToken('old-refresh');
    expiredCount = 0;

    final options = BaseOptions(baseUrl: 'http://test');
    final bareDio = Dio(options)..httpClientAdapter = server;
    dio = Dio(options)..httpClientAdapter = server;
    dio.interceptors.add(
      AuthInterceptor(
        storage: storage,
        dio: dio,
        refreshCoordinator: RefreshCoordinator(
          dio: bareDio,
          storage: storage,
          onSessionExpired: () => expiredCount++,
        ),
      ),
    );
  });

  test('trois 401 simultanés déclenchent UN seul refresh', () async {
    final responses = await Future.wait([
      dio.get<dynamic>('/menus'),
      dio.get<dynamic>('/orders'),
      dio.get<dynamic>('/me'),
    ]);

    expect(responses.map((r) => r.statusCode), [200, 200, 200]);
    expect(server.refreshCalls, 1);
    expect(await storage.readAccessToken(), 'new-access');
    // Rotation stricte de l'API : le nouveau refresh token est sauvegardé.
    expect(await storage.readRefreshToken(), 'new-refresh');
    expect(expiredCount, 0);
  });

  test('refresh refusé : session effacée et erreur remontée', () async {
    server.refreshStatus = 401;

    await expectLater(dio.get<dynamic>('/menus'), throwsA(isA<DioException>()));

    expect(await storage.readAccessToken(), isNull);
    expect(await storage.readRefreshToken(), isNull);
    expect(expiredCount, 1);
  });
}
