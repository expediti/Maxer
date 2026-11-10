import 'package:flutter/material.dart';

/// REXAM Brand Design System — Minimal Black & White Identity
/// Strict palette: Pure pitch black, subtle charcoal surfaces, crisp white typography,
/// and extremely restrained semantic status dots (Green = Eligible, Red = Ineligible, Yellow = Pending).
class AppColors {
  AppColors._();

  // --- Official Design System Starting Tokens ---
  static const Color mainBackground = Color(0xFF000000);
  static const Color secondaryBackground = Color(0xFF080808);
  static const Color cardBackground = Color(0xFF0D0D0D);
  static const Color elevatedSurface = Color(0xFF141414);

  // Typography Tokens
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFB5B5B5);
  static const Color mutedText = Color(0xFF777777);

  // Structural & Interactive Borders
  static const Color border = Color(0xFF242424);
  static const Color borders = Color(0xFF242424);
  static const Color bordersLight = Color(0xFF1A1A1A);
  static const Color divider = Color(0xFF1F1F1F);

  // Semantic Status Colors (Restrained to dots and micro-badges)
  static const Color eligible = Color(0xFF22C55E);
  static const Color ineligible = Color(0xFFEF4444);
  static const Color pending = Color(0xFFEAB308);

  static const Color primaryGreen = Color(0xFF22C55E);
  static const Color secondaryGreen = Color(0xFF16A34A);
  static const Color mutedGreen = Color(0xFF166534);
  static const Color greenTint = Color(0x1A22C55E); // ~10% for subtle status chips

  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0x1AEF4444);
  static const Color warning = Color(0xFFEAB308);
  static const Color warningBg = Color(0x1AEAB308);
  static const Color info = Color(0xFF38BDF8);
  static const Color infoBg = Color(0x1A38BDF8);
  static const Color success = Color(0xFF22C55E);
  static const Color successBg = Color(0x1A22C55E);

  // Neutral Accents
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Semantic Aliases
  static const Color mainText = primaryText;
  static const Color secondarySurface = cardBackground;
  static const Color background = mainBackground;
  static const Color surface = cardBackground;
  static const Color surfaceElevated = elevatedSurface;
  static const Color borderSubtle = bordersLight;
  static const Color textMain = primaryText;
  static const Color textMuted = secondaryText;
  static const Color textSubtle = mutedText;

  static const Color darkBackground = mainBackground;
  static const Color darkSecondaryBackground = secondaryBackground;
  static const Color darkSurface = cardBackground;
  static const Color darkSurfaceElevated = elevatedSurface;
  static const Color darkTextMain = primaryText;
  static const Color darkTextMuted = secondaryText;
  static const Color darkTextSubtle = mutedText;
  static const Color darkBorder = border;
  static const Color darkBorderSubtle = bordersLight;
  static const Color darkDivider = divider;

  static const Color lightBackground = mainBackground;
  static const Color lightSecondaryBackground = secondaryBackground;
  static const Color lightSurface = cardBackground;
  static const Color lightSurfaceElevated = elevatedSurface;
  static const Color lightTextMain = primaryText;
  static const Color lightTextMuted = secondaryText;
  static const Color lightTextSubtle = mutedText;
  static const Color lightBorder = border;
  static const Color lightBorderSubtle = bordersLight;
  static const Color lightDivider = divider;

  static const Color primaryBlue = primaryGreen;
  static const Color primaryBlueDark = secondaryGreen;
  static const Color primaryBlueLight = greenTint;
}
