import 'package:flutter/material.dart';
import 'package:campus_eats/core/theme/app_spacing.dart';

/// Badge affichant un statut avec couleur adaptée.
/// Ex. "En cours", "Prêt", "Annulé".
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({
    Key? key,
    required this.label,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
