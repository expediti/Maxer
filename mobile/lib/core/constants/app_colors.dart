import 'package:flutter/material.dart';

/// REXAM Brand Design System Color Palette
/// Strict adherence to the specification:
/// - Main background: #090D0B
/// - Secondary background: #111713
/// - Surface: #171F19
/// - Primary green: #65D68A
/// - Secondary green: #328653
/// - Main text: #F2F5F2
/// - Muted text: #89938C
/// - Border: #27332B
/// - Warning: #E5B65B
/// - Error: #E16B6B
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF090D0B);
  static const Color secondaryBackground = Color(0xFF111713);
  static const Color surface = Color(0xFF171F19);
  static const Color surfaceElevated = Color(0xFF1E2821);

  static const Color primaryGreen = Color(0xFF65D68A);
  static const Color secondaryGreen = Color(0xFF328653);
  static const Color greenLight = Color(0x1F65D68A); // 12% opacity tint

  static const Color textMain = Color(0xFFF2F5F2);
  static const Color textMuted = Color(0xFF89938C);
  static const Color textSubtle = Color(0xFF5A635D);

  static const Color border = Color(0xFF27332B);
  static const Color borderSubtle = Color(0xFF1E2821);
  static const Color divider = Color(0xFF1C241E);

  static const Color warning = Color(0xFFE5B65B);
  static const Color warningLight = Color(0x1FE5B65B);

  static const Color error = Color(0xFFE16B6B);
  static const Color errorLight = Color(0x1FE16B6B);

  static const Color info = Color(0xFF68B2DF);
  static const Color infoLight = Color(0x1F68B2DF);

  // Eligibility Status Colors
  static const Color eligible = Color(0xFF65D68A);
  static const Color potentiallyEligible = Color(0xFFE5B65B);
  static const Color ineligible = Color(0xFFE16B6B);
  static const Color missingInfo = Color(0xFF89938C);
}

