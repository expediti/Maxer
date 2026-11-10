import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimensions.dart';
import '../core/constants/branding.dart';
import '../core/theme/app_typography.dart';

class RexamWordmark extends StatelessWidget {
  final double fontSize;
  final bool showSubtitle;
  final bool isDark;

  const RexamWordmark({
    super.key,
    this.fontSize = 24.0,
    this.showSubtitle = true,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppBranding.logoImage(
              size: fontSize * 1.3,
            ),
            const SizedBox(width: AppDimensions.space12),
            Text(
              AppBranding.brandName,
              style: AppTypography.brandTitle.copyWith(
                fontSize: fontSize,
                letterSpacing: 3.5,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        if (showSubtitle) ...[
          const SizedBox(height: AppDimensions.space6),
          Text(
            AppBranding.brandTagline,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
              fontSize: 11.5,
            ),
          ),
        ],
      ],
    );
  }
}
