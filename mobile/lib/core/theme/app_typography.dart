import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get brandTitle => GoogleFonts.inter(
        fontSize: 22.0,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
      );

  static TextStyle get screenTitle => GoogleFonts.inter(
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      );

  static TextStyle get sectionHeader => GoogleFonts.inter(
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      );

  static TextStyle get cardTitle => GoogleFonts.inter(
        fontSize: 15.0,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get cardSubtitle => GoogleFonts.inter(
        fontSize: 13.0,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        height: 1.45,
      );

  static TextStyle get bodyMuted => GoogleFonts.inter(
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        height: 1.45,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 11.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  static TextStyle get codeSnippet => GoogleFonts.jetBrainsMono(
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryBlue,
      );
}
