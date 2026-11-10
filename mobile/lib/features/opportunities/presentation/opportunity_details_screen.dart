import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:rexam/core/constants/app_colors.dart';
import 'package:rexam/core/constants/app_dimensions.dart';
import 'package:rexam/core/theme/app_typography.dart';
import 'package:rexam/core/utils/currency_formatter.dart';
import 'package:rexam/core/utils/date_formatter.dart';
import 'package:rexam/core/utils/url_launcher_helper.dart';
import 'package:rexam/core/widgets/empty_state.dart';
import 'package:rexam/core/widgets/organisation_logo.dart';
import 'package:rexam/models/application_tracker.dart';
import 'package:rexam/features/applications/presentation/providers/applications_provider.dart';
import 'package:rexam/features/saved/presentation/providers/saved_provider.dart';
import 'package:rexam/features/reminders/presentation/providers/reminders_provider.dart';
import 'package:rexam/features/opportunities/domain/opportunity.dart';
import 'package:rexam/features/opportunities/presentation/providers/opportunities_provider.dart';
import 'package:rexam/features/opportunities/presentation/widgets/status_badge.dart';
import 'package:rexam/features/eligibility/domain/eligibility_report.dart';
import 'package:rexam/features/eligibility/presentation/providers/eligibility_provider.dart';

class OpportunityDetailsScreen extends ConsumerWidget {
  final String opportunityId;

  const OpportunityDetailsScreen({
    super.key,
    required this.opportunityId,
  });

  void _showTrackApplicationDialog(BuildContext context, WidgetRef ref, Opportunity opportunity) {
    final currentTracker = ref.read(applicationsProvider.notifier).getByOpportunityId(opportunity.id);
    ApplicationStatus selectedStatus = currentTracker?.status ?? ApplicationStatus.interested;
    final appNumberController = TextEditingController(text: currentTracker?.applicationNumber ?? '');
    final notesController = TextEditingController(text: currentTracker?.personalNotes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: ctx.themeCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
            side: BorderSide(color: ctx.themeBorder),
          ),
          title: Text(
            'Track Application Stage',
            style: AppTypography.screenTitle.copyWith(fontSize: 18, color: ctx.themeTextMain),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record your application progress in your Rexam profile. Note that Rexam is an opportunity intelligence platform and does not submit forms on your behalf.',
                  style: TextStyle(color: ctx.themeTextMuted, fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: AppDimensions.space16),

                DropdownButtonFormField<ApplicationStatus>(
                  initialValue: selectedStatus,
                  dropdownColor: ctx.themeSurfaceElevated,
                  style: TextStyle(color: ctx.themeTextMain, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Current Stage',
                    prefixIcon: Icon(LucideIcons.clipboardCheck, size: 18),
                  ),
                  items: ApplicationStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        status.label,
                        style: TextStyle(fontSize: 13, color: ctx.themeTextMain),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedStatus = val);
                  },
                ),
                const SizedBox(height: AppDimensions.space12),

                TextField(
                  controller: appNumberController,
                  style: TextStyle(color: ctx.themeTextMain, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Roll No / Registration ID (Optional)',
                    prefixIcon: Icon(LucideIcons.hash, size: 18),
                  ),
                ),
                const SizedBox(height: AppDimensions.space12),

