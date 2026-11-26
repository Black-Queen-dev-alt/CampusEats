/// Erreur "métier" renvoyée par la couche data.
/// Les widgets et les blocs ne manipulent jamais de DioException.
abstract class Failure implements Exception {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure()
    : super('Impossible de joindre le serveur. Vérifiez votre connexion.');
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Non authentifié']);
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message = 'Accès interdit']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Ressource introuvable']);
}

class ConflictFailure extends Failure {
  const ConflictFailure([super.message = 'Conflit', this.code]);

  final String? code;
}

/// Erreur 422 : `fieldErrors` associe un champ à son message.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.fieldErrors = const {}});
  final Map<String, String> fieldErrors;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Erreur serveur']);
}
