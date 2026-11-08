import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------------
  // LIGHT THEME (Warm Off-White / Light Neutral)
  // ---------------------------------------------------------------------------
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryBlueLight,
        onPrimaryContainer: AppColors.primaryBlueDark,
        secondary: AppColors.primaryBlueDark,
        onSecondary: Colors.white,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextMain,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.lightBorder,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: AppTypography.brandTitle.copyWith(color: AppColors.lightTextMain),
        titleLarge: AppTypography.screenTitle.copyWith(color: AppColors.lightTextMain),
        titleMedium: AppTypography.sectionHeader.copyWith(color: AppColors.lightTextMain),
        titleSmall: AppTypography.cardTitle.copyWith(color: AppColors.lightTextMain),
        bodyLarge: AppTypography.body.copyWith(color: AppColors.lightTextMain),
        bodyMedium: AppTypography.bodyMuted.copyWith(color: AppColors.lightTextMuted),
        labelLarge: AppTypography.button.copyWith(color: Colors.white),
        labelMedium: AppTypography.label.copyWith(color: AppColors.lightTextMain),
        labelSmall: AppTypography.caption.copyWith(color: AppColors.lightTextMuted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextMain,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextMain,
        ),
        iconTheme: IconThemeData(
          color: AppColors.lightTextMain,
          size: 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.roundedDefault,
          side: const BorderSide(
            color: AppColors.lightBorder,
            width: AppDimensions.cardBorderWidth,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        hintStyle: AppTypography.bodyMuted.copyWith(color: AppColors.lightTextSubtle),
        labelStyle: AppTypography.bodyMuted.copyWith(color: AppColors.lightTextMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space12,
        ),
        border: OutlineInputBorder(
          borderRadius: AppDimensions.roundedDefault,
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.roundedDefault,
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.roundedDefault,
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.roundedDefault,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.roundedDefault,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.roundedDefault,
          ),
          textStyle: AppTypography.button.copyWith(color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          side: const BorderSide(color: AppColors.lightBorder),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.roundedDefault,
          ),
          textStyle: AppTypography.button.copyWith(color: AppColors.primaryBlue),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSecondaryBackground,
        labelStyle: AppTypography.caption.copyWith(color: AppColors.lightTextMain),
        side: const BorderSide(color: AppColors.lightBorder),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.roundedSmall,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space8,
          vertical: AppDimensions.space4,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DARK THEME (Deep Slate / Charcoal)
  // ---------------------------------------------------------------------------
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBlue,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryBlueDark,
        onPrimaryContainer: Colors.white,
        secondary: AppColors.primaryBlueLight,
        onSecondary: AppColors.darkTextMain,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextMain,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.darkBorder,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: AppTypography.brandTitle.copyWith(color: AppColors.darkTextMain),
        titleLarge: AppTypography.screenTitle.copyWith(color: AppColors.darkTextMain),
        titleMedium: AppTypography.sectionHeader.copyWith(color: AppColors.darkTextMain),
        titleSmall: AppTypography.cardTitle.copyWith(color: AppColors.darkTextMain),
        bodyLarge: AppTypography.body.copyWith(color: AppColors.darkTextMain),
        bodyMedium: AppTypography.bodyMuted.copyWith(color: AppColors.darkTextMuted),
        labelLarge: AppTypography.button.copyWith(color: Colors.white),
        labelMedium: AppTypography.label.copyWith(color: AppColors.darkTextMain),
        labelSmall: AppTypography.caption.copyWith(color: AppColors.darkTextMuted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextMain,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextMain,
        ),
        iconTheme: IconThemeData(
          color: AppColors.darkTextMain,
          size: 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.roundedDefault,
          side: const BorderSide(
            color: AppColors.darkBorder,
            width: AppDimensions.cardBorderWidth,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSecondaryBackground,
        hintStyle: AppTypography.bodyMuted.copyWith(color: AppColors.darkTextSubtle),
        labelStyle: AppTypography.bodyMuted.copyWith(color: AppColors.darkTextMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space12,
        ),
        border: OutlineInputBorder(
          borderRadius: AppDimensions.roundedDefault,
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.roundedDefault,
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.roundedDefault,
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.roundedDefault,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.roundedDefault,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.roundedDefault,
          ),
          textStyle: AppTypography.button.copyWith(color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          side: const BorderSide(color: AppColors.darkBorder),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.roundedDefault,
          ),
          textStyle: AppTypography.button.copyWith(color: Colors.white),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSecondaryBackground,
        labelStyle: AppTypography.caption.copyWith(color: AppColors.darkTextMain),
        side: const BorderSide(color: AppColors.darkBorder),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.roundedSmall,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space8,
          vertical: AppDimensions.space4,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
