import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/opportunity.dart';

/// Minimal status indicator: Small semantic dot followed by crisp label.
/// Theme-aware: renders with high contrast in both Light and Dark themes.
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
      case EligibilityStatus.unconfirmed:
        dotColor = AppColors.pending; // #EAB308
        label = 'Info Incomplete';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: context.themeSurfaceElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: context.themeBorder, width: 1.0),
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
              color: context.themeTextMain,
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

/// Opportunity Application Lifecycle Badge:
/// Open, Upcoming, Notification Released, Awaiting Notification, Closed, Archived.
class OpportunityLifecycleBadge extends StatelessWidget {
  final String applicationStatus;
  final bool isCompact;

  const OpportunityLifecycleBadge({
    super.key,
    required this.applicationStatus,
    this.isCompact = true,
  });

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    String label;
    final stat = applicationStatus.toLowerCase().trim();

    switch (stat) {
      case 'open':
        dotColor = AppColors.eligible;
        label = 'Open';
        break;
      case 'upcoming':
        dotColor = AppColors.info;
        label = 'Upcoming';
        break;
      case 'notification_released':
        dotColor = const Color(0xFFA855F7);
        label = 'Notification Released';
        break;
      case 'awaiting_notification':
        dotColor = AppColors.pending;
        label = 'Awaiting Notification';
        break;
      case 'closed':
        dotColor = AppColors.ineligible;
        label = 'Closed';
        break;
      case 'archived':
        dotColor = AppColors.mutedText;
        label = 'Archived';
        break;
      default:
        dotColor = AppColors.primaryGreen;
        label = applicationStatus;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 7 : 9,
        vertical: isCompact ? 2.5 : 4,
      ),
      decoration: BoxDecoration(
        color: context.themeSurfaceElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: context.themeBorder, width: 1.0),
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
          const SizedBox(width: 5.5),
          Text(
            label,
            style: TextStyle(
              color: context.themeTextMain,
              fontSize: isCompact ? 10.5 : 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Official Provenance & Fact Verification Tier Badge
class VerificationTierBadge extends StatelessWidget {
  final String tier;
  final bool isCompact;

  const VerificationTierBadge({
    super.key,
    required this.tier,
    this.isCompact = true,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    IconData icon;
    String label;
    final upper = tier.toUpperCase().trim();

    if (upper == 'VERIFIED') {
      iconColor = AppColors.primaryGreen;
      icon = LucideIcons.badgeCheck;
      label = 'Official Verified';
    } else if (upper == 'PARTIALLY_VERIFIED') {
      iconColor = AppColors.warning;
      icon = LucideIcons.shieldCheck;
      label = 'Partially Verified';
    } else if (upper == 'UNDER_REVIEW') {
      iconColor = const Color(0xFFF97316);
      icon = LucideIcons.hourglass;
      label = 'Under Review';
    } else if (upper == 'EXPIRED') {
      iconColor = AppColors.mutedText;
      icon = LucideIcons.clock;
      label = 'Expired';
    } else {
      iconColor = AppColors.error;
      icon = LucideIcons.circleAlert;
      label = 'Unconfirmed';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2.5 : 4,
      ),
      decoration: BoxDecoration(
        color: context.themeSurfaceElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: context.themeBorder, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 11 : 13, color: iconColor),
          const SizedBox(width: 4.5),
          Text(
            label,
            style: TextStyle(
              color: context.themeTextMain,
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