                TextField(
                  controller: notesController,
                  maxLines: 2,
                  style: TextStyle(color: ctx.themeTextMain, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Personal Notes / Checklist (Optional)',
                    prefixIcon: Icon(LucideIcons.fileText, size: 18),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: TextStyle(color: ctx.themeTextMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(applicationsProvider.notifier).addOrUpdate(
                      opportunity: opportunity,
                      status: selectedStatus,
                      applicationNumber: appNumberController.text.trim().isEmpty ? null : appNumberController.text.trim(),
                      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    );
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Tracking updated: ${selectedStatus.label}',
                      style: TextStyle(color: ctx.themeTextMain),
                    ),
                    backgroundColor: ctx.themeCard,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: ctx.themeBorder),
                    ),
                  ),
                );
              },
              child: const Text('Save Stage'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunityAsync = ref.watch(opportunityDetailProvider(opportunityId));
    final savedList = ref.watch(savedProvider);
    final remindersSet = ref.watch(remindersProvider);
    final isSaved = savedList.any((o) => o.id == opportunityId || o.slug == opportunityId);

    return opportunityAsync.when(
      data: (opportunity) {
        if (opportunity == null) {
          return Scaffold(
            backgroundColor: context.themeBackground,
            appBar: AppBar(
              backgroundColor: context.themeBackground,
              leading: IconButton(
                icon: Icon(LucideIcons.arrowLeft, color: context.themeTextMain),
                onPressed: () => context.pop(),
              ),
            ),
            body: const EmptyStateView(
              icon: LucideIcons.searchX,
              title: 'Examination Not Found',
              description: 'The requested opportunity record could not be found or may have been archived.',
            ),
          );
        }

        final reportAsync = ref.watch(eligibilityReportProvider(opportunity.id));

        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/discover');
            }
          },
          child: Scaffold(
            backgroundColor: context.themeBackground,
            appBar: AppBar(
              backgroundColor: context.themeBackground,
              elevation: 0,
              leading: IconButton(
                icon: Icon(LucideIcons.arrowLeft, color: context.themeTextMain, size: 20),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/discover');
                  }
                },
              ),
              title: Text(
                opportunity.organisation,
                style: AppTypography.screenTitle.copyWith(fontSize: 16, color: context.themeTextMain),
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                Builder(
                  builder: (ctx) {
                    final isReminded = remindersSet.contains(opportunity.id);
                    return IconButton(
                      icon: Icon(
                        isReminded ? LucideIcons.bellRing : LucideIcons.bell,
                        color: isReminded ? AppColors.primaryGreen : context.themeTextMuted,
                        size: 20,
                      ),
                      tooltip: isReminded ? 'Reminders Active' : 'Remind Me (Key Dates & Deadlines)',
                      onPressed: () {
                        ref.read(remindersProvider.notifier).toggleReminder(opportunity);
                        ScaffoldMessenger.of(ctx).showSnackBar(
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
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    isSaved ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                    color: isSaved ? (context.isDarkMode ? AppColors.white : AppColors.black) : context.themeTextMuted,
                    size: 20,
                  ),
                  tooltip: isSaved ? 'Bookmarked' : 'Save Opportunity',
                  onPressed: () {
                    ref.read(savedProvider.notifier).toggleSave(opportunity);
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prominent Top Identity Header Card
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    decoration: BoxDecoration(
                      color: context.themeCard,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tags & Status Row
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: context.themeSurfaceElevated,
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                    border: Border.all(color: context.themeBorder),
                                  ),
                                  child: Text(
                                    opportunity.category.label,
                                    style: TextStyle(
                                      color: context.themeTextMuted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                VerificationTierBadge(
                                  tier: opportunity.verificationTier,
                                  isCompact: true,
                                ),
                                if (opportunity.vacancies != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: context.themeSurfaceElevated,
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                      border: Border.all(color: context.themeBorder),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.users, size: 12, color: context.themeTextMuted),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${opportunity.vacancies} Posts',
                                          style: TextStyle(
                                            color: context.themeTextMain,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            reportAsync.when(
                              data: (rep) => StatusBadge(status: rep.overallStatus),
                              loading: () => const StatusBadge(status: EligibilityStatus.missingInformation),
                              error: (err, stack) => const StatusBadge(status: EligibilityStatus.missingInformation),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.space16),

                        // Prominent Organisation Logo + Title
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OrganisationLogo(
                              slug: opportunity.slug,
                              name: opportunity.organisation,
                              size: 64,
                              borderRadius: 12,
                            ),
                            const SizedBox(width: AppDimensions.space12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    opportunity.title,
                                    style: AppTypography.screenTitle.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      height: 1.25,
                                      color: context.themeTextMain,
                                    ),
                                  ),
                                  const SizedBox(height: AppDimensions.space6),
                                  Text(
                                    '${opportunity.organisation} • ${opportunity.issuingAuthority}',
                                    style: AppTypography.caption.copyWith(
                                      color: context.themeTextMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.space12),

                        // Location & Pay Scale
                        Row(
                          children: [
                            Icon(LucideIcons.mapPin, size: 14, color: context.themeTextMuted),
                            const SizedBox(width: 6),
                            Text(
                              opportunity.location,
                              style: AppTypography.caption.copyWith(color: context.themeTextMain),
                            ),
                            if (opportunity.salaryOrPayScale != null) ...[
                              const SizedBox(width: AppDimensions.space16),
                              Icon(LucideIcons.wallet, size: 14, color: context.themeTextMuted),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  opportunity.salaryOrPayScale!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption.copyWith(
                                    color: context.themeTextMain,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // Statutory Eligibility Assessment Card
                  reportAsync.when(
                    data: (rep) => _buildEligibilityCard(context, rep, opportunity),
                    loading: () => Container(
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      decoration: BoxDecoration(
                        color: context.themeCard,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                        border: Border.all(color: context.themeBorder),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: context.themeTextMain),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Text('Evaluating statutory eligibility...', style: TextStyle(color: context.themeTextMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    error: (err, _) => Container(
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      decoration: BoxDecoration(
                        color: context.themeCard,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                        border: Border.all(color: context.themeBorder),
                      ),
                      child: Text('Eligibility evaluation currently unavailable.', style: TextStyle(color: context.themeTextMuted, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // User-Controlled Examination Reminders Banner
                  Builder(
                    builder: (ctx) {
                      final isReminded = remindersSet.contains(opportunity.id);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: AppDimensions.space12),
                        decoration: BoxDecoration(
                          color: isReminded ? AppColors.greenTint : context.themeCard,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                          border: Border.all(
                            color: isReminded ? AppColors.primaryGreen.withValues(alpha: 0.5) : context.themeBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isReminded ? LucideIcons.bellRing : LucideIcons.bell,
                              size: 20,
                              color: isReminded ? AppColors.primaryGreen : context.themeTextMuted,
                            ),
                            const SizedBox(width: AppDimensions.space12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isReminded ? 'Deadline Reminders Active' : 'User-Controlled Reminders',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: isReminded ? AppColors.primaryGreen : ctx.themeTextMain,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isReminded
                                        ? 'Alarms scheduled for 7d, 3d, 2d, 24h before closing & exam date in IST.'
                                        : 'Separate from Save. Tap to get verified date & deadline alerts in IST.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ctx.themeTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isReminded,
                              activeColor: AppColors.primaryGreen,
                              onChanged: (val) {
                                ref.read(remindersProvider.notifier).toggleReminder(opportunity);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // Important Dates: Visually Structured Timeline
                  _buildSectionHeader(context, 'Official Schedule & Deadlines', LucideIcons.calendar),
                  const SizedBox(height: AppDimensions.space8),
                  _buildStructuredTimeline(context, opportunity),
                  const SizedBox(height: AppDimensions.space20),

                  // Statutory Eligibility Criteria
                  _buildSectionHeader(context, 'Statutory Eligibility Criteria', LucideIcons.shieldCheck),
                  const SizedBox(height: AppDimensions.space8),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    decoration: BoxDecoration(
                      color: context.themeCard,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCriterionRow(
                          context,
                          'Age Limit Norms',
                          '${opportunity.minAge ?? 18} to ${opportunity.maxAge ?? 32} years (Category relaxations apply as per gazette)',
                        ),
                        _buildCriterionRow(
                          context,
                          'Prescribed Qualifications',
                          opportunity.educationalQualifications.isNotEmpty
                              ? opportunity.educationalQualifications.join('\n')
                              : 'Refer to official gazette notification.',
                        ),
                        if (opportunity.eligibleStreams.isNotEmpty)
                          _buildCriterionRow(context, 'Eligible Disciplines / Branches', opportunity.eligibleStreams.join(', ')),
                        _buildCriterionRow(
                          context,
                          'Academic Score Requirement',
                          opportunity.minPercentage != null && opportunity.minCgpa != null
                              ? 'Minimum ${opportunity.minPercentage!.toStringAsFixed(1)}% marks or ${opportunity.minCgpa!.toStringAsFixed(2)} CGPA'
                              : (opportunity.minCgpa != null
                                  ? 'Minimum ${opportunity.minCgpa!.toStringAsFixed(2)} CGPA on a ${opportunity.cgpaScaleMax.toStringAsFixed(0)}-point scale'
                                  : (opportunity.minPercentage != null
                                      ? 'Minimum ${opportunity.minPercentage!.toStringAsFixed(1)}% aggregate marks'
                                      : 'Passing marks in qualifying degree')),
                        ),
                        _buildCriterionRow(context, 'Nationality Requirement', opportunity.nationality),
                        _buildCriterionRow(context, 'Prior Work Experience', opportunity.workExperience),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Overview & Scope
                  _buildSectionHeader(context, 'Overview & Scope', LucideIcons.fileText),
                  const SizedBox(height: AppDimensions.space8),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    decoration: BoxDecoration(
                      color: context.themeCard,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Text(
                      opportunity.overview.isNotEmpty ? opportunity.overview : 'No description provided.',
                      style: AppTypography.body.copyWith(
                        color: context.themeTextMain,
                        height: 1.5,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Application Fee Details
                  _buildSectionHeader(context, 'Application Fee & Concessions', LucideIcons.wallet),
                  const SizedBox(height: AppDimensions.space8),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    decoration: BoxDecoration(
                      color: context.themeCard,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Standard Application Fee:',
                              style: TextStyle(color: context.themeTextMuted, fontSize: 13),
                            ),
                            Text(
                              CurrencyFormatter.format(opportunity.applicationFee),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: context.themeTextMain,
                              ),
                            ),
                          ],
                        ),
                        if (opportunity.feeExemptions.isNotEmpty) ...[
                          const SizedBox(height: AppDimensions.space8),
                          Divider(color: context.themeBorder, height: 1),
                          const SizedBox(height: AppDimensions.space8),
                          Text(
                            'Exemptions & Concessions: ${opportunity.feeExemptions}',
                            style: TextStyle(
                              color: context.themeTextMuted,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Selection Procedure & Stages
                  _buildSectionHeader(context, 'Selection Process', LucideIcons.gitFork),
                  const SizedBox(height: AppDimensions.space8),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    decoration: BoxDecoration(
                      color: context.themeCard,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Text(
                      opportunity.selectionProcedure.isNotEmpty
                          ? opportunity.selectionProcedure
                          : 'Selection procedure details to be released with the detailed scheme.',
                      style: AppTypography.body.copyWith(
                        color: context.themeTextMain,
                        height: 1.45,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Official Gazette & Source Provenance Verification Card
                  _buildSectionHeader(context, 'Authoritative Source Provenance', LucideIcons.shieldCheck),
                  const SizedBox(height: AppDimensions.space8),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    decoration: BoxDecoration(
                      color: context.themeCard,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.shieldCheck, size: 16, color: AppColors.primaryGreen),
                            const SizedBox(width: AppDimensions.space8),
                            Text(
                              'Verified Authoritative Record',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: context.themeTextMain,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.space8),
                        Text(
                          'Conducting Authority: ${opportunity.organisation}',
                          style: TextStyle(color: context.themeTextMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Issuing Body: ${opportunity.issuingAuthority}',
                          style: TextStyle(color: context.themeTextMuted, fontSize: 12),
                        ),
                        if (opportunity.advertisementNumber != null && opportunity.advertisementNumber!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Advertisement No: ${opportunity.advertisementNumber}',
                            style: TextStyle(color: context.themeTextMuted, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 3),
                        Text(
                          'Last Verified: ${opportunity.lastVerifiedAt != null ? DateFormat("d MMMM yyyy, hh:mm a").format(opportunity.lastVerifiedAt!) : "Verified today"}',
                          style: TextStyle(color: context.themeTextMuted, fontSize: 12),
                        ),
                        if (opportunity.officialNotificationPdfUrl != null &&
                            opportunity.officialNotificationPdfUrl!.isNotEmpty) ...[
                          const SizedBox(height: AppDimensions.space12),
                          OutlinedButton.icon(
                            onPressed: () => UrlLauncherHelper.openUrl(
                              context,
                              opportunity.verifiedNotificationUrl ?? opportunity.officialNotificationPdfUrl,
                              fallbackTitle: 'Official Notification PDF',
                            ),
                            icon: const Icon(LucideIcons.fileText, size: 15),
                            label: const Text('View Official Notification Document'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(40),
                              side: BorderSide(color: context.themeBorder),
                              foregroundColor: context.themeTextMain,
                              backgroundColor: context.themeSurfaceElevated,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space32),
                ],
              ),
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.all(AppDimensions.space16),
              decoration: BoxDecoration(
                color: context.themeCard,
                border: Border(top: BorderSide(color: context.themeBorder)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        onPressed: () => _showTrackApplicationDialog(context, ref, opportunity),
                        icon: const Icon(LucideIcons.clipboardCheck, size: 16),
                        label: const Text('Track Application'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.themeBorder),
                          foregroundColor: context.themeTextMain,
                          backgroundColor: context.themeSurfaceElevated,
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        onPressed: () => UrlLauncherHelper.openApplicationPortal(
                          context,
                          applicationUrl: opportunity.verifiedApplicationUrl ?? opportunity.officialApplicationUrl,
                          notificationPdfUrl: opportunity.verifiedNotificationUrl ?? opportunity.officialNotificationPdfUrl,
                          sourcePortalUrl: opportunity.sourceUrl,
                          isApplicationUrlVerified: opportunity.isApplicationUrlVerified,
                          applicationUrlStatus: opportunity.applicationUrlStatus,
                        ),
                        icon: Icon(
                          LucideIcons.externalLink,
                          size: 16,
                          color: context.isDarkMode ? AppColors.black : AppColors.white,
                        ),
                        label: const Text('Apply on Portal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.isDarkMode ? AppColors.white : AppColors.black,
                          foregroundColor: context.isDarkMode ? AppColors.black : AppColors.white,
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: context.themeBackground,
        body: Center(child: CircularProgressIndicator(color: context.themeTextMain)),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: context.themeBackground,
        appBar: AppBar(
          backgroundColor: context.themeBackground,
          leading: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: context.themeTextMain),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text('Error loading examination details: $err', style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: context.themeTextMuted),
        const SizedBox(width: AppDimensions.space8),
        Text(
          title,
          style: AppTypography.sectionHeader.copyWith(
            color: context.themeTextMain,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Important Dates: Structured Timeline Component
  // ---------------------------------------------------------------------------
  Widget _buildStructuredTimeline(BuildContext context, Opportunity opportunity) {
    final List<Map<String, dynamic>> timelineItems = [];

    if (opportunity.importantDates.containsKey('notification_date') ||
        opportunity.importantDates.containsKey('Notification Released')) {
      final d = opportunity.importantDates['notification_date'] ?? opportunity.importantDates['Notification Released'];
      if (d != null) {
        timelineItems.add({
          'title': 'Notification Released',
          'date': d,
          'isPast': DateTime.now().isAfter(d),
          'isHighlight': false,
        });
      }
    }

    final start = opportunity.applicationStartDate;
    if (start != null) {
      timelineItems.add({
        'title': 'Applications Open',
        'date': start,
        'isPast': DateTime.now().isAfter(start),
        'isHighlight': false,
      });
    }

    final deadline = opportunity.applicationDeadline;
    if (deadline != null) {
      timelineItems.add({
        'title': 'Application Deadline',
        'date': deadline,
        'isPast': DateTime.now().isAfter(deadline),
        'isHighlight': true,
      });
    }

    if (opportunity.importantDates.containsKey('Admit Card Release') ||
        opportunity.importantDates.containsKey('admit_card_date')) {
      final d = opportunity.importantDates['Admit Card Release'] ?? opportunity.importantDates['admit_card_date'];
      if (d != null) {
        timelineItems.add({
          'title': 'Admit Card Release',
          'date': d,
          'isPast': DateTime.now().isAfter(d),
          'isHighlight': false,
        });
      }
    }

    final examDate = opportunity.importantDates['Examination Date'] ??
        opportunity.importantDates['prelims_date'] ??
        opportunity.importantDates['prelims_exam_date'];
    if (examDate != null) {
      timelineItems.add({
        'title': 'Examination Date',
        'date': examDate,
        'isPast': DateTime.now().isAfter(examDate),
        'isHighlight': false,
      });
    }

    if (opportunity.importantDates.containsKey('Result Declaration') ||
        opportunity.importantDates.containsKey('result_date')) {
      final d = opportunity.importantDates['Result Declaration'] ?? opportunity.importantDates['result_date'];
      if (d != null) {
        timelineItems.add({
          'title': 'Result Declaration',
          'date': d,
          'isPast': DateTime.now().isAfter(d),
          'isHighlight': false,
        });
      }
    }

    // Fallback if none in map: show application deadline
    if (timelineItems.isEmpty && opportunity.applicationDeadline != null) {
      timelineItems.add({
        'title': 'Application Deadline',
        'date': opportunity.applicationDeadline!,
        'isPast': DateTime.now().isAfter(opportunity.applicationDeadline!),
        'isHighlight': true,
      });
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        children: List.generate(timelineItems.length, (index) {
          final item = timelineItems[index];
          final isLast = index == timelineItems.length - 1;
          final DateTime dt = item['date'] as DateTime;
          final bool isPast = item['isPast'] as bool;
          final bool isHighlight = item['isHighlight'] == true;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline Line and Node
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isHighlight
                              ? (context.isDarkMode ? AppColors.white : AppColors.black)
                              : (isPast ? AppColors.mutedText : context.themeCard),
                          border: Border.all(
                            color: isHighlight
                                ? (context.isDarkMode ? AppColors.white : AppColors.black)
                                : context.themeBorder,
                            width: 2,
                          ),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 1.5,
                            color: context.themeBorder,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.space8),

                // Milestone Information
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : AppDimensions.space16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String,
                                style: TextStyle(
                                  color: isHighlight ? context.themeTextMain : context.themeTextMuted,
                                  fontSize: 13,
                                  fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isPast ? 'Completed / Past' : (isHighlight ? 'Closing soon' : 'Upcoming'),
                                style: TextStyle(
                                  color: context.themeTextSubtle,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          DateFormat('d MMMM yyyy').format(dt),
                          style: TextStyle(
                            color: isHighlight ? context.themeTextMain : context.themeTextMuted,
                            fontSize: 12.5,
                            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEligibilityCard(BuildContext context, EligibilityReport report, Opportunity opportunity) {
    Color dotColor;
    String statusTitle;
    String statusSummary;

    final isInfoIncomplete = report.overallStatus == EligibilityStatus.missingInformation ||
        report.overallStatus == EligibilityStatus.needsVerification ||
        opportunity.uncertainFields.isNotEmpty;

    if (isInfoIncomplete) {
      dotColor = AppColors.pending;
      statusTitle = 'Eligibility Information Incomplete';
      statusSummary = 'Eligibility cannot be confirmed because official information is incomplete.';
    } else {
      switch (report.overallStatus) {
        case EligibilityStatus.eligible:
          dotColor = AppColors.eligible;
          statusTitle = 'Statutory Criteria Satisfied';
          statusSummary = report.overallSummary;
          break;
        case EligibilityStatus.potentiallyEligible:
          dotColor = AppColors.pending;
          statusTitle = 'Candidate Likely Eligible';
          statusSummary = report.overallSummary;
          break;
        case EligibilityStatus.notEligible:
          dotColor = AppColors.ineligible;
          statusTitle = 'Statutory Criteria Not Met';
          statusSummary = report.overallSummary;
          break;
        case EligibilityStatus.missingInformation:
        case EligibilityStatus.needsVerification:
          dotColor = AppColors.pending;
          statusTitle = 'Eligibility Information Incomplete';
          statusSummary = 'Eligibility cannot be confirmed because official information is incomplete.';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Text(
                  statusTitle,
                  style: TextStyle(
                    color: context.themeTextMain,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            statusSummary,
            style: TextStyle(
              color: context.themeTextMuted,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppDimensions.space12),
          InkWell(
            onTap: () => context.push('/eligibility/$opportunityId'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View comprehensive evaluation breakdown',
                  style: TextStyle(
                    color: context.themeTextMain,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(LucideIcons.arrowRight, size: 14, color: context.themeTextMain),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriterionRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: context.themeTextMuted, fontSize: 11.5, fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: context.themeTextMain,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
