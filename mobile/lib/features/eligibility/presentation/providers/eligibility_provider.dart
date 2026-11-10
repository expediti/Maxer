import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexam/features/opportunities/domain/opportunity.dart';
import 'package:rexam/features/opportunities/presentation/providers/opportunities_provider.dart';
import 'package:rexam/features/eligibility/domain/eligibility_report.dart';
import 'package:rexam/features/profile/domain/candidate_profile.dart';
import 'package:rexam/features/profile/presentation/providers/profile_provider.dart';
import 'package:rexam/repositories/eligibility_repository.dart';

/// Single unified eligibility evaluation gateway for Riverpod providers and UI widgets.
/// Directly delegates to the authoritative DeterministicEligibilityRepository.
class EligibilityEngine {
  static EligibilityReport evaluate({
    required Opportunity opportunity,
    required CandidateProfile candidate,
  }) {
    return DeterministicEligibilityRepository.evaluate(
      candidate: candidate,
      examination: opportunity,
    );
  }

  static EligibilityReport insufficientInfo({
    required Opportunity opportunity,
    required String message,
  }) {
    return EligibilityReport(
      opportunityId: opportunity.id,
      opportunityTitle: opportunity.title,
      organisation: opportunity.organisation,
      overallStatus: EligibilityStatus.missingInformation,
      overallSummary: message,
      criteriaResults: const [
        EligibilityCriterionResult(
          criterionName: 'Candidate Profile Check',
          status: RuleCheckStatus.needsConfirmation,
          candidateValue: 'Profile information incomplete',
          requirement: 'Complete candidate profile with DOB, Category, and Education',
          details: 'Insufficient information to determine eligibility.',
          ruleEvidence: 'Statutory qualification analysis requires verified candidate attributes.',
        ),
      ],
      applicableRelaxations: const [],
      requiredDocumentsForVerification: opportunity.requiredDocuments,
      evaluatedAt: DateTime.now(),
    );
  }
}

final eligibilityReportProvider =
    FutureProvider.family<EligibilityReport, String>((ref, opportunityId) async {
  final profileAsync = ref.watch(profileProvider);
  final repo = ref.watch(opportunityRepositoryProvider);
  final opp = await repo.getOpportunityById(opportunityId);

  if (opp == null) {
    throw Exception('Opportunity with ID $opportunityId not found in official records.');
  }

  return profileAsync.when(
    data: (profile) => EligibilityEngine.evaluate(opportunity: opp, candidate: profile),
    loading: () => EligibilityEngine.insufficientInfo(
      opportunity: opp,
      message: 'Loading candidate profile attributes...',
    ),
    error: (err, stack) => EligibilityEngine.insufficientInfo(
      opportunity: opp,
      message: 'Insufficient information to determine eligibility.',
    ),
  );
});
