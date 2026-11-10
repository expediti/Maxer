import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get brandTitle => GoogleFonts.plusJakartaSans(
        fontSize: 22.0,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: AppColors.primaryText,
      );

  static TextStyle get headlineLarge => GoogleFonts.plusJakartaSans(
        fontSize: 28.0,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.2,
        color: AppColors.primaryText,
      );

  static TextStyle get screenTitle => GoogleFonts.plusJakartaSans(
        fontSize: 20.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.primaryText,
      );

  static TextStyle get sectionHeader => GoogleFonts.plusJakartaSans(
        fontSize: 16.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.primaryText,
      );

  static TextStyle get cardTitle => GoogleFonts.plusJakartaSans(
        fontSize: 15.0,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: -0.1,
        color: AppColors.primaryText,
      );

  static TextStyle get cardSubtitle => GoogleFonts.plusJakartaSans(
        fontSize: 13.0,
        fontWeight: FontWeight.w500,
        color: AppColors.secondaryText,
      );

  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.primaryText,
      );

  static TextStyle get bodyMuted => GoogleFonts.plusJakartaSans(
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.secondaryText,
      );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: AppColors.mutedText,
      );

  static TextStyle get label => GoogleFonts.plusJakartaSans(
        fontSize: 11.0,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.secondaryText,
      );

  static TextStyle get button => GoogleFonts.plusJakartaSans(
        fontSize: 14.0,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: AppColors.mainBackground,
      );

  static TextStyle get codeSnippet => GoogleFonts.jetBrainsMono(
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryGreen,
      );
}
