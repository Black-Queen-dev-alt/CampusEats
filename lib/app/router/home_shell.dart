import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats/app/di/injection.dart';
import 'package:campus_eats/features/auth/presentation/bloc/auth_bloc.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({Key? key}) : super(key: key);

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  static const List<String> _routes = ['/menu', '/kitchen', '/admin'];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    // Optionally, hide tabs not authorized for the current role.
    final authBloc = getIt<AuthBloc>();
    final role = (authBloc.state is Authenticated) ? (authBloc.state as Authenticated).role : '';
    final allowedTabs = <int>[];
    if (role == 'student') allowedTabs.addAll([0]); // menu
    if (role == 'staff') allowedTabs.addAll([1]); // kitchen
    if (role == 'admin') allowedTabs.addAll([2]); // admin
    // Ensure at least one tab is displayed to avoid empty UI.
    final items = <BottomNavigationBarItem>[];
    if (allowedTabs.contains(0)) {
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Menu'));
    }
    if (allowedTabs.contains(1)) {
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Cuisine'));
    }
    if (allowedTabs.contains(2)) {
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('CampusEats')),
      body: const Center(child: Text('Sélectionnez une section via le bandeau inférieur')),
      bottomNavigationBar: BottomNavigationBar(
        items: items,
        currentIndex: _selectedIndex % items.length,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

