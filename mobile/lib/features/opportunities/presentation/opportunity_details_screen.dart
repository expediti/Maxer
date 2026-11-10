import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:rexam/core/constants/app_colors.dart';
import 'package:rexam/core/constants/app_dimensions.dart';
import 'package:rexam/core/theme/app_typography.dart';
import 'package:rexam/core/utils/currency_formatter.dart';
import 'package:rexam/core/utils/url_launcher_helper.dart';
import 'package:rexam/core/widgets/empty_state.dart';
import 'package:rexam/core/widgets/organisation_logo.dart';
import 'package:rexam/models/application_tracker.dart';
import 'package:rexam/features/applications/presentation/providers/applications_provider.dart';
import 'package:rexam/features/saved/presentation/providers/saved_provider.dart';
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
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text(
            'Track Application Stage',
            style: AppTypography.screenTitle.copyWith(fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record your application progress in your Rexam profile. Note that Rexam is an opportunity intelligence platform and does not submit forms on your behalf.',
                  style: TextStyle(color: AppColors.secondaryText, fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: AppDimensions.space16),

                DropdownButtonFormField<ApplicationStatus>(
                  initialValue: selectedStatus,
                  dropdownColor: AppColors.elevatedSurface,
                  style: const TextStyle(color: AppColors.primaryText, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Current Stage',
                    prefixIcon: Icon(LucideIcons.clipboardCheck, size: 18),
                  ),
                  items: ApplicationStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        status.label,
                        style: const TextStyle(fontSize: 13, color: AppColors.primaryText),
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
                  style: const TextStyle(color: AppColors.primaryText, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Roll No / Registration ID (Optional)',
                    prefixIcon: Icon(LucideIcons.hash, size: 18),
                  ),
                ),
                const SizedBox(height: AppDimensions.space12),

                TextField(
                  controller: notesController,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.primaryText, fontSize: 13),
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
              child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
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
                      style: const TextStyle(color: AppColors.primaryText),
                    ),
                    backgroundColor: AppColors.cardBackground,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.border),
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
    final isSaved = savedList.any((o) => o.id == opportunityId || o.slug == opportunityId);

    return opportunityAsync.when(
      data: (opportunity) {
        if (opportunity == null) {
          return Scaffold(
            backgroundColor: AppColors.mainBackground,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primaryText),
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
            backgroundColor: AppColors.mainBackground,
            appBar: AppBar(
              backgroundColor: AppColors.mainBackground,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primaryText, size: 20),
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
                style: AppTypography.screenTitle.copyWith(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    isSaved ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                    color: isSaved ? AppColors.white : AppColors.secondaryText,
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
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: AppColors.border),
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
                                    color: AppColors.elevatedSurface,
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    opportunity.category.label,
                                    style: const TextStyle(
                                      color: AppColors.secondaryText,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                if (opportunity.vacancies != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.elevatedSurface,
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.users, size: 12, color: AppColors.secondaryText),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${opportunity.vacancies} Posts',
                                          style: const TextStyle(
                                            color: AppColors.primaryText,
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
                                    ),
                                  ),
                                  const SizedBox(height: AppDimensions.space6),
                                  Text(
                                    '${opportunity.organisation} • ${opportunity.issuingAuthority}',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.secondaryText,
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
                            const Icon(LucideIcons.mapPin, size: 14, color: AppColors.secondaryText),
                            const SizedBox(width: 6),
                            Text(
                              opportunity.location,
                              style: AppTypography.caption.copyWith(color: AppColors.primaryText),
                            ),
                            if (opportunity.salaryOrPayScale != null) ...[
                              const SizedBox(width: AppDimensions.space16),
                              const Icon(LucideIcons.wallet, size: 14, color: AppColors.secondaryText),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  opportunity.salaryOrPayScale!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primaryText,
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
                    data: (rep) => _buildEligibilityCard(context, rep),
                    loading: () => Container(
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                          ),
                          SizedBox(width: AppDimensions.space12),
                          Text('Evaluating statutory eligibility...', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                        ],
                      ),
                    ),
                    error: (err, _) => Container(
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Text('Eligibility evaluation currently unavailable.', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Important Dates: Visually Structured Timeline
                  _buildSectionHeader('Official Schedule & Deadlines', LucideIcons.calendar),
                  const SizedBox(height: AppDimensions.space8),
                  _buildStructuredTimeline(opportunity),
                  const SizedBox(height: AppDimensions.space20),

                  // Statutory Eligibility Criteria
                  _buildSectionHeader('Statutory Eligibility Criteria', LucideIcons.shieldCheck),
                  const SizedBox(height: AppDimensions.space8),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCriterionRow(
                          'Age Limit Norms',
                          '${opportunity.minAge ?? 18} to ${opportunity.maxAge ?? 32} years (Category relaxations apply as per gazette)',
                        ),
                        _buildCriterionRow(
                          'Prescribed Qualifications',
                          opportunity.educationalQualifications.isNotEmpty
                              ? opportunity.educationalQualifications.join('\n')
                              : 'Refer to official gazette notification.',
                        ),
                        if (opportunity.eligibleStreams.isNotEmpty)
                          _buildCriterionRow('Eligible Disciplines / Branches', opportunity.eligibleStreams.join(', ')),
                        _buildCriterionRow(
                          'Academic Score Requirement',
                          opportunity.minPercentage != null && opportunity.minCgpa != null
                              ? 'Minimum ${opportunity.minPercentage!.toStringAsFixed(1)}% marks or ${opportunity.minCgpa!.toStringAsFixed(2)} CGPA'
                              : (opportunity.minCgpa != null
                                  ? 'Minimum ${opportunity.minCgpa!.toStringAsFixed(2)} CGPA on a ${opportunity.cgpaScaleMax.toStringAsFixed(0)}-point scale'
                                  : (opportunity.minPercentage != null
                                      ? 'Minimum ${opportunity.minPercentage!.toStringAsFixed(1)}% aggregate marks'
                                      : 'Passing marks in qualifying degree')),
                        ),
                        _buildCriterionRow('Nationality Requirement', opportunity.nationality),
                        _buildCriterionRow('Prior Work Experience', opportunity.workExperience),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Overview & Scope
                  _buildSectionHeader('Overview & Scope', LucideIcons.fileText),
                  const SizedBox(height: AppDimensions.space8),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      opportunity.overview.isNotEmpty ? opportunity.overview : 'No description provided.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.primaryText,
                        height: 1.5,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Application Fee Details
                  _buildSectionHeader('Application Fee & Concessions', LucideIcons.wallet),
                  const SizedBox(height: AppDimensions.space8),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Standard Application Fee:',
                              style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                            ),
                            Text(
                              CurrencyFormatter.format(opportunity.applicationFee),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.space12),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: AppDimensions.space12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(LucideIcons.info, size: 14, color: AppColors.secondaryText),
                            const SizedBox(width: AppDimensions.space8),
                            Expanded(
                              child: Text(
                                'Fee Exemptions: ${opportunity.feeExemptions.isNotEmpty ? opportunity.feeExemptions : "SC/ST/PwBD and Female candidates exempted."}',
                                style: const TextStyle(color: AppColors.secondaryText, fontSize: 12, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Official Sources & Verified Documents
                  _buildSectionHeader('Official Sources & Documents', LucideIcons.externalLink),
                  const SizedBox(height: AppDimensions.space8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        if (opportunity.officialNotificationPdfUrl != null) ...[
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: const Icon(LucideIcons.fileText, color: AppColors.white, size: 20),
                            title: const Text(
                              'Official Notification Gazette (PDF)',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primaryText),
                            ),
                            subtitle: const Text(
                              'Open verified gazette notification from conducting authority',
                              style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
                            ),
                            trailing: const Icon(LucideIcons.externalLink, size: 16, color: AppColors.secondaryText),
                            onTap: () => UrlLauncherHelper.openUrl(
                              context,
                              opportunity.officialNotificationPdfUrl,
                              fallbackTitle: 'Gazette Notification PDF',
                            ),
                          ),
                          const Divider(color: AppColors.border, height: 1),
                        ],
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: const Icon(LucideIcons.globe, color: AppColors.white, size: 20),
                          title: const Text(
                            'Official Application Portal',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primaryText),
                          ),
                          subtitle: Text(
                            opportunity.officialApplicationUrl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.secondaryText, fontSize: 11),
                          ),
                          trailing: const Icon(LucideIcons.externalLink, size: 16, color: AppColors.secondaryText),
                          onTap: () => UrlLauncherHelper.openUrl(
                            context,
                            opportunity.officialApplicationUrl,
                            fallbackTitle: 'Official Application Portal',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space32),
                ],
              ),
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.all(AppDimensions.space16),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(top: BorderSide(color: AppColors.border)),
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
                          side: const BorderSide(color: AppColors.border),
                          foregroundColor: AppColors.primaryText,
                          backgroundColor: AppColors.elevatedSurface,
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        onPressed: () => UrlLauncherHelper.openUrl(
                          context,
                          opportunity.officialApplicationUrl,
                          fallbackTitle: 'Official Application Portal',
                        ),
                        icon: const Icon(LucideIcons.externalLink, size: 16, color: AppColors.black),
                        label: const Text('Apply on Portal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.black,
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
      loading: () => const Scaffold(
        backgroundColor: AppColors.mainBackground,
        body: Center(child: CircularProgressIndicator(color: AppColors.white)),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: AppColors.mainBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primaryText),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text('Error loading examination details: $err', style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.secondaryText),
        const SizedBox(width: AppDimensions.space8),
        Text(
          title,
          style: AppTypography.sectionHeader.copyWith(
            color: AppColors.primaryText,
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
  Widget _buildStructuredTimeline(Opportunity opportunity) {
    final List<Map<String, dynamic>> timelineItems = [];

    if (opportunity.importantDates.containsKey('notification_date') ||
        opportunity.importantDates.containsKey('Notification Released')) {
      final d = opportunity.importantDates['notification_date'] ?? opportunity.importantDates['Notification Released'];
      if (d != null) {
        timelineItems.add({'title': 'Notification Released', 'date': d, 'isPast': DateTime.now().isAfter(d)});
      }
    }

    if (opportunity.importantDates.containsKey('application_start_date') ||
        opportunity.importantDates.containsKey('Application Window Opens')) {
      final d = opportunity.importantDates['application_start_date'] ?? opportunity.importantDates['Application Window Opens'];
      if (d != null) {
        timelineItems.add({'title': 'Application Window Opens', 'date': d, 'isPast': DateTime.now().isAfter(d)});
      }
    }

    if (opportunity.applicationDeadline != null) {
      timelineItems.add({
        'title': 'Application Deadline',
        'date': opportunity.applicationDeadline!,
        'isPast': DateTime.now().isAfter(opportunity.applicationDeadline!),
        'isHighlight': true,
      });
    }

    if (opportunity.importantDates.containsKey('fee_payment_deadline')) {
      final d = opportunity.importantDates['fee_payment_deadline'];
      if (d != null) {
        timelineItems.add({'title': 'Fee Payment Last Date', 'date': d, 'isPast': DateTime.now().isAfter(d)});
      }
    }

    if (opportunity.importantDates.containsKey('admit_card_date')) {
      final d = opportunity.importantDates['admit_card_date'];
      if (d != null) {
        timelineItems.add({'title': 'Admit Card Available', 'date': d, 'isPast': DateTime.now().isAfter(d)});
      }
    }

    if (opportunity.importantDates.containsKey('examination_start_date') ||
        opportunity.importantDates.containsKey('Scheduled Examination Date')) {
      final d = opportunity.importantDates['examination_start_date'] ?? opportunity.importantDates['Scheduled Examination Date'];
      if (d != null) {
        timelineItems.add({'title': 'Scheduled Examination Date', 'date': d, 'isPast': DateTime.now().isAfter(d)});
      }
    }

    if (opportunity.importantDates.containsKey('result_date')) {
      final d = opportunity.importantDates['result_date'];
      if (d != null) {
        timelineItems.add({'title': 'Result Announcement', 'date': d, 'isPast': DateTime.now().isAfter(d)});
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
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.border),
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
                              ? AppColors.white
                              : (isPast ? AppColors.mutedText : AppColors.cardBackground),
                          border: Border.all(
                            color: isHighlight ? AppColors.white : AppColors.border,
                            width: 2,
                          ),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 1.5,
                            color: AppColors.border,
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
                                  color: isHighlight ? AppColors.primaryText : AppColors.secondaryText,
                                  fontSize: 13,
                                  fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isPast ? 'Completed / Past' : (isHighlight ? 'Closing soon' : 'Upcoming'),
                                style: const TextStyle(
                                  color: AppColors.mutedText,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          DateFormat('d MMMM yyyy').format(dt),
                          style: TextStyle(
                            color: isHighlight ? AppColors.primaryText : AppColors.secondaryText,
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

  Widget _buildEligibilityCard(BuildContext context, EligibilityReport report) {
    Color dotColor;
    String statusTitle;

    switch (report.overallStatus) {
      case EligibilityStatus.eligible:
        dotColor = AppColors.eligible;
        statusTitle = 'Statutory Criteria Satisfied';
        break;
      case EligibilityStatus.potentiallyEligible:
        dotColor = AppColors.pending;
        statusTitle = 'Candidate Likely Eligible';
        break;
      case EligibilityStatus.notEligible:
        dotColor = AppColors.ineligible;
        statusTitle = 'Statutory Criteria Not Met';
        break;
      case EligibilityStatus.missingInformation:
      case EligibilityStatus.needsVerification:
        dotColor = AppColors.pending;
        statusTitle = 'Additional Profile Verification Required';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.border),
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
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (report.overallSummary.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.space8),
            Text(
              report.overallSummary,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.space12),
          InkWell(
            onTap: () => context.push('/eligibility/$opportunityId'),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View comprehensive evaluation breakdown',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                SizedBox(width: 4),
                Icon(LucideIcons.arrowRight, size: 14, color: AppColors.primaryText),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriterionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11.5, fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.primaryText,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
