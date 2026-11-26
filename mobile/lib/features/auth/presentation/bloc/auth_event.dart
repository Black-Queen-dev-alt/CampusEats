part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Au démarrage : restaure la session depuis le stockage sécurisé.
final class AppStarted extends AuthEvent {
  const AppStarted();
}

final class LoginRequested extends AuthEvent {
  const LoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class RegisterRequested extends AuthEvent {
  const RegisterRequested({
    required this.fullName,
    required this.email,
    required this.password,
  });

  final String fullName;
  final String email;
  final String password;

  @override
  List<Object?> get props => [fullName, email, password];
}

final class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Envoyé par le RefreshCoordinator quand le refresh est refusé.
final class SessionExpired extends AuthEvent {
  const SessionExpired();
}

/// Le profil a été modifié : met à jour l'utilisateur connecté.
final class UserUpdated extends AuthEvent {
  const UserUpdated(this.user);

  final User user;

  @override
  List<Object?> get props => [user];
}
