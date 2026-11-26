import 'package:flutter/material.dart';
import 'package:campus_eats_mobile/core/errors/failure.dart';
import 'package:campus_eats_mobile/core/theme/app_colors.dart';
import 'package:campus_eats_mobile/core/theme/app_spacing.dart';
import 'package:campus_eats_mobile/core/widgets/app_button.dart';
import 'package:campus_eats_mobile/core/widgets/skeleton.dart';

/// Les 4 états obligatoires de tout écran alimenté par l'API :
/// chargement (squelette), vide, erreur (avec « Réessayer »), contenu.
/// Une erreur réseau s'affiche en version « hors ligne ».
class StateView extends StatelessWidget {
  const StateView({
    super.key,
    this.isLoading = false,
    this.isEmpty = false,
    this.failure,
    this.errorMessage,
    this.onRetry,
    this.onShowCache,
    this.loadingPlaceholder,
    this.emptyTitle = 'Aucun résultat',
    this.emptyMessage,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.child,
  });

  final bool isLoading;
  final bool isEmpty;

  /// Erreur typée (préférée). Si c'est un [NetworkFailure] : écran hors ligne.
  final Failure? failure;

  /// Message d'erreur simple (compatibilité).
  final String? errorMessage;
  final VoidCallback? onRetry;

  /// Si fourni en mode hors ligne : lien « Voir le cache ».
  final VoidCallback? onShowCache;
  final Widget? loadingPlaceholder;
  final String emptyTitle;
  final String? emptyMessage;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingPlaceholder ?? const SkeletonList();
    }
    if (failure is NetworkFailure) {
      return StateMessage(
        icon: Icons.wifi_off_rounded,
        iconColor: AppColors.primary,
        title: 'Vous êtes hors ligne',
        message:
            "Aucune connexion Internet n'est disponible. Les dernières données sont affichées.",
        primaryLabel: onRetry == null ? null : 'Réessayer',
        onPrimary: onRetry,
        secondaryLabel: onShowCache == null ? null : 'Voir le cache',
        onSecondary: onShowCache,
      );
    }
    if (failure != null || errorMessage != null) {
      return StateMessage(
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
        title: 'Une erreur est survenue',
        message: failure?.message ??
            errorMessage ??
            'Impossible de charger les données. Veuillez réessayer.',
        primaryLabel: onRetry == null ? null : 'Réessayer',
        onPrimary: onRetry,
      );
    }
    if (isEmpty) {
      return StateMessage(
        icon: Icons.inventory_2_outlined,
        iconColor: AppColors.secondary,
        title: emptyTitle,
        message: emptyMessage,
        primaryLabel: emptyActionLabel,
        onPrimary: onEmptyAction,
      );
    }
    return child ?? const SizedBox.shrink();
  }
}

/// Écran centré : icône, titre, message et un ou deux boutons.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.iconColor = AppColors.primary,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? message;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: iconColor),
            const SizedBox(height: AppSpacing.m),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.s),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (primaryLabel != null && onPrimary != null) ...[
              const SizedBox(height: AppSpacing.l),
              AppButton(label: primaryLabel!, onPressed: onPrimary!),
            ],
            if (secondaryLabel != null && onSecondary != null)
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
          ],
        ),
      ),
    );
  }
}
