import 'package:flutter/material.dart';

/// Zenvix color palette — Premium flat, paper-like theme.
class AppColors {
  AppColors._();

  static const Color ink = Color(0xFF252A34);
  static const Color coral = Color(0xFFE9826E);
  static const Color paper = Color(0xFFFAF8F5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color mist = Color(0xFFF0EFEC);
  static const Color slate = Color(0xFF777B83);
  static const Color border = Color(0xFFE3E0DA);

  static const Color sage = Color(0xFF789C86);
  static const Color amber = Color(0xFFD9A441);
  static const Color error = Color(0xFFC96B67);

  // Shadows for cards
  static List<BoxShadow> get subtleElevation => [
    BoxShadow(
      color: ink.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  // ── Legacy aliases (mapped to new aesthetic) ──
  static const Color background = paper;
  static const Color surface = white;
  static const Color surfaceLight = mist;
  static const Color cardSurface = white;
  static const Color surfaceBorder = border;

  static const Color neonBlue = ink; // primary accent -> ink
  static const Color electricPurple = coral; // secondary accent -> coral
  static const Color accentCyan = sage;
  static const Color accentPink = amber;

  static const Color textPrimary = ink;
  static const Color textSecondary = slate;
  static const Color textTertiary = slate;
  static const Color textDisabled = slate;

  static const Color success = sage;
  static const Color warning = amber;
  static const Color info = ink;

  static const LinearGradient accentGradient = LinearGradient(
    colors: [ink, ink],
  );
  
  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [white, white],
  );

  static const LinearGradient subtleGradient = LinearGradient(
    colors: [paper, mist],
  );

  static List<BoxShadow> get neonGlow => subtleElevation;
}
