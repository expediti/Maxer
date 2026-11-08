import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexam/core/constants/app_colors.dart';
import 'package:rexam/core/constants/app_dimensions.dart';
import 'package:rexam/core/theme/app_typography.dart';
import 'package:rexam/core/utils/date_formatter.dart';
import 'package:rexam/features/opportunities/domain/opportunity.dart';
import 'package:rexam/features/opportunities/presentation/widgets/status_badge.dart';
import 'package:rexam/features/saved/presentation/providers/saved_provider.dart';

class OpportunityCard extends ConsumerWidget {
  final Opportunity opportunity;
  final VoidCallback onTap;

  const OpportunityCard({
    super.key,
    required this.opportunity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final savedList = ref.watch(savedProvider);
    final isSaved = savedList.any((o) => o.id == opportunity.id || o.slug == opportunity.id);
    final isClosing = DateFormatter.isClosingSoon(opportunity.applicationDeadline);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimensions.roundedDefault,
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.space16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: AppDimensions.roundedDefault,
            border: Border.all(
              color: isClosing
                  ? AppColors.warning.withValues(alpha: 0.6)
                  : theme.colorScheme.outline,
              width: AppDimensions.cardBorderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Category, Vacancies & Bookmark Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.space8,
                            vertical: AppDimensions.space2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
                            borderRadius: AppDimensions.roundedSmall,
                            border: Border.all(color: theme.colorScheme.outline),
                          ),
                          child: Text(
                            opportunity.category.label,
                            style: AppTypography.caption.copyWith(
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (opportunity.vacancies != null) ...[
                          const SizedBox(width: AppDimensions.space8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.space6,
                              vertical: AppDimensions.space2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
                              borderRadius: AppDimensions.roundedSmall,
                            ),
                            child: Text(
                              '${opportunity.vacancies} Posts',
                              style: AppTypography.caption.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      size: 20,
                      color: isSaved ? AppColors.primaryBlue : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                    onPressed: () {
                      ref.read(savedProvider.notifier).toggleSave(opportunity);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space10),

              // Title
              Text(
                opportunity.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.cardTitle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppDimensions.space4),

              // Organisation & Issuing Authority
              Row(
                children: [
                  const Icon(Icons.verified_outlined, size: 13, color: AppColors.primaryBlue),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      opportunity.organisation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardSubtitle.copyWith(
                        fontSize: 12.5,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space12),

              // Overview excerpt
              if (opportunity.overview.isNotEmpty) ...[
                Text(
                  opportunity.overview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppDimensions.space12),
              ],

              // Divider
              Divider(color: theme.colorScheme.outline, height: 1),
              const SizedBox(height: AppDimensions.space10),

              // Footer: Deadline, Eligibility & Location
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Deadline info
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: isClosing ? AppColors.warning : (isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        opportunity.applicationDeadline != null
                            ? DateFormatter.formatDeadline(opportunity.applicationDeadline!)
                            : 'Date to be announced',
                        style: AppTypography.caption.copyWith(
                          color: isClosing ? AppColors.warning : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                          fontWeight: isClosing ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),

                  // Eligibility Badge
                  const StatusBadge(
                    status: EligibilityStatus.eligible,
                    isCompact: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
