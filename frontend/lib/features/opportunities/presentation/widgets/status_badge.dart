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
        textColor = AppColors.primaryGreen;
        bgColor = AppColors.greenLight;
        borderColor = AppColors.primaryGreen.withOpacity(0.3);
        break;
      case EligibilityStatus.potentiallyEligible:
        textColor = AppColors.warning;
        bgColor = AppColors.warningLight;
        borderColor = AppColors.warning.withOpacity(0.3);
        break;
      case EligibilityStatus.notEligible:
        textColor = AppColors.error;
        bgColor = AppColors.errorLight;
        borderColor = AppColors.error.withOpacity(0.3);
        break;
      case EligibilityStatus.missingInformation:
        textColor = AppColors.textMuted;
        bgColor = AppColors.surface;
        borderColor = AppColors.border;
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
              shape: BoxShape.circle,
              color: textColor,
            ),
          ),
          const SizedBox(width: AppDimensions.space6),
          Text(
            status.label,
            style: AppTypography.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class VerifiedSourceChip extends StatelessWidget {
  final String? authority;

  const VerifiedSourceChip({
    super.key,
    this.authority,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space8,
        vertical: AppDimensions.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: AppDimensions.roundedSmall,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_outlined,
            size: 12,
            color: AppColors.primaryGreen,
          ),
          const SizedBox(width: AppDimensions.space4),
          Text(
            authority ?? 'Official Source',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
