import 'package:rexam/features/opportunities/domain/opportunity.dart';

enum RuleCheckStatus {
  passed('Satisfied'),
  conditionallyPassed('Satisfied with Relaxation'),
  failed('Not Satisfied'),
  needsConfirmation('Needs Confirmation');

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

  const EligibilityCriterionResult({
    required this.criterionName,
    required this.status,
    required this.candidateValue,
    required this.requirement,
    required this.details,
    this.ruleEvidence,
  });
}

class EligibilityReport {
  final String opportunityId;
  final String opportunityTitle;
  final String organisation;
  final EligibilityStatus overallStatus;
  final String overallSummary;
  final List<EligibilityCriterionResult> criteriaResults;
  final List<String> applicableRelaxations;
  final List<String> requiredDocumentsForVerification;
  final DateTime evaluatedAt;

  const EligibilityReport({
    required this.opportunityId,
    required this.opportunityTitle,
    required this.organisation,
    required this.overallStatus,
    required this.overallSummary,
    required this.criteriaResults,
    required this.applicableRelaxations,
    required this.requiredDocumentsForVerification,
    required this.evaluatedAt,
  });
}
