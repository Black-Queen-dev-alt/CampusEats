import 'package:flutter/material.dart';

/// Palette CampusEats, relevée sur le logo et les maquettes.
class AppColors {
  // Marque
  static const Color primary = Color(0xFF0F766E); // vert canard
  static const Color primaryDark = Color(0xFF0B4F4A);
  static const Color primaryLight = Color(0xFFE0F2F1);
  static const Color secondary = Color(0xFFF28C1B); // orange du logo

  // Surfaces et textes
  static const Color background = Color(0xFFF3FAF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFD3E5E3);
  static const Color textPrimary = Color(0xFF12353A);
  static const Color textSecondary = Color(0xFF5B7479);

  // États
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2B8CC4);

  /// Dégradé des en-têtes (accueil, splash).
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, primary],
  );
}
