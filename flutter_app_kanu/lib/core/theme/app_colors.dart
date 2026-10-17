import 'package:flutter/material.dart';

/// Palette de marque KANU.
///
/// Les valeurs sombres sont directement issues du design system du site
/// (variables `--color-kanu-*` du bundle CSS). Le thème clair est une
/// déclinaison cohérente conservant la même hiérarchie chromatique
/// (noir/rouge/or/gris).
class AppColors {
  const AppColors._();

  // ---- Thème sombre (référence du site) --------------------------------
  static const Color black = Color(0xFF080808);
  static const Color dark = Color(0xFF101012);
  static const Color charcoal = Color(0xFF141418);
  static const Color card = Color(0xFF121215);
  static const Color surface = Color(0xFF1B1B20);
  static const Color border = Color(0xFF2A2A32);
  static const Color borderSoft = Color(0xFF1E1E24);

  static const Color white = Color(0xFFF5F5FA);
  static const Color muted = Color(0xFFA0A0B0);
  static const Color silver = Color(0xFFC8C8D8);
  static const Color chrome = Color(0xFFE0E0EC);

  static const Color red = Color(0xFFFF1A1A);
  static const Color redDeep = Color(0xFFE02020);
  static const Color rose = Color(0xFFFF4444);
  static const Color gold = Color(0xFFD4B860);
  static const Color cream = Color(0xFFEDE8DC);

  // Sémantique
  static const Color success = Color(0xFF00C850);
  static const Color warning = Color(0xFFE0A020);
  static const Color danger = Color(0xFFFF3B3B);

  // ---- Thème clair -----------------------------------------------------
  static const Color lightBackground = Color(0xFFF7F5F2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE3E0DA);
  static const Color lightText = Color(0xFF1A1A1F);
  static const Color lightMuted = Color(0xFF6B6B78);
  static const Color lightPrimary = Color(0xFFC01818);

  /// Dégradé rouge signature.
  static const LinearGradient redGradient = LinearGradient(
    colors: [red, redDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dégradé argenté (titres / séparateurs).
  static const LinearGradient silverGradient = LinearGradient(
    colors: [chrome, silver, muted],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
