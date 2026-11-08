import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimensions.dart';
import '../core/theme/app_typography.dart';

class RexamWordmark extends StatelessWidget {
  final double fontSize;
  final bool showSubtitle;
  final bool isDark;

  const RexamWordmark({
    super.key,
    this.fontSize = 24.0,
    this.showSubtitle = true,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = isDark || theme.brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? AppColors.darkTextMain : AppColors.lightTextMain;
    final mutedTextColor = isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Emblem Symbol + Text
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: fontSize * 1.35,
              height: fontSize * 1.35,
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(fontSize * 0.4),
                border: Border.all(
                  color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: fontSize * 0.55,
                  height: fontSize * 0.55,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),
            SizedBox(width: fontSize * 0.45),
            Text(
              'REXAM',
              style: AppTypography.brandTitle.copyWith(
                fontSize: fontSize,
                letterSpacing: 3.5,
                fontWeight: FontWeight.w800,
                color: primaryTextColor,
              ),
            ),
          ],
        ),
        if (showSubtitle) ...[
          const SizedBox(height: AppDimensions.space8),
          Text(
            'Indian Examination & Opportunity Intelligence',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: mutedTextColor,
              letterSpacing: 0.4,
              fontSize: 12.0,
            ),
          ),
        ],
      ],
    );
  }
}

