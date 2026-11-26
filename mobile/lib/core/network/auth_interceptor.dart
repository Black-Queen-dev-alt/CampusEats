import 'package:dio/dio.dart';
import 'package:campus_eats_mobile/core/network/refresh_coordinator.dart';
import 'package:campus_eats_mobile/core/storage/secure_token_storage.dart';

/// Ajoute le token aux requêtes, et sur 401 : refresh puis nouvelle tentative.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.storage,
    required this.refreshCoordinator,
    required this.dio,
  });

  final SecureTokenStorage storage;
  final RefreshCoordinator refreshCoordinator;
  final Dio dio;

  static const _retriedKey = 'auth_retried';

  bool _isAuthRoute(String path) => path.startsWith('/auth/');

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isAuthRoute(options.path)) {
      final token = await storage.readAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final is401 = err.response?.statusCode == 401;

    if (!is401 ||
        _isAuthRoute(request.path) ||
        request.extra[_retriedKey] == true) {
      return handler.next(err);
    }

    // Un autre appel a peut-être déjà rafraîchi le token : on compare.
    final sentHeader = request.headers['Authorization'];
    final current = await storage.readAccessToken();
    final alreadyRefreshed = current != null && sentHeader != 'Bearer $current';

    if (!alreadyRefreshed) {
      final ok = await refreshCoordinator.refresh();
      if (!ok) return handler.next(err);
    }

    try {
      final token = await storage.readAccessToken();
      request.extra[_retriedKey] = true;
      request.headers['Authorization'] = 'Bearer $token';
      final response = await dio.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
