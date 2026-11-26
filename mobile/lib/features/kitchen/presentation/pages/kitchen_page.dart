// Placeholder Kitchen page
import 'package:flutter/material.dart';
import 'package:campus_eats_mobile/features/auth/presentation/widgets/logout_button.dart';

class KitchenPage extends StatelessWidget {
  const KitchenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen'),
        actions: const [LogoutButton()],
      ),
      body: const Center(child: Text('Kitchen page placeholder')),
    );
  }
}
