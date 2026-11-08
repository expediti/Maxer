import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexam/core/constants/app_colors.dart';
import 'package:rexam/core/constants/app_dimensions.dart';
import 'package:rexam/core/theme/app_typography.dart';
import 'package:rexam/core/utils/date_formatter.dart';
import 'package:rexam/features/eligibility/domain/eligibility_report.dart';
import 'package:rexam/features/eligibility/presentation/providers/eligibility_provider.dart';
import 'package:rexam/features/opportunities/presentation/widgets/status_badge.dart';

class EligibilityReportScreen extends ConsumerWidget {
  final String opportunityId;

  const EligibilityReportScreen({
    super.key,
    required this.opportunityId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(eligibilityReportProvider(opportunityId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Eligibility Assessment Report'),
      ),
      body: SafeArea(
        child: reportAsync.when(
          data: (report) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Banner with Overall Verdict
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppDimensions.roundedDefault,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('OVERALL EVALUATION', style: AppTypography.label.copyWith(color: AppColors.textSubtle)),
                          StatusBadge(status: report.overallStatus),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space12),
                      Text(report.opportunityTitle, style: AppTypography.screenTitle.copyWith(fontSize: 18)),
                      const SizedBox(height: AppDimensions.space4),
                      Text(report.organisation, style: AppTypography.cardSubtitle),
                      const SizedBox(height: AppDimensions.space12),
                      Text(
                        report.overallSummary,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textMain,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space12),
                      Text(
                        'Evaluated deterministically at ${DateFormatter.formatDateTime(report.evaluatedAt)} based on candidate profile attributes.',
                        style: AppTypography.caption.copyWith(color: AppColors.textSubtle, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space20),

                // Individual Criteria List
                Text('CRITERION-BY-CRITERION VERIFICATION', style: AppTypography.label.copyWith(color: AppColors.primaryGreen)),
                const SizedBox(height: AppDimensions.space12),

                ...report.criteriaResults.map((result) => _buildCriterionCard(result)),
                const SizedBox(height: AppDimensions.space20),

                // Applicable Category Relaxations
                if (report.applicableRelaxations.isNotEmpty) ...[
                  Text('APPLICABLE STATUTORY RELAXATIONS', style: AppTypography.label.copyWith(color: AppColors.primaryGreen)),
                  const SizedBox(height: AppDimensions.space8),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space12),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: AppDimensions.roundedDefault,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: report.applicableRelaxations.map((rel) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppDimensions.space4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.arrow_right, size: 18, color: AppColors.primaryGreen),
                              const SizedBox(width: AppDimensions.space4),
                              Expanded(child: Text(rel, style: AppTypography.body.copyWith(fontSize: 13))),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),
                ],

                // Required Verification Documents
                Text('MANDATORY EVIDENCE FOR DOCUMENT VERIFICATION (DV)', style: AppTypography.label.copyWith(color: AppColors.primaryGreen)),
                const SizedBox(height: AppDimensions.space8),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppDimensions.roundedDefault,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: report.requiredDocumentsForVerification.map((doc) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppDimensions.space8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.description_outlined, size: 16, color: AppColors.primaryGreen),
                            const SizedBox(width: AppDimensions.space8),
                            Expanded(child: Text(doc, style: AppTypography.body.copyWith(fontSize: 13))),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppDimensions.space24),

                // Actions
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back to Opportunity Details'),
                  onPressed: () => context.pop(),
                ),
                const SizedBox(height: AppDimensions.space8),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/profile/wizard'),
                    child: const Text('Update Profile Attributes'),
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
          error: (err, _) => Center(child: Text('Error generating report: $err')),
        ),
      ),
    );
  }

  Widget _buildCriterionCard(EligibilityCriterionResult result) {
    Color statusColor;
    IconData statusIcon;

    switch (result.status) {
      case RuleCheckStatus.passed:
        statusColor = AppColors.primaryGreen;
        statusIcon = Icons.check_circle_outline;
        break;
      case RuleCheckStatus.conditionallyPassed:
        statusColor = AppColors.warning;
        statusIcon = Icons.swap_horiz;
        break;
      case RuleCheckStatus.failed:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_outlined;
        break;
      case RuleCheckStatus.needsConfirmation:
        statusColor = AppColors.textMuted;
        statusIcon = Icons.help_outline;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space12),
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.roundedDefault,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(result.criterionName, style: AppTypography.cardTitle),
              Row(
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: AppDimensions.space4),
                  Text(
                    result.status.label,
                    style: AppTypography.caption.copyWith(color: statusColor, fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space8),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppDimensions.space8),

          _buildRow('Candidate Record:', result.candidateValue),
          _buildRow('Advertised Norm:', result.requirement),
          const SizedBox(height: AppDimensions.space6),
          Text(result.details, style: AppTypography.body.copyWith(fontSize: 13, height: 1.4)),

          if (result.ruleEvidence != null) ...[
            const SizedBox(height: AppDimensions.space8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space8, vertical: AppDimensions.space4),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: AppDimensions.roundedSmall,
              ),
              child: Text(
                'Evidence: ${result.ruleEvidence!}',
                style: AppTypography.caption.copyWith(color: AppColors.textSubtle, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11)),
          ),
          Expanded(
            child: Text(value, style: AppTypography.caption.copyWith(color: AppColors.textMain, fontWeight: FontWeight.w500, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
