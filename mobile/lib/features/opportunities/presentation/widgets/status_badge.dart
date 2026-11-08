import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/opportunity.dart';

class StatusBadge extends StatelessWidget {
  final EligibilityStatus status;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;
    Color borderColor;

    switch (status) {
      case EligibilityStatus.eligible:
        textColor = AppColors.success;
        bgColor = AppColors.successLight;
        borderColor = AppColors.success.withValues(alpha: 0.3);
        break;
      case EligibilityStatus.potentiallyEligible:
        textColor = AppColors.warning;
        bgColor = AppColors.warningLight;
        borderColor = AppColors.warning.withValues(alpha: 0.3);
        break;
      case EligibilityStatus.notEligible:
        textColor = AppColors.error;
        bgColor = AppColors.errorLight;
        borderColor = AppColors.error.withValues(alpha: 0.3);
        break;
      case EligibilityStatus.missingInformation:
        textColor = AppColors.missingInfo;
        bgColor = Theme.of(context).colorScheme.surface;
        borderColor = Theme.of(context).colorScheme.outline;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppDimensions.space8 : AppDimensions.space12,
        vertical: isCompact ? AppDimensions.space2 : AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppDimensions.roundedSmall,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppDimensions.space6),
          Text(
            status.label,
            style: AppTypography.caption.copyWith(
              color: textColor,
              fontSize: isCompact ? 10.5 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
