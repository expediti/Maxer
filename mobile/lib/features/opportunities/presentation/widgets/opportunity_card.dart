import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rexam/core/constants/app_colors.dart';
import 'package:rexam/core/constants/app_dimensions.dart';
import 'package:rexam/core/theme/app_typography.dart';
import 'package:rexam/core/utils/date_formatter.dart';
import 'package:rexam/core/widgets/organisation_logo.dart';
import 'package:rexam/features/opportunities/domain/opportunity.dart';
import 'package:rexam/features/opportunities/presentation/widgets/status_badge.dart';
import 'package:rexam/features/saved/presentation/providers/saved_provider.dart';
import 'package:rexam/features/reminders/presentation/providers/reminders_provider.dart';
import 'package:rexam/features/profile/presentation/providers/profile_provider.dart';
import 'package:rexam/models/eligibility_report.dart';
import 'package:rexam/repositories/eligibility_repository.dart';

class OpportunityCard extends ConsumerWidget {
  final Opportunity opportunity;
  final VoidCallback onTap;
  final bool showEligibilityDetails;
  final EligibilityReport? customReport;

  const OpportunityCard({
    super.key,
    required this.opportunity,
    required this.onTap,
    this.showEligibilityDetails = false,
    this.customReport,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedList = ref.watch(savedProvider);
    final remindersSet = ref.watch(remindersProvider);
    final profileAsync = ref.watch(profileProvider);
    final isSaved = savedList.any((o) => o.id == opportunity.id || o.slug == opportunity.id);
    final isReminded = remindersSet.contains(opportunity.id);
    final isClosing = DateFormatter.isClosingSoon(opportunity.applicationDeadline);
    final daysLeft = opportunity.applicationDeadline?.difference(DateTime.now()).inDays;

    // Authoritative Eligibility Evaluation
    final candidateProfile = profileAsync.valueOrNull;
    final report = customReport ??
        (candidateProfile != null
            ? DeterministicEligibilityRepository.evaluate(
                candidate: candidateProfile,
                examination: opportunity,
              )
            : null);

    final status = report?.overallStatus ?? EligibilityStatus.needsVerification;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.space16),
          decoration: BoxDecoration(
            color: context.themeCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
            border: Border.all(
              color: isClosing ? AppColors.warning.withValues(alpha: 0.6) : context.themeBorder,
              width: AppDimensions.cardBorderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Organisation Logo + Title & Department + Bookmark Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrganisationLogo(
                    slug: opportunity.slug,
                    name: opportunity.organisation,
                    size: 42.0,
                    borderRadius: 10.0,
                  ),
                  const SizedBox(width: AppDimensions.space12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opportunity.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.themeTextMain,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          opportunity.organisation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            fontSize: 12.5,
                            color: context.themeTextMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          isReminded ? LucideIcons.bellRing : LucideIcons.bell,
                          size: 18,
                          color: isReminded ? AppColors.primaryGreen : AppColors.mutedText,
                        ),
                        tooltip: isReminded ? 'Reminders Active' : 'Remind Me',
                        onPressed: () {
                          ref.read(remindersProvider.notifier).toggleReminder(opportunity);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isReminded
                                    ? 'Reminders disabled for ${opportunity.title}'
                                    : 'Reminders enabled (7d, 3d, 2d, 24h & Exam Date in IST)',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: AppDimensions.space8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          isSaved ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                          size: 19,
                          color: isSaved ? (context.isDarkMode ? AppColors.white : AppColors.black) : AppColors.mutedText,
                        ),
                        tooltip: isSaved ? 'Bookmarked' : 'Save Opportunity',
                        onPressed: () {
                          ref.read(savedProvider.notifier).toggleSave(opportunity);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space12),

              // Badges Row: Status, Category, State, Vacancies, Salary/Stipend
              Wrap(
                spacing: AppDimensions.space8,
                runSpacing: 4,
                children: [
                  OpportunityLifecycleBadge(
                    applicationStatus: opportunity.applicationStatus,
                    isCompact: true,
                  ),
                  VerificationTierBadge(
                    tier: opportunity.verificationTier,
                    isCompact: true,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.themeSurfaceElevated,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Text(
                      opportunity.category.label,
                      style: AppTypography.caption.copyWith(
                        color: context.themeTextMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (opportunity.state != null && opportunity.state!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.themeSurfaceElevated,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        border: Border.all(color: context.themeBorder),
                      ),
                      child: Text(
                        opportunity.state!,
                        style: AppTypography.caption.copyWith(
                          color: context.themeTextMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (opportunity.vacancies != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.themeSurfaceElevated,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        border: Border.all(color: context.themeBorder),
                      ),
                      child: Text(
                        opportunity.category == ExaminationCategory.scholarship
                            ? '${opportunity.vacancies} Slots'
                            : '${opportunity.vacancies} Posts',
                        style: AppTypography.caption.copyWith(
                          color: context.themeTextMain,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (opportunity.salaryOrPayScale != null && opportunity.salaryOrPayScale!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.themeSurfaceElevated,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        border: Border.all(color: context.themeBorder),
                      ),
                      child: Text(
                        opportunity.salaryOrPayScale!,
                        style: AppTypography.caption.copyWith(
                          color: context.themeTextMain,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (opportunity.acceptsFinalYearStudents)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.themeSurfaceElevated,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        border: Border.all(color: context.themeBorder),
                      ),
                      child: Text(
                        'Final Year Appearing Accepted',
                        style: TextStyle(
                          color: context.themeTextMain,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              // Overview excerpt if available
              if (opportunity.overview.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.space10),
                Text(
                  opportunity.overview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.secondaryText,
                    height: 1.4,
                  ),
                ),
              ],

              // Detailed Eligibility Reasons & Relaxations (when in Eligible For Me section or requested)
              if (showEligibilityDetails && report != null) ...[
                const SizedBox(height: AppDimensions.space12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.space10),
                  decoration: BoxDecoration(
                    color: context.themeSurfaceElevated,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(color: context.themeBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.shieldCheck, size: 14, color: AppColors.eligible),
                          const SizedBox(width: 6),
                          Text(
                            'Why You Qualify',
                            style: AppTypography.caption.copyWith(
                              color: context.themeTextMain,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Top 2 passing criteria summaries
                      ...report.criteriaResults
                          .where((c) =>
                              c.status == RuleCheckStatus.passed ||
                              c.status == RuleCheckStatus.conditionallyPassed)
                          .take(2)
                          .map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 3.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('• ',
                                        style: TextStyle(color: context.themeTextMuted, fontSize: 11)),
                                    Expanded(
                                      child: Text(
                                        c.details,
                                        style: TextStyle(
                                          color: context.themeTextMuted,
                                          fontSize: 11.5,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                      if (report.applicableRelaxations.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(LucideIcons.sparkles, size: 12, color: AppColors.pending),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Relaxations applied: ${report.applicableRelaxations.join("; ")}',
                                style: TextStyle(
                                  color: context.themeTextMain,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppDimensions.space12),
              Divider(color: context.themeBorder, height: 1),
              const SizedBox(height: AppDimensions.space10),

              // Footer: Deadline / Countdown and Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.clock,
                        size: 13,
                        color: isClosing ? AppColors.warning : AppColors.mutedText,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        opportunity.applicationDeadline != null
                            ? DateFormatter.formatDeadline(opportunity.applicationDeadline!)
                            : 'Date not announced',
                        style: AppTypography.caption.copyWith(
                          color: isClosing ? AppColors.warning : AppColors.secondaryText,
                          fontWeight: isClosing ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 11.5,
                        ),
                      ),
                      if (daysLeft != null && daysLeft > 0 && daysLeft <= 14) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.warningBg,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '$daysLeft d left',
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  StatusBadge(
                    status: status,
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
