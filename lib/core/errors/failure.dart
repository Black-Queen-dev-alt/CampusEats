// Failure base class
abstract class Failure {
  final String message;
  const Failure(this.message);
}

// Specific failures
class UnauthorizedFailure extends Failure { const UnauthorizedFailure() : super('Non authentifié'); }
class ForbiddenFailure extends Failure { const ForbiddenFailure() : super('Accès interdit'); }
class ConflictFailure extends Failure { const ConflictFailure() : super('Conflit'); }
class ValidationFailure extends Failure { const ValidationFailure() : super('Erreur de validation'); }
class ServerFailure extends Failure { const ServerFailure() : super('Erreur serveur'); }
