import 'package:flutter/material.dart';
import 'package:campus_eats_mobile/core/theme/app_colors.dart';
import 'package:campus_eats_mobile/core/theme/app_spacing.dart';

/// Logo CampusEats (assets/images/logo.png).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'Logo CampusEats',
      ),
    );
  }
}

/// Fond dégradé vert des écrans de marque (accueil, splash).
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.child, this.bottomRadius = 48});

  final Widget child;
  final double bottomRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(bottomRadius),
        ),
      ),
      child: child,
    );
  }
}
