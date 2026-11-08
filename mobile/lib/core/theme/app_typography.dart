import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get brandTitle => GoogleFonts.inter(
        fontSize: 22.0,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
        color: AppColors.textMain,
      );

  static TextStyle get screenTitle => GoogleFonts.inter(
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppColors.textMain,
      );

  static TextStyle get sectionHeader => GoogleFonts.inter(
        fontSize: 15.0,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: AppColors.textMain,
      );

  static TextStyle get cardTitle => GoogleFonts.inter(
        fontSize: 15.0,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.textMain,
      );

  static TextStyle get cardSubtitle => GoogleFonts.inter(
        fontSize: 13.0,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.textMain,
      );

  static TextStyle get bodyMuted => GoogleFonts.inter(
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.textMuted,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: AppColors.textMuted,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 11.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.textMain,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: AppColors.background,
      );

  static TextStyle get codeSnippet => GoogleFonts.jetBrainsMono(
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryGreen,
      );
}

