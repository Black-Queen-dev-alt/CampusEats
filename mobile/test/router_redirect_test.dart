import 'package:flutter_test/flutter_test.dart';
import 'package:campus_eats_mobile/app/router/app_router.dart';
import 'package:campus_eats_mobile/features/auth/domain/user.dart';
import 'package:campus_eats_mobile/features/auth/presentation/bloc/auth_bloc.dart';

Authenticated _as(UserRole role) => Authenticated(
  User(id: '1', email: 'a@b.fr', fullName: 'Test User', role: role),
);

void main() {
  group('AppRouter.redirect', () {
    test('session pas encore vérifiée : écran d\'attente', () {
      expect(AppRouter.redirect(const AuthInitial(), '/menu'), '/splash');
      expect(AppRouter.redirect(const AuthInitial(), '/splash'), isNull);
    });

    test('visiteur : renvoyé vers l\'accueil, pages publiques autorisées', () {
      expect(AppRouter.redirect(const Unauthenticated(), '/menu'), '/welcome');
      expect(AppRouter.redirect(const Unauthenticated(), '/login'), isNull);
      expect(AppRouter.redirect(const AuthLoading(), '/login'), isNull);
      expect(
        AppRouter.redirect(const AuthFailure(message: 'x'), '/register'),
        isNull,
      );
    });

    test('étudiant connecté', () {
      final s = _as(UserRole.etudiant);
      expect(AppRouter.redirect(s, '/login'), '/menu');
      expect(AppRouter.redirect(s, '/splash'), '/menu');
      expect(AppRouter.redirect(s, '/kitchen'), '/menu');
      expect(AppRouter.redirect(s, '/admin'), '/menu');
      expect(AppRouter.redirect(s, '/orders'), isNull);
      expect(AppRouter.redirect(s, '/orders/abc123'), isNull);
      expect(AppRouter.redirect(s, '/profile'), isNull);
    });

    test('personnel connecté', () {
      final s = _as(UserRole.personnel);
      expect(AppRouter.redirect(s, '/welcome'), '/kitchen');
      expect(AppRouter.redirect(s, '/menu'), '/kitchen');
      expect(AppRouter.redirect(s, '/kitchen'), isNull);
    });

    test('admin connecté', () {
      final s = _as(UserRole.admin);
      expect(AppRouter.redirect(s, '/login'), '/admin');
      expect(AppRouter.redirect(s, '/kitchen'), '/admin');
      expect(AppRouter.redirect(s, '/admin/menus'), isNull);
      expect(AppRouter.redirect(s, '/admin/settings'), isNull);
    });
  });
}
