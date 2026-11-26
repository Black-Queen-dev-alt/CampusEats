// Placeholder Admin page
import 'package:flutter/material.dart';
import 'package:campus_eats_mobile/features/auth/presentation/widgets/logout_button.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        actions: const [LogoutButton()],
      ),
      body: const Center(child: Text('Admin page placeholder')),
    );
  }
}
