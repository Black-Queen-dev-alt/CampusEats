import 'package:flutter/material.dart';
import 'package:campus_eats/core/theme/app_theme.dart';
import 'package:campus_eats/core/theme/app_spacing.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  const AppButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.m,
          horizontal: AppSpacing.l,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        disabledBackgroundColor: Theme.of(context).disabledColor,
        textStyle: const TextStyle(fontSize: 16),
      ),
      onPressed: enabled ? onPressed : null,
      child: Text(label),
    );
  }
}
