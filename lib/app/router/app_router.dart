import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_guards.dart';
import 'home_shell.dart';
import 'package:campus_eats/features/auth/presentation/pages/welcome_page.dart';
import 'package:campus_eats/features/auth/presentation/pages/login_page.dart';
import 'package:campus_eats/features/auth/presentation/pages/register_page.dart';
import 'package:campus_eats/features/menu/presentation/pages/menu_page.dart';
import 'package:campus_eats/features/kitchen/presentation/pages/kitchen_page.dart';
import 'package:campus_eats/features/admin/presentation/pages/admin_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
        redirect: (context, state) => authGuard(state),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
        redirect: (context, state) => authGuard(state),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeShell(),
        redirect: (context, state) => roleGuard(state),
      ),
      // Routes spécifiques aux rôles
      GoRoute(
        path: '/menu',
        builder: (context, state) => const MenuPage(),
      ),
      GoRoute(
        path: '/kitchen',
        builder: (context, state) => const KitchenPage(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text(state.error?.toString() ?? 'Page not found')),
    ),
  );
}

import 'package:go_router/go_router.dart';
import 'route_guards.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const Placeholder(), import 'package:campus_eats/features/auth/presentation/pages/welcome_page.dart';
import 'package:campus_eats/features/auth/presentation/pages/login_page.dart';
import 'package:campus_eats/features/auth/presentation/pages/register_page.dart';

// ... (keep existing imports)
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Placeholder(), // TODO: replace with LoginPage
        redirect: (context, state) => authGuard(state),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const Placeholder(), // TODO: replace with RegisterPage
        redirect: (context, state) => authGuard(state),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const Placeholder(), // TODO: replace with HomeShell
        redirect: (context, state) => roleGuard(state),
      ),
      // Ajoutez d'autres routes (menu, kitchen, admin, etc.) ici.
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text(state.error?.toString() ?? 'Page not found')),
    ),
  );
}
