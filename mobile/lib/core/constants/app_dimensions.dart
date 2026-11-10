import 'package:flutter/material.dart';

/// Spacing and sizing based strictly on an 8px grid increments
/// Corner radii restrained to modern 14-18px
class AppDimensions {
  AppDimensions._();

  // Spacing (8px grid increments and fine adjustments)
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // Corner Radii (Modern 14-18px)
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusCard = 14.0;
  static const double radiusDefault = 16.0;
  static const double radiusLarge = 18.0;
  static const double radiusXLarge = 24.0;

  static const BorderRadius roundedSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius roundedMedium = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius roundedCard = BorderRadius.all(Radius.circular(radiusCard));
  static const BorderRadius roundedDefault = BorderRadius.all(Radius.circular(radiusDefault));
  static const BorderRadius roundedLarge = BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius roundedXLarge = BorderRadius.all(Radius.circular(radiusXLarge));

  // Component heights (48dp minimum touch targets)
  static const double buttonHeight = 48.0;
  static const double inputHeight = 50.0;
  static const double navBarHeight = 68.0;
  static const double cardBorderWidth = 1.0;
}
