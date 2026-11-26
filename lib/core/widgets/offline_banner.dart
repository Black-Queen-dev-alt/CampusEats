import 'package:flutter/material.dart';
import 'package:campus_eats/core/theme/app_spacing.dart';

/// Bandeau affiché en haut de l'écran lorsqu'une connexion réseau est perdue.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.redAccent,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: const Center(
        child: Text(
          'Hors ligne – affichage des données en cache',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
