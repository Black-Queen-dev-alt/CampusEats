import 'package:flutter/material.dart';
import 'package:campus_eats_mobile/core/theme/app_colors.dart';
import 'package:campus_eats_mobile/core/theme/app_spacing.dart';

/// Pastille de statut : le libellé est toujours écrit (jamais la couleur seule).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  /// Statuts de commande tels que renvoyés par l'API :
  /// received, preparing, ready, withdrawn, cancelled.
  factory StatusBadge.order(String status) {
    final (label, color) = switch (status) {
      'received' => ('Reçue', AppColors.info),
      'preparing' => ('En préparation', AppColors.secondary),
      'ready' => ('Prête', AppColors.success),
      'withdrawn' => ('Retirée', AppColors.primary),
      'cancelled' => ('Annulée', AppColors.error),
      _ => (status, AppColors.textSecondary),
    };
    return StatusBadge(label: label, color: color);
  }

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.s + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
