import 'package:flutter/material.dart';

/// Centralized branding configuration for REXAM.
/// All logo and icon assets must reference this class.
class AppBranding {
  AppBranding._();

  /// Primary application logo asset path
  static const String logo = 'assets/branding/logo.png';

  /// Primary application icon asset path
  static const String icon = 'assets/branding/icon.png';

  /// Brand name
  static const String brandName = 'REXAM';

  /// Brand tagline / purpose
  static const String brandTagline = 'Indian Examination & Opportunity Intelligence';

  /// Helper widget to render the official Rexam logo cleanly preserving aspect ratio
  static Widget logoImage({
    double? size = 28,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    final double? effectiveWidth = width ?? size;
    final double? effectiveHeight = height ?? size;

    return Image.asset(
      logo,
      width: effectiveWidth,
      height: effectiveHeight,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        width: effectiveWidth,
        height: effectiveHeight,
        decoration: BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            'R',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// Helper widget to render the official Rexam launcher / app icon
  static Widget iconImage({
    double? size = 32,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    final double? effectiveWidth = width ?? size;
    final double? effectiveHeight = height ?? size;

    return Image.asset(
      icon,
      width: effectiveWidth,
      height: effectiveHeight,
      fit: fit,
    );
  }
}

