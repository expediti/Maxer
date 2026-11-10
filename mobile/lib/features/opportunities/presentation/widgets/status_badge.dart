import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/opportunity.dart';

/// Minimal status indicator: Small semantic dot followed by crisp label.
/// No heavy colored backgrounds — adheres strictly to minimal black/white design system.
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
    Color dotColor;
    String label;

    switch (status) {
      case EligibilityStatus.eligible:
        dotColor = AppColors.eligible; // #22C55E
        label = 'Eligible';
        break;
      case EligibilityStatus.potentiallyEligible:
        dotColor = AppColors.pending; // #EAB308
        label = 'Likely Eligible';
        break;
      case EligibilityStatus.notEligible:
        dotColor = AppColors.ineligible; // #EF4444
        label = 'Not Eligible';
        break;
      case EligibilityStatus.missingInformation:
      case EligibilityStatus.needsVerification:
        dotColor = AppColors.pending; // #EAB308
        label = 'Requires Verification';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 5.5 : 6.5,
            height: isCompact ? 5.5 : 6.5,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: isCompact ? 10.5 : 12,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
