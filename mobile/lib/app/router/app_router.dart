import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_mobile/app/router/app_shell.dart';
import 'package:campus_eats_mobile/app/router/go_router_refresh_stream.dart';
import 'package:campus_eats_mobile/core/widgets/coming_soon_page.dart';
import 'package:campus_eats_mobile/features/admin/presentation/pages/admin_page.dart';
import 'package:campus_eats_mobile/features/auth/domain/user.dart';
import 'package:campus_eats_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:campus_eats_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:campus_eats_mobile/features/auth/presentation/pages/register_page.dart';
import 'package:campus_eats_mobile/features/auth/presentation/pages/splash_page.dart';
import 'package:campus_eats_mobile/features/auth/presentation/pages/welcome_page.dart';
import 'package:campus_eats_mobile/features/kitchen/presentation/pages/kitchen_page.dart';
import 'package:campus_eats_mobile/features/menu/presentation/pages/menu_page.dart';
import 'package:campus_eats_mobile/features/orders/presentation/pages/orders_page.dart';
import 'package:campus_eats_mobile/features/profile/presentation/pages/profile_page.dart';

class AppRouter {
  static const _publicRoutes = {'/welcome', '/login', '/register'};

  /// Routes autorisées par rôle (à compléter quand les écrans arrivent).
  static List<String> _allowedPrefixes(UserRole role) => switch (role) {
    UserRole.etudiant => ['/menu', '/cart', '/orders', '/profile'],
    UserRole.personnel => ['/kitchen'],
    UserRole.admin => ['/admin'],
  };

  static String homeFor(UserRole role) => switch (role) {
    UserRole.etudiant => '/menu',
    UserRole.personnel => '/kitchen',
    UserRole.admin => '/admin',
  };

  /// Une SEULE fonction de redirection pour toute l'app.
  static String? redirect(AuthState auth, String location) {
    // 1. Session pas encore vérifiée : écran d'attente.
    if (auth is AuthInitial) {
      return location == '/splash' ? null : '/splash';
    }

    // 2. Non connecté (y compris pendant un login ou après un échec).
    if (auth is! Authenticated) {
      return _publicRoutes.contains(location) ? null : '/welcome';
    }

    // 3. Connecté : renvoyé vers l'espace de son rôle.
    final role = auth.user.role;
    final home = homeFor(role);
    if (location == '/splash' || _publicRoutes.contains(location)) return home;

    final allowed = _allowedPrefixes(role).any(location.startsWith);
    return allowed ? null : home;
  }

  static GoRouter create(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) =>
          redirect(authBloc.state, state.matchedLocation),
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
        GoRoute(path: '/welcome', builder: (_, __) => const WelcomePage()),
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),

        // Étudiant : Accueil / Mes Commandes / Profil
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(
            navigationShell: shell,
            destinations: AppShell.studentDestinations,
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/menu', builder: (_, __) => const MenuPage()),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/orders',
                  builder: (_, __) => const OrdersPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (_, __) => const ProfilePage(),
                ),
              ],
            ),
          ],
        ),
        // Détail d'une commande (cible des notifications), hors barre du bas.
        GoRoute(
          path: '/orders/:id',
          builder: (_, state) =>
              OrderDetailPage(orderId: state.pathParameters['id'] ?? ''),
        ),

        // Personnel : tableau cuisine
        GoRoute(path: '/kitchen', builder: (_, __) => const KitchenPage()),

        // Admin : Dashboard / Menus / Commandes / Paramètres
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(
            navigationShell: shell,
            destinations: AppShell.adminDestinations,
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/admin', builder: (_, __) => const AdminPage()),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/admin/menus',
                  builder: (_, __) => const ComingSoonPage(
                    title: 'Gérer les menus',
                    detail: 'Menus et plats (lot personne 4).',
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/admin/orders',
                  builder: (_, __) => const ComingSoonPage(
                    title: 'Commandes',
                    detail: 'Suivi des commandes (lot personne 4).',
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/admin/settings',
                  builder: (_, __) => const ProfilePage(),
                ),
              ],
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text(state.error?.toString() ?? 'Page introuvable'),
        ),
      ),
    );
  }
}
