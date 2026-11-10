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
            Container(
              width: fontSize * 1.3,
              height: fontSize * 1.3,
              decoration: BoxDecoration(
                color: AppColors.elevatedSurface,
                borderRadius: BorderRadius.circular(fontSize * 0.35),
                border: Border.all(
                  color: AppColors.borders,
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Container(
                  width: fontSize * 0.5,
                  height: fontSize * 0.5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Text(
              'REXAM',
              style: AppTypography.brandTitle.copyWith(
                fontSize: fontSize,
                letterSpacing: 3.5,
                fontWeight: FontWeight.w800,
                color: AppColors.mainText,
              ),
            ),
          ],
        ),
        if (showSubtitle) ...[
          const SizedBox(height: AppDimensions.space6),
          Text(
            'Indian Examination & Opportunity Intelligence',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.secondaryText,
              letterSpacing: 0.5,
              fontSize: 11.5,
            ),
          ),
        ],
      ],
    );
  }
}
