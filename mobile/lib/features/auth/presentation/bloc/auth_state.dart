part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Démarrage : on ne sait pas encore si une session existe (écran d'attente).
final class AuthInitial extends AuthState {
  const AuthInitial();
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Requête de connexion / inscription en cours (toujours "non connecté").
final class AuthLoading extends Unauthenticated {
  const AuthLoading();
}

/// Échec de connexion / inscription (toujours "non connecté").
final class AuthFailure extends Unauthenticated {
  const AuthFailure({required this.message, this.fieldErrors = const {}});

  final String message;

  /// Erreurs 422 par champ : { "email": "...", "password": "..." }
  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => [message, fieldErrors];
}

final class Authenticated extends AuthState {
  const Authenticated(this.user);

  final User user;

  @override
  List<Object?> get props => [user];
}
