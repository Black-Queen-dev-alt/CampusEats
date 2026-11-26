// Convertit une DioException en Failure, à UN seul endroit.
import 'package:dio/dio.dart';
import 'package:campus_eats_mobile/core/errors/failure.dart';

/// Format d'erreur de l'API :
/// { "success": false, "error": { "code", "message", "details": [{field, message}] } }
Failure mapDioError(DioException error) {
  final status = error.response?.statusCode;
  if (status == null) return const NetworkFailure();

  String? message;
  final fieldErrors = <String, String>{};

  final body = error.response?.data;
  if (body is Map && body['error'] is Map) {
    final err = body['error'] as Map;
    message = err['message'] as String?;
    final details = err['details'];
    if (details is List) {
      for (final d in details) {
        if (d is Map && d['field'] is String && d['message'] is String) {
          fieldErrors.putIfAbsent(
            d['field'] as String,
            () => d['message'] as String,
          );
        }
      }
    }
  }

  switch (status) {
    case 401:
      return UnauthorizedFailure(message ?? 'Non authentifié');
    case 403:
      return ForbiddenFailure(message ?? 'Accès interdit');
    case 404:
      return NotFoundFailure(message ?? 'Ressource introuvable');
    case 409:
      return ConflictFailure(message ?? 'Conflit');
    case 422:
      return ValidationFailure(
        message ?? 'Données invalides',
        fieldErrors: fieldErrors,
      );
    default:
      return ServerFailure(message ?? 'Erreur serveur');
  }
}
