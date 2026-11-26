import 'package:flutter/material.dart';
import 'package:campus_eats_mobile/core/theme/app_spacing.dart';

enum AppButtonVariant { filled, outlined }

/// Bouton principal de l'app : pleine largeur, 52 dp de haut (>= 48 dp).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.isLoading = false,
    this.variant = AppButtonVariant.filled,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  /// Affiche un indicateur et bloque les doubles appuis.
  final bool isLoading;
  final AppButtonVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !isLoading;
    final VoidCallback? handler = active ? onPressed : null;

    final Widget content = isLoading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.s),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );

    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: switch (variant) {
        AppButtonVariant.filled => FilledButton(
          onPressed: handler,
          child: content,
        ),
        AppButtonVariant.outlined => OutlinedButton(
          onPressed: handler,
          child: content,
        ),
      },
    );
  }
}
