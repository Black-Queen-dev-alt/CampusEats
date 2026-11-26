import 'package:dio/dio.dart';
import 'package:campus_eats_mobile/core/errors/error_mapper.dart';
import 'package:campus_eats_mobile/core/errors/failure.dart';
import 'package:campus_eats_mobile/features/auth/domain/user.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final User user;
  final String accessToken;
  final String refreshToken;
}

/// Appelle l'API d'authentification. Ne laisse sortir que des [Failure].
class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthSession> login({required String email, required String password}) {
    return _createSession('/auth/login', {
      'email': email,
      'password': password,
    });
  }

  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _createSession('/auth/register', {
      'fullName': fullName,
      'email': email,
      'password': password,
    });
  }

  Future<User> me() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/me');
      return _parseUser(response.data?['data']);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<User> updateProfile({required String fullName}) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/me',
        data: {'fullName': fullName},
      );
      return _parseUser(response.data?['data']);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> logout(String? refreshToken) async {
    if (refreshToken == null) return;
    try {
      await _dio.post<void>(
        '/auth/logout',
        data: {'refreshToken': refreshToken},
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AuthSession> _createSession(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ServerFailure('Réponse inattendue du serveur.');
      }
      final access = data['accessToken'];
      final refresh = data['refreshToken'];
      if (access is! String || refresh is! String) {
        throw const ServerFailure('Réponse inattendue du serveur.');
      }
      return AuthSession(
        user: _parseUser(data['user']),
        accessToken: access,
        refreshToken: refresh,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  User _parseUser(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const ServerFailure('Réponse inattendue du serveur.');
    }
    final role = UserRole.fromApi(json['role'] as String?);
    final id = (json['id'] ?? json['_id'])?.toString();
    if (role == null || id == null) {
      throw const ServerFailure(
        'Réponse inattendue du serveur (rôle inconnu).',
      );
    }
    return User(
      id: id,
      email: (json['email'] as String?) ?? '',
      fullName: (json['fullName'] as String?) ?? '',
      role: role,
    );
  }
}
