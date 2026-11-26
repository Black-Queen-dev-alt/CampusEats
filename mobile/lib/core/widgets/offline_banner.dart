import 'package:flutter/material.dart';
import 'package:campus_eats_mobile/core/theme/app_colors.dart';
import 'package:campus_eats_mobile/core/theme/app_spacing.dart';

/// Bandeau affiché au-dessus d'une liste servie depuis le cache local.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    this.message = 'Affichage hors-ligne (menu en cache)',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.warning.withValues(alpha: 0.2),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.s,
        horizontal: AppSpacing.m,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
