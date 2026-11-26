import 'package:flutter/material.dart';
import 'package:campus_eats_mobile/features/auth/presentation/widgets/logout_button.dart';
import 'package:campus_eats_mobile/core/theme/app_spacing.dart';
import 'package:campus_eats_mobile/core/widgets/state_view.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder menu page
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: const [LogoutButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: StateView(
          isLoading: false,
          isEmpty: false,
          errorMessage: null,
          child: ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Plat Exemple',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'Description courte du plat.',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: AppSpacing.s),
                      Text(
                        '12,00 €',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
