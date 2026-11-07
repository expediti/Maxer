import 'package:flutter/material.dart';

/// Spacing and sizing based strictly on 4px grid increments
/// Corner radii restrained to 8-12px
class AppDimensions {
  AppDimensions._();

  // Spacing
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // Corner Radii (8-12px)
  static const double radiusSmall = 6.0;
  static const double radiusDefault = 8.0;
  static const double radiusMedium = 10.0;
  static const double radiusLarge = 12.0;

  static const BorderRadius roundedSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius roundedDefault = BorderRadius.all(Radius.circular(radiusDefault));
  static const BorderRadius roundedMedium = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius roundedLarge = BorderRadius.all(Radius.circular(radiusLarge));

  // Component heights
  static const double buttonHeight = 44.0;
  static const double inputHeight = 48.0;
  static const double navBarHeight = 64.0;
  static const double cardBorderWidth = 1.0;
}
