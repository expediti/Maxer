import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:rexam/core/constants/app_colors.dart';
import 'package:rexam/core/constants/app_dimensions.dart';
import 'package:rexam/core/theme/app_typography.dart';
import 'package:rexam/core/utils/currency_formatter.dart';
import 'package:rexam/core/utils/date_formatter.dart';
import 'package:rexam/core/widgets/empty_state.dart';
import 'package:rexam/models/application_tracker.dart';
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
                  initialValue: selectedStatus,
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
                  SnackBar(
                    content: Text('Tracking updated: ${selectedStatus.label}'),
                    backgroundColor: AppColors.success,
                  ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final opportunityAsync = ref.watch(opportunityDetailProvider(opportunityId));
    final savedList = ref.watch(savedProvider);
    final isSaved = savedList.any((o) => o.id == opportunityId || o.slug == opportunityId);

    return opportunityAsync.when(
      data: (opportunity) {
        if (opportunity == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyStateView(
              icon: Icons.search_off_rounded,
              title: 'Examination Not Found',
              description: 'The requested opportunity record could not be found or may have been archived.',
            ),
          );
        }

        final deadline = opportunity.applicationDeadline;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(opportunity.organisation, style: const TextStyle(fontSize: 16)),
            actions: [
              IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isSaved ? AppColors.primaryBlue : null,
                ),
                tooltip: isSaved ? 'Bookmarked' : 'Save Opportunity',
                onPressed: () {
                  ref.read(savedProvider.notifier).toggleSave(opportunity);
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Container
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: AppDimensions.roundedDefault,
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
                                  borderRadius: AppDimensions.roundedSmall,
                                  border: Border.all(color: theme.colorScheme.outline),
                                ),
                                child: Text(
                                  opportunity.category.label,
                                  style: AppTypography.caption.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (opportunity.vacancies != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.successLight,
                                    borderRadius: AppDimensions.roundedSmall,
                                  ),
                                  child: Text(
                                    '${opportunity.vacancies} Vacancies',
                                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const StatusBadge(status: EligibilityStatus.eligible),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space12),

                      // Title
                      Text(
                        opportunity.title,
                        style: AppTypography.screenTitle.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space6),

                      // Organisation and Ministry
                      Text(
                        '${opportunity.organisation} • ${opportunity.issuingAuthority}',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space12),

                      // Location and Salary Chip
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primaryBlue),
                          const SizedBox(width: 4),
                          Text(opportunity.location, style: AppTypography.caption),
                          if (opportunity.salaryOrPayScale != null) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.account_balance_wallet_outlined, size: 14, color: AppColors.success),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                opportunity.salaryOrPayScale!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(color: AppColors.success),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),

                // Eligibility Banner (Deterministic)
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: AppDimensions.roundedDefault,
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 28),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Profile Matched & Eligible',
                              style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your degree, age cutoff, and reservation category satisfy all mandatory rules.',
                              style: TextStyle(color: Colors.black.withValues(alpha: 0.7), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/eligibility/${opportunity.id}'),
                        child: const Text('View Report', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space20),

                // Overview Section
                _buildSectionHeader('Overview & Description'),
                const SizedBox(height: AppDimensions.space8),
                Text(
                  opportunity.overview.isNotEmpty ? opportunity.overview : 'No description provided.',
                  style: AppTypography.body.copyWith(height: 1.5),
                ),
                const SizedBox(height: AppDimensions.space20),

                // Important Verified Dates Section
                _buildSectionHeader('Important Dates (Official Schedule)'),
                const SizedBox(height: AppDimensions.space8),
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: AppDimensions.roundedDefault,
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Column(
                    children: [
                      _buildDateTile(
                        'Application Deadline',
                        deadline != null ? DateFormat('d MMMM yyyy, HH:mm').format(deadline) : 'To be announced',
                        isUrgent: DateFormatter.isClosingSoon(deadline),
                      ),
                      if (opportunity.importantDates['Notification Date'] != null)
                        _buildDateTile(
                          'Notification Released',
                          DateFormat('d MMMM yyyy').format(opportunity.importantDates['Notification Date']!),
                        ),
                      if (opportunity.importantDates['Examination Date'] != null)
                        _buildDateTile(
                          'Scheduled Examination Date',
                          DateFormat('d MMMM yyyy').format(opportunity.importantDates['Examination Date']!),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space20),

                // Statutory Eligibility Requirements
                _buildSectionHeader('Statutory Eligibility Criteria'),
                const SizedBox(height: AppDimensions.space8),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: AppDimensions.roundedDefault,
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCriterionRow('Age Limit', '${opportunity.minAge ?? 18} to ${opportunity.maxAge ?? 35} years (Cutoff: Aug 2026)'),
                      _buildCriterionRow('Educational Qualifications', opportunity.educationalQualifications.join('\n')),
                      _buildCriterionRow('Eligible Streams / Branches', opportunity.eligibleStreams.join(', ')),
                      _buildCriterionRow('Minimum Percentage', opportunity.minPercentage != null ? '${opportunity.minPercentage}% marks' : 'Passing marks required'),
                      _buildCriterionRow('Nationality Requirement', opportunity.nationality),
                      _buildCriterionRow('Prior Work Experience', opportunity.workExperience),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space20),

                // Application Fee Details
                _buildSectionHeader('Application Fee & Concessions'),
                const SizedBox(height: AppDimensions.space8),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: AppDimensions.roundedDefault,
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('General / OBC / EWS Fee:'),
                          Text(
                            CurrencyFormatter.format(opportunity.applicationFee),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Text(
                        'Fee Exemptions: ${opportunity.feeExemptions.isNotEmpty ? opportunity.feeExemptions : "SC/ST/PwBD and Female candidates exempted."}',
                        style: AppTypography.caption.copyWith(color: AppColors.success),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space20),

                // Official Documents & Links
                _buildSectionHeader('Official Sources & Documents'),
                const SizedBox(height: AppDimensions.space8),
                if (opportunity.officialNotificationPdfUrl != null) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.error),
                    title: const Text('Official Notification Gazette PDF', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Download original gazette from conducting authority'),
                    trailing: const Icon(Icons.open_in_new, size: 16),
                    onTap: () => _launchUrl(context, opportunity.officialNotificationPdfUrl!),
                  ),
                  const Divider(),
                ],
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.public, color: AppColors.primaryBlue),
                  title: const Text('Official Application Portal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(opportunity.officialApplicationUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.open_in_new, size: 16),
                  onTap: () => _launchUrl(context, opportunity.officialApplicationUrl),
                ),
                const SizedBox(height: AppDimensions.space32),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(AppDimensions.space16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSecondaryBackground : Colors.white,
              border: Border(top: BorderSide(color: theme.colorScheme.outline)),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showTrackApplicationDialog(context, ref, opportunity),
                  icon: const Icon(Icons.add_task_rounded, size: 18),
                  label: const Text('Track Application'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(160, AppDimensions.buttonHeight),
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchUrl(context, opportunity.officialApplicationUrl),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Apply on Portal'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error loading examination details: $err')),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 3, height: 16, color: AppColors.primaryBlue),
        const SizedBox(width: AppDimensions.space8),
        Text(title, style: AppTypography.sectionHeader),
      ],
    );
  }

  Widget _buildDateTile(String label, String value, {bool isUrgent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isUrgent ? AppColors.warning : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriterionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}
