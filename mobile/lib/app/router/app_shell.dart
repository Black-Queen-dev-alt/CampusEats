import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Coque avec barre de navigation du bas. Chaque onglet garde son état.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.destinations,
  });

  final StatefulNavigationShell navigationShell;
  final List<ShellDestination> destinations;

  /// Onglets de l'étudiant (maquette : Accueil, Mes Commandes, Profil).
  static const studentDestinations = [
    ShellDestination(
      label: 'Accueil',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    ShellDestination(
      label: 'Mes Commandes',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    ShellDestination(
      label: 'Profil',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  /// Onglets de l'administrateur (maquette : Dashboard, Menus, Commandes, Paramètres).
  static const adminDestinations = [
    ShellDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    ShellDestination(
      label: 'Menus',
      icon: Icons.restaurant_menu_outlined,
      selectedIcon: Icons.restaurant_menu,
    ),
    ShellDestination(
      label: 'Commandes',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    ShellDestination(
      label: 'Paramètres',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Un second appui sur l'onglet actif revient à sa page racine.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
