import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_mobile/core/theme/app_colors.dart';
import 'package:campus_eats_mobile/core/theme/app_spacing.dart';
import 'package:campus_eats_mobile/core/widgets/app_button.dart';
import 'package:campus_eats_mobile/core/widgets/app_logo.dart';

/// Écran d'accueil : en-tête vert avec le logo, puis connexion / inscription.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                BrandHeader(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xl,
                      ),
                      child: Column(
                        children: [
                          const AppLogo(size: 190),
                          const SizedBox(height: AppSpacing.m),
                          Text(
                            'Bien manger, à votre portée',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Column(
                    children: [
                      AppButton(
                        label: 'Se connecter',
                        onPressed: () => context.go('/login'),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      AppButton(
                        label: 'Créer un compte',
                        variant: AppButtonVariant.outlined,
                        onPressed: () => context.go('/register'),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.m,
                            ),
                            child: Text(
                              'ou',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.m),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              'Accès sécurisé réservé aux étudiants, personnels et administrateurs',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
