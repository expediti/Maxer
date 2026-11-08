import 'package:flutter/material.dart';

/// REXAM Brand Design System Color Palette
/// Designed for high readability, academic & career professionalism,
/// and support for both Light and Dark themes.
class AppColors {
  AppColors._();

  // --- Light Theme Palette (Warm Neutral / Off-White) ---
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSecondaryBackground = Color(0xFFF1F5F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);

  static const Color lightTextMain = Color(0xFF111827); // Deep charcoal
  static const Color lightTextMuted = Color(0xFF6B7280); // Muted grey
  static const Color lightTextSubtle = Color(0xFF9CA3AF);

  static const Color lightBorder = Color(0xFFE5E7EB); // Subtle border
  static const Color lightBorderSubtle = Color(0xFFF3F4F6);
  static const Color lightDivider = Color(0xFFE5E7EB);

  // --- Dark Theme Palette (Deep Slate / Charcoal) ---
  static const Color darkBackground = Color(0xFF0B0F19);
  static const Color darkSecondaryBackground = Color(0xFF111827);
  static const Color darkSurface = Color(0xFF162032);
  static const Color darkSurfaceElevated = Color(0xFF1E293B);

  static const Color darkTextMain = Color(0xFFF9FAFB);
  static const Color darkTextMuted = Color(0xFF94A3B8);
  static const Color darkTextSubtle = Color(0xFF64748B);

  static const Color darkBorder = Color(0xFF26334D);
  static const Color darkBorderSubtle = Color(0xFF1E293B);
  static const Color darkDivider = Color(0xFF1F2937);

  // --- Brand Accents & Semantic Tokens ---
  // Primary: Sophisticated Indigo / Blue
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlueDark = Color(0xFF1D4ED8);
  static const Color primaryBlueLight = Color(0xFFEFF6FF);

  // Success: Green
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color successDark = Color(0xFF10B981);

  // Warning: Amber
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color warningDark = Color(0xFFF59E0B);

  // Error: Red
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color errorDark = Color(0xFFEF4444);

  // Info: Cyan / Sky Blue
  static const Color info = Color(0xFF0284C7);
  static const Color infoLight = Color(0xFFF0F9FF);

  // Eligibility Status Colors
  static const Color eligible = Color(0xFF059669);
  static const Color potentiallyEligible = Color(0xFFD97706);
  static const Color ineligible = Color(0xFFDC2626);
  static const Color missingInfo = Color(0xFF6B7280);

  // Legacy & Theme-dependent compatibility accessors (defaulting to dark/light appropriately)
  static const Color background = darkBackground;
  static const Color secondaryBackground = darkSecondaryBackground;
  static const Color surface = darkSurface;
  static const Color surfaceElevated = darkSurfaceElevated;
  static const Color textMain = darkTextMain;
  static const Color textMuted = darkTextMuted;
  static const Color textSubtle = darkTextSubtle;
  static const Color border = darkBorder;
  static const Color borderSubtle = darkBorderSubtle;
  static const Color divider = darkDivider;

  static const Color primaryGreen = Color(0xFF10B981);
  static const Color secondaryGreen = Color(0xFF059669);
  static const Color greenLight = Color(0x1F10B981);
}
