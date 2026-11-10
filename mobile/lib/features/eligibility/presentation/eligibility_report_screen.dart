import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textMain, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/discover');
              }
            },
          ),
          title: Text(
            'Eligibility Assessment Report',
            style: AppTypography.screenTitle.copyWith(fontSize: 16),
          ),
        ),
      body: SafeArea(
        child: reportAsync.when(
          data: (report) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
              vertical: AppDimensions.space12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Banner with Overall Verdict
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.shieldCheck, size: 14, color: AppColors.primaryGreen),
                              const SizedBox(width: 6),
                              Text(
                                'OVERALL STATUTORY EVALUATION',
                                style: AppTypography.label.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          StatusBadge(status: report.overallStatus),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space12),
                      Text(
                        report.opportunityTitle,
                        style: AppTypography.screenTitle.copyWith(fontSize: 17, height: 1.3),
                      ),
                      const SizedBox(height: AppDimensions.space4),
                      Text(
                        report.organisation,
                        style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: AppDimensions.space12),
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.space12),
                        decoration: BoxDecoration(
                          color: AppColors.secondarySurface,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          report.overallSummary,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textMain,
                            height: 1.45,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space12),
                      Text(
                        'Evaluated deterministically at ${DateFormatter.formatDateTime(report.evaluatedAt)} against Gazette clauses.',
                        style: AppTypography.caption.copyWith(color: AppColors.textSubtle, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space20),

                // Individual Criteria Verification List
                Row(
                  children: [
                    const Icon(LucideIcons.checkSquare, size: 14, color: AppColors.primaryGreen),
                    const SizedBox(width: 6),
                    Text(
                      'CRITERION-BY-CRITERION VERIFICATION',
                      style: AppTypography.label.copyWith(
                        color: AppColors.primaryGreen,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space12),

                ...report.criteriaResults.map((result) => _buildCriterionCard(result)),
                const SizedBox(height: AppDimensions.space16),

                // Applicable Category Relaxations
                if (report.applicableRelaxations.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(LucideIcons.award, size: 14, color: AppColors.primaryGreen),
                      const SizedBox(width: 6),
                      Text(
                        'APPLICABLE STATUTORY RELAXATIONS',
                        style: AppTypography.label.copyWith(
                          color: AppColors.primaryGreen,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: report.applicableRelaxations.map((rel) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppDimensions.space6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(LucideIcons.check, size: 14, color: AppColors.primaryGreen),
                              const SizedBox(width: AppDimensions.space8),
                              Expanded(
                                child: Text(
                                  rel,
                                  style: AppTypography.body.copyWith(
                                    fontSize: 12,
                                    color: AppColors.textMain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),
                ],

                // Required Verification Documents
                Row(
                  children: [
                    const Icon(LucideIcons.fileCheck, size: 14, color: AppColors.primaryGreen),
                    const SizedBox(width: 6),
                    Text(
                      'MANDATORY EVIDENCE FOR DOCUMENT VERIFICATION (DV)',
                      style: AppTypography.label.copyWith(
                        color: AppColors.primaryGreen,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space8),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: report.requiredDocumentsForVerification.map((doc) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppDimensions.space8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(LucideIcons.fileText, size: 14, color: AppColors.primaryGreen),
                            const SizedBox(width: AppDimensions.space8),
                            Expanded(
                              child: Text(
                                doc,
                                style: AppTypography.body.copyWith(
                                  fontSize: 12,
                                  color: AppColors.textMain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppDimensions.space24),

                // Actions
                ElevatedButton.icon(
                  icon: const Icon(LucideIcons.arrowLeft, size: 16),
                  label: const Text('Back to Opportunity Details'),
                  onPressed: () => context.pop(),
                ),
                const SizedBox(height: AppDimensions.space8),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(LucideIcons.edit2, size: 14, color: AppColors.primaryGreen),
                    onPressed: () => context.go('/profile/wizard'),
                    label: const Text(
                      'Update Profile Attributes',
                      style: TextStyle(color: AppColors.primaryGreen, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),
              ],
            ),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.space24),
              child: Text(
                'Error generating report: $err',
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
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
        statusIcon = LucideIcons.checkCircle2;
        break;
      case RuleCheckStatus.conditionallyPassed:
        statusColor = AppColors.warning;
        statusIcon = LucideIcons.alertTriangle;
        break;
      case RuleCheckStatus.failed:
        statusColor = AppColors.error;
        statusIcon = LucideIcons.xCircle;
        break;
      case RuleCheckStatus.needsConfirmation:
        statusColor = AppColors.warning;
        statusIcon = LucideIcons.helpCircle;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space12),
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                result.criterionName,
                style: AppTypography.cardTitle.copyWith(fontSize: 14),
              ),
              Row(
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    result.status.label,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space8),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: AppDimensions.space8),

          _buildRow('Candidate Record:', result.candidateValue),
          _buildRow('Advertised Norm:', result.requirement),
          if (result.originalScore != null && result.originalScore != result.candidateValue)
            _buildRow('Original Score:', result.originalScore!),
          if (result.conversionFormula != null)
            _buildRow('Conversion:', result.conversionFormula!),
          if (result.convertedPercentage != null)
            _buildRow('Converted Percentage:', result.convertedPercentage!),
          if (result.conversionSource != null)
            _buildRow('Source:', result.conversionSource!),
          if (result.comparison != null)
            _buildRow('Comparison:', result.comparison!),
          _buildRow('Status:', result.status.label),
          const SizedBox(height: 6),
          Text(
            result.details,
            style: AppTypography.body.copyWith(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textMain,
            ),
          ),

          if (result.ruleEvidence != null) ...[
            const SizedBox(height: AppDimensions.space8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space8,
                vertical: AppDimensions.space4,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondarySurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(color: AppColors.border),
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMain,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
