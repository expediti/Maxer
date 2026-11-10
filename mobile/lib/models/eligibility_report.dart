import 'examination.dart';

enum RuleCheckStatus {
  passed('Satisfied'),
  conditionallyPassed('Satisfied with Relaxation'),
  failed('Not Satisfied'),
  needsConfirmation('Requires Verification');

  final String label;
  const RuleCheckStatus(this.label);
}

class EligibilityCriterionResult {
  final String criterionName;
  final RuleCheckStatus status;
  final String candidateValue;
  final String requirement;
  final String details;
  final String? ruleEvidence;

  // Granular Academic Conversion Metadata
  final String? originalScore;
  final String? convertedPercentage;
  final String? conversionFormula;
  final String? conversionSource;
  final String? comparison;

  const EligibilityCriterionResult({
    required this.criterionName,
    required this.status,
    required this.candidateValue,
    required this.requirement,
    required this.details,
    this.ruleEvidence,
    this.originalScore,
    this.convertedPercentage,
    this.conversionFormula,
    this.conversionSource,
    this.comparison,
  });
}

class EligibilityReport {
  final String examinationId;
  final String examinationTitle;
  final String organisation;
  final EligibilityStatus overallStatus;
  final String overallSummary;
  final List<EligibilityCriterionResult> criteriaResults;
  final List<String> applicableRelaxations;
  final List<String> requiredDocumentsForVerification;
  final DateTime evaluatedAt;

  const EligibilityReport({
    String? examinationId,
    String? opportunityId,
    String? examinationTitle,
    String? opportunityTitle,
    required this.organisation,
    required this.overallStatus,
    required this.overallSummary,
    required this.criteriaResults,
    required this.applicableRelaxations,
    required this.requiredDocumentsForVerification,
    required this.evaluatedAt,
  })  : examinationId = examinationId ?? opportunityId ?? '',
        examinationTitle = examinationTitle ?? opportunityTitle ?? '';

  String get opportunityId => examinationId;
  String get opportunityTitle => examinationTitle;
}
