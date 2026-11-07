import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexam/core/constants/app_colors.dart';
import 'package:rexam/core/constants/app_dimensions.dart';
import 'package:rexam/core/theme/app_typography.dart';
import 'package:rexam/core/utils/currency_formatter.dart';
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
    final savedList = ref.watch(savedProvider);
    final isSaved = savedList.any((o) => o.id == opportunity.id);
    final isClosing = DateFormatter.isClosingSoon(opportunity.applicationDeadline);

    return InkWell(
      onTap: onTap,
      borderRadius: AppDimensions.roundedDefault,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppDimensions.roundedDefault,
          border: Border.all(
            color: isClosing ? AppColors.warning.withOpacity(0.4) : AppColors.border,
            width: AppDimensions.cardBorderWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Category & Bookmark
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space8,
                        vertical: AppDimensions.space2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBackground,
                        borderRadius: AppDimensions.roundedSmall,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        opportunity.category.label,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
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
                          color: AppColors.secondaryBackground,
                          borderRadius: AppDimensions.roundedSmall,
                        ),
                        child: Text(
                          '${opportunity.vacancies} Posts',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMain,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    size: 18,
                    color: isSaved ? AppColors.primaryGreen : AppColors.textMuted,
                  ),
                  onPressed: () {
                    ref.read(savedProvider.notifier).toggleSave(opportunity);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space8),

            // Row 2: Title
            Text(
              opportunity.title,
              style: AppTypography.cardTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimensions.space4),

            // Row 3: Organisation
            Text(
              opportunity.organisation,
              style: AppTypography.cardSubtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimensions.space12),

            // Row 4: Key Metadata grid
            Container(
              padding: const EdgeInsets.all(AppDimensions.space8),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: AppDimensions.roundedSmall,
              ),
              child: Row(
                children: [
                  // Deadline
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DEADLINE', style: AppTypography.label.copyWith(color: AppColors.textSubtle, fontSize: 10)),
                        const SizedBox(height: AppDimensions.space2),
                        Text(
                          DateFormatter.formatDate(opportunity.applicationDeadline),
                          style: AppTypography.caption.copyWith(
                            color: isClosing ? AppColors.warning : AppColors.textMain,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DateFormatter.daysRemaining(opportunity.applicationDeadline),
                          style: AppTypography.caption.copyWith(
                            color: isClosing ? AppColors.warning : AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 28, color: AppColors.border),
                  const SizedBox(width: AppDimensions.space8),
                  // Fee
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FEE', style: AppTypography.label.copyWith(color: AppColors.textSubtle, fontSize: 10)),
                        const SizedBox(height: AppDimensions.space2),
                        Text(
                          CurrencyFormatter.formatInr(opportunity.applicationFee),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMain,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          opportunity.applicationFee == null ? 'Exempted / Nil' : 'Standard',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 28, color: AppColors.border),
                  const SizedBox(width: AppDimensions.space8),
                  // Age
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AGE LIMIT', style: AppTypography.label.copyWith(color: AppColors.textSubtle, fontSize: 10)),
                        const SizedBox(height: AppDimensions.space2),
                        Text(
                          '${opportunity.minAge}–${opportunity.maxAge} yrs',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMain,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Relaxations apply',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space12),

            // Row 5: Eligibility & Verification Status footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const StatusBadge(
                  status: EligibilityStatus.eligible,
                  isCompact: true,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: AppDimensions.space4),
                    Text(
                      'Verified ${DateFormatter.formatDate(opportunity.lastVerifiedAt)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSubtle,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
