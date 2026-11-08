import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rexam/core/constants/app_colors.dart';
import 'package:rexam/core/constants/app_dimensions.dart';
import 'package:rexam/core/theme/app_typography.dart';
import 'package:rexam/core/utils/currency_formatter.dart';
import 'package:rexam/core/utils/date_formatter.dart';
import 'package:rexam/features/applications/domain/application_tracker.dart';
import 'package:rexam/features/applications/presentation/providers/applications_provider.dart';
import 'package:rexam/features/saved/presentation/providers/saved_provider.dart';
import 'package:rexam/features/opportunities/domain/opportunity.dart';
import 'package:rexam/features/opportunities/presentation/providers/opportunities_provider.dart';
import 'package:rexam/features/opportunities/presentation/widgets/status_badge.dart';

class OpportunityDetailsScreen extends ConsumerWidget {
  final String opportunityId;

  const OpportunityDetailsScreen({
    super.key,
    required this.opportunityId,
  });

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri != null) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open external link: $urlString')),
          );
        }
      }
    }
  }

  void _showTrackApplicationDialog(BuildContext context, WidgetRef ref, Opportunity opportunity) {
    final currentTracker = ref.read(applicationsProvider.notifier).getByOpportunityId(opportunity.id);
    ApplicationStatus selectedStatus = currentTracker?.status ?? ApplicationStatus.interested;
    final appNumberController = TextEditingController(text: currentTracker?.applicationNumber ?? '');
    final notesController = TextEditingController(text: currentTracker?.personalNotes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.roundedDefault,
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text('Track Application Status', style: AppTypography.screenTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record your application progress. Rexam is an opportunity intelligence platform and does not submit forms on your behalf.',
                  style: AppTypography.caption.copyWith(color: AppColors.warning),
                ),
                const SizedBox(height: AppDimensions.space16),

                DropdownButtonFormField<ApplicationStatus>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Current Stage'),
                  items: ApplicationStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.label, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedStatus = val);
                  },
                ),
                const SizedBox(height: AppDimensions.space12),

                TextField(
                  controller: appNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Roll No / Registration ID (Optional)',
                  ),
                ),
                const SizedBox(height: AppDimensions.space12),

                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Personal Notes / Reminders (Optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
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
                  const SnackBar(content: Text('Application tracker updated.')),
                );
              },
              child: const Text('Save Progress'),
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
    final isSaved = savedList.any((o) => o.id == opportunityId);
    final tracker = ref.watch(applicationsProvider.notifier).getByOpportunityId(opportunityId);

    return opportunityAsync.when(
      data: (opp) {
        if (opp == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: const Center(child: Text('Opportunity record not found.')),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(opp.organisation, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? AppColors.primaryGreen : AppColors.textMain,
                ),
                onPressed: () => ref.read(savedProvider.notifier).toggleSave(opp),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Share link copied: ${opp.officialApplicationUrl}')),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verification provenance banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space12, vertical: AppDimensions.space8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppDimensions.roundedSmall,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_outlined, size: 16, color: AppColors.primaryGreen),
                        const SizedBox(width: AppDimensions.space8),
                        Expanded(
                          child: Text(
                            'Verified from ${opp.sourceUrl} on ${DateFormatter.formatDate(opp.lastVerifiedAt)}',
                            style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // Category & Vacancies Tag
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space8, vertical: AppDimensions.space4),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBackground,
                          borderRadius: AppDimensions.roundedSmall,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(opp.category.label, style: AppTypography.caption.copyWith(color: AppColors.primaryGreen)),
                      ),
                      if (opp.vacancies != null) ...[
                        const SizedBox(width: AppDimensions.space8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space8, vertical: AppDimensions.space4),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppDimensions.roundedSmall,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text('${opp.vacancies} Vacancies', style: AppTypography.caption.copyWith(color: AppColors.textMain)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space12),

                  // 1. Opportunity Title
                  Text(opp.title, style: AppTypography.screenTitle.copyWith(fontSize: 22, height: 1.25)),
                  const SizedBox(height: AppDimensions.space8),

                  // 2. Issuing Authority
                  Text('${opp.organisation} • ${opp.issuingAuthority}', style: AppTypography.cardSubtitle),
                  const SizedBox(height: AppDimensions.space16),

                  // Eligibility Quick Card & Action
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppDimensions.roundedDefault,
                      border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ELIGIBILITY STATUS', style: AppTypography.label.copyWith(color: AppColors.primaryGreen)),
                            const StatusBadge(status: EligibilityStatus.eligible, isCompact: true),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.space8),
                        Text(
                          'Based on your profile, you meet age, degree, and reservation eligibility conditions.',
                          style: AppTypography.body,
                        ),
                        const SizedBox(height: AppDimensions.space12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.analytics_outlined, size: 16, color: AppColors.primaryGreen),
                          label: const Text('View Detailed Criterion Breakdown'),
                          onPressed: () => context.go('/eligibility/${opp.id}'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // 4. Overview
                  _buildSectionHeader('4. Overview & Purpose'),
                  Text(opp.overview, style: AppTypography.body),
                  const SizedBox(height: AppDimensions.space20),

                  // 6. Eligibility Criteria Summary
                  _buildSectionHeader('6. Eligibility Criteria Summary'),
                  Text(opp.eligibilityCriteriaSummary, style: AppTypography.body),
                  const SizedBox(height: AppDimensions.space20),

                  // 7 & 8. Age Limits & Relaxations
                  _buildSectionHeader('7 & 8. Age Limits & Statutory Relaxation'),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space12),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: AppDimensions.roundedDefault,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Standard Age Band: ${opp.minAge} to ${opp.maxAge} years', style: AppTypography.cardTitle),
                        const SizedBox(height: AppDimensions.space8),
                        const Divider(color: AppColors.border),
                        const SizedBox(height: AppDimensions.space8),
                        ...opp.categoryAgeRelaxation.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppDimensions.space6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(entry.key, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                                ),
                                Expanded(
                                  child: Text(entry.value, style: AppTypography.body.copyWith(fontSize: 13)),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // 9. Educational Qualifications
                  _buildSectionHeader('9. Prescribed Educational Qualifications'),
                  ...opp.educationalQualifications.map((qual) => _buildCheckItem(qual)),
                  const SizedBox(height: AppDimensions.space20),

                  // 10 & 11. Nationality & Gender
                  _buildSectionHeader('10 & 11. Nationality & Gender Requirements'),
                  _buildKeyValueRow('Nationality', opp.nationality),
                  _buildKeyValueRow('Gender Eligibility', opp.genderRequirements),
                  const SizedBox(height: AppDimensions.space20),

                  // 12. Work Experience
                  _buildSectionHeader('12. Work Experience Requirements'),
                  Text(opp.workExperience, style: AppTypography.body),
                  const SizedBox(height: AppDimensions.space20),

                  // 13. Application Fee & Exemptions
                  _buildSectionHeader('13. Application Fee & Fee Exemptions'),
                  _buildKeyValueRow('General Fee', CurrencyFormatter.formatInr(opp.applicationFee)),
                  _buildKeyValueRow('Exemptions / Concessions', opp.feeExemptions),
                  const SizedBox(height: AppDimensions.space20),

                  // 14. Required Documents Checklist
                  _buildSectionHeader('14. Mandatory Documents Checklist'),
                  ...opp.requiredDocuments.map((doc) => _buildCheckItem(doc)),
                  const SizedBox(height: AppDimensions.space20),

                  // 15. Important Dates
                  _buildSectionHeader('15. Important Official Dates'),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space12),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: AppDimensions.roundedDefault,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: opp.importantDates.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppDimensions.space8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                              Text(DateFormatter.formatDate(e.value), style: AppTypography.caption.copyWith(color: AppColors.textMain, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // 16 & 17. Selection & Exam Pattern
                  _buildSectionHeader('16 & 17. Selection Procedure & Pattern'),
                  Text(opp.selectionProcedure, style: AppTypography.body),
                  if (opp.examPattern != null) ...[
                    const SizedBox(height: AppDimensions.space8),
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.space12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppDimensions.roundedSmall,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(opp.examPattern!, style: AppTypography.bodyMuted.copyWith(fontSize: 13)),
                    ),
                  ],
                  const SizedBox(height: AppDimensions.space20),

                  // 18 & 19. Pay Scale & Location
                  _buildSectionHeader('18 & 19. Remuneration & Posting Location'),
                  if (opp.salaryOrPayScale != null) _buildKeyValueRow('Pay Scale / Stipend', opp.salaryOrPayScale!),
                  _buildKeyValueRow('Location', opp.location),
                  const SizedBox(height: AppDimensions.space20),

                  // 20. Application Instructions
                  _buildSectionHeader('20. Official Application Instructions'),
                  Text(opp.applicationInstructions, style: AppTypography.body),
                  const SizedBox(height: AppDimensions.space24),

                  // Official Verification Links (21, 22, 23)
                  _buildSectionHeader('21–23. Official Documents & Portal Links'),
                  if (opp.officialNotificationPdfUrl != null) ...[
                    OutlinedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.error),
                      label: const Text('Open Official Notification PDF'),
                      onPressed: () => _launchUrl(context, opp.officialNotificationPdfUrl!),
                    ),
                    const SizedBox(height: AppDimensions.space8),
                  ],
                  ElevatedButton.icon(
                    icon: const Icon(Icons.launch, size: 18),
                    label: const Text('Open Official Application Portal'),
                    onPressed: () => _launchUrl(context, opp.officialApplicationUrl),
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  Center(
                    child: TextButton(
                      onPressed: () => _launchUrl(context, opp.sourceUrl),
                      child: Text(
                        'Issuing Authority Website (${opp.sourceUrl})',
                        style: AppTypography.caption.copyWith(color: AppColors.textMuted, decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space24),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(AppDimensions.space16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(
                      tracker != null ? Icons.check_circle_outline : Icons.flag_outlined,
                      size: 16,
                      color: tracker != null ? AppColors.primaryGreen : AppColors.textMain,
                    ),
                    label: Text(tracker != null ? tracker.status.label : 'Track Status'),
                    onPressed: () => _showTrackApplicationDialog(context, ref, opp),
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _launchUrl(context, opp.officialApplicationUrl),
                    child: const Text('Apply on Portal'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space8),
      child: Text(
        title,
        style: AppTypography.sectionHeader.copyWith(color: AppColors.primaryGreen),
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, size: 16, color: AppColors.primaryGreen),
          const SizedBox(width: AppDimensions.space8),
          Expanded(child: Text(text, style: AppTypography.body.copyWith(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildKeyValueRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(key, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value, style: AppTypography.body.copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
