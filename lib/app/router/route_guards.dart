import 'package:go_router/go_router.dart';
import 'package:campus_eats/app/di/injection.dart';
import 'package:campus_eats/features/auth/presentation/bloc/auth_bloc.dart';

/// Garde d'authentification :
/// - Si l'utilisateur n'est pas authentifié, on le redirige vers /login.
/// - Si l'utilisateur est déjà authentifié et tente d'accéder à /login ou /register,
///   on le redirige vers la page d'accueil (/home).
String? authGuard(GoRouterState state) {
  final authBloc = getIt<AuthBloc>();
  final authState = authBloc.state;

  // Si l'utilisateur n'est pas authentifié → rester sur la page demandée (login/register).
  if (authState is Unauthenticated) {
    return null; // autoriser la navigation vers login/register.
  }

  // Si déjà authentifié → rediriger vers la zone principale.
  return '/home';
}

/// Garde basée sur le rôle de l'utilisateur.
/// Utilisée pour la route /home afin d'envoyer l'utilisateur vers la bonne section.
String? roleGuard(GoRouterState state) {
  final authBloc = getIt<AuthBloc>();
  final authState = authBloc.state;

  if (authState is Authenticated) {
    switch (authState.role) {
      case 'student':
        return '/menu';
      case 'staff':
        return '/kitchen';
      case 'admin':
        return '/admin';
      default:
        return '/login';
    }
  }

  // Pas de session → rediriger vers login.
  return '/login';
}
