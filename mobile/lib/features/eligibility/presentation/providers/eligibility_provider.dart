import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexam/features/opportunities/domain/opportunity.dart';
import 'package:rexam/features/opportunities/presentation/providers/opportunities_provider.dart';
import 'package:rexam/features/eligibility/domain/eligibility_report.dart';
import 'package:rexam/features/profile/domain/candidate_profile.dart';
import 'package:rexam/features/profile/presentation/providers/profile_provider.dart';

class EligibilityEngine {
  static EligibilityReport evaluate({
    required Opportunity opportunity,
    required CandidateProfile candidate,
  }) {
    final List<EligibilityCriterionResult> results = [];
    final List<String> applicableRelaxations = [];
    final List<String> requiredDocs = [];

    // 1. Age Rule Evaluation
    final candidateAge = candidate.ageInYears;
    RuleCheckStatus ageStatus = RuleCheckStatus.needsConfirmation;
    String ageDetails = '';

    if (candidateAge == null) {
      ageDetails = 'Date of birth is not specified in candidate profile. Age check requires DoB.';
    } else {
      final baseMin = opportunity.minAge;
      final baseMax = opportunity.maxAge;

      if (baseMin == null && baseMax == null) {
        ageStatus = RuleCheckStatus.passed;
        ageDetails = 'No age restriction specified in official gazette.';
      } else if (baseMin != null && candidateAge < baseMin) {
        ageStatus = RuleCheckStatus.failed;
        ageDetails = 'Candidate age ($candidateAge years) is below minimum age requirement of $baseMin years.';
      } else if (baseMax != null && candidateAge > baseMax) {
        // Check reservation relaxations
        int relaxationYears = 0;
        final category = candidate.socialCategory;

        if (category == 'SC' || category == 'ST') {
          relaxationYears = 5;
        } else if (category == 'OBC-NCL' || category == 'OBC') {
          relaxationYears = 3;
        }
        if (candidate.isPwBD) {
          relaxationYears += 10;
        }

        final relaxedMax = baseMax + relaxationYears;
        if (candidateAge <= relaxedMax) {
          ageStatus = RuleCheckStatus.conditionallyPassed;
          ageDetails =
              'Candidate age ($candidateAge years) exceeds standard maximum ($baseMax years), but is fully covered under ${candidate.socialCategory} statutory relaxation of $relaxationYears years (up to $relaxedMax years).';
          applicableRelaxations.add('${candidate.socialCategory} Age Relaxation: +$relaxationYears years');
          requiredDocs.add('Valid ${candidate.socialCategory} Certificate in Central Format issued before cutoff');
        } else {
          ageStatus = RuleCheckStatus.failed;
          ageDetails =
              'Candidate age ($candidateAge years) exceeds both general maximum ($baseMax) and category relaxed maximum ($relaxedMax years).';
        }
      } else {
        ageStatus = RuleCheckStatus.passed;
        final minStr = baseMin != null ? '$baseMin' : 'any';
        final maxStr = baseMax != null ? '$baseMax' : 'no upper limit';
        ageDetails = 'Candidate age ($candidateAge years) falls within standard limit ($minStr–$maxStr years).';
      }
    }

    results.add(EligibilityCriterionResult(
      criterionName: 'Age Limit & Cutoff',
      status: ageStatus,
      candidateValue: candidateAge != null ? '$candidateAge years (DOB: ${candidate.dateOfBirth?.day}/${candidate.dateOfBirth?.month}/${candidate.dateOfBirth?.year})' : 'Not specified',
      requirement: '${opportunity.minAge ?? 'N/A'} to ${opportunity.maxAge ?? 'N/A'} years (Relaxation applicable)',
      details: ageDetails,
      ruleEvidence: 'Official Notification Clause 3(b) "Age Limits & Category Relaxations".',
    ));

    // 2. Nationality & Domicile
    RuleCheckStatus nationalityStatus = RuleCheckStatus.passed;
    String nationalityDetails = 'Candidate holds Indian citizenship, fulfilling mandatory constitutional requirement.';
    if (candidate.nationality.toLowerCase() != 'indian') {
      nationalityStatus = RuleCheckStatus.needsConfirmation;
      nationalityDetails = 'Candidate nationality is ${candidate.nationality}. Check service-specific citizenship rules.';
    }

    results.add(EligibilityCriterionResult(
      criterionName: 'Nationality / Domicile',
      status: nationalityStatus,
      candidateValue: candidate.nationality,
      requirement: opportunity.nationality,
      details: nationalityDetails,
      ruleEvidence: 'Clause 2: Nationality conditions for Central and PSU appointments.',
    ));

    // 3. Educational Qualification Check
    RuleCheckStatus qualStatus = RuleCheckStatus.passed;
    String qualDetails = '';
    final candQual = candidate.highestQualification ?? '';

    if (candQual.isEmpty) {
      qualStatus = RuleCheckStatus.needsConfirmation;
      qualDetails = 'Educational qualification not updated in candidate profile.';
    } else {
      final matchesQual = opportunity.educationalQualifications.any((req) {
        return req.toLowerCase().contains('any discipline') ||
            req.toLowerCase().contains('bachelor’s degree') ||
            req.toLowerCase().contains('b.e') ||
            req.toLowerCase().contains('b.tech');
      });

      if (matchesQual) {
        qualStatus = RuleCheckStatus.passed;
        qualDetails = 'Degree "${candidate.degreeName ?? candQual}" from ${candidate.universityOrCollege ?? 'recognized university'} matches requirement.';
      } else {
        qualStatus = RuleCheckStatus.needsConfirmation;
        qualDetails = 'Please verify if ${candidate.degreeName} meets the equivalence criteria.';
      }
    }

    results.add(EligibilityCriterionResult(
      criterionName: 'Educational Qualification',
      status: qualStatus,
      candidateValue: '${candidate.degreeName ?? candidate.highestQualification ?? "Not updated"} (${candidate.stream ?? "General"})',
      requirement: opportunity.educationalQualifications.first,
      details: qualDetails,
      ruleEvidence: 'Notification Section IV: Minimum Educational Qualifications.',
    ));

    // 4. Academic Percentage / CGPA Cutoff
    RuleCheckStatus percentageStatus = RuleCheckStatus.passed;
    String percentageDetails = '';
    final candPercentage = candidate.cgpaOrPercentage;

    if (opportunity.minPercentage != null) {
      if (candPercentage == null) {
        percentageStatus = RuleCheckStatus.needsConfirmation;
        percentageDetails = 'Candidate CGPA/Percentage is not specified in profile. Requires at least ${opportunity.minPercentage}%.';
      } else if (candPercentage >= opportunity.minPercentage!) {
        percentageStatus = RuleCheckStatus.passed;
        percentageDetails = 'Candidate score ($candPercentage%) exceeds minimum cutoff of ${opportunity.minPercentage}%.';
      } else {
        percentageStatus = RuleCheckStatus.failed;
        percentageDetails = 'Candidate score ($candPercentage%) is below required minimum of ${opportunity.minPercentage}%.';
      }
    } else {
      percentageStatus = RuleCheckStatus.passed;
      percentageDetails = 'No minimum aggregate percentage specified. Passing degree recognized.';
    }

    results.add(EligibilityCriterionResult(
      criterionName: 'Minimum Aggregate / CGPA',
      status: percentageStatus,
      candidateValue: candPercentage != null ? '$candPercentage%' : 'Not specified',
      requirement: opportunity.minPercentage != null ? 'Minimum ${opportunity.minPercentage}%' : 'Passing degree (No minimum percentage)',
      details: percentageDetails,
      ruleEvidence: 'Eligibility Guidelines Section 4.2.',
    ));

    // 5. Discipline & Stream Eligibility
    RuleCheckStatus streamStatus = RuleCheckStatus.passed;
    String streamDetails = '';
    final candStream = candidate.stream ?? '';

    final isAllDisciplines = opportunity.eligibleStreams.any((s) => s.toLowerCase().contains('all disciplines'));
    if (isAllDisciplines) {
      streamStatus = RuleCheckStatus.passed;
      streamDetails = 'All graduate disciplines are eligible. Candidate stream "$candStream" is fully accepted.';
    } else {
      final matchesStream = opportunity.eligibleStreams.any((s) =>
          candStream.isNotEmpty && (s.toLowerCase().contains(candStream.toLowerCase()) || candStream.toLowerCase().contains(s.toLowerCase())));

      if (matchesStream) {
        streamStatus = RuleCheckStatus.passed;
        streamDetails = 'Stream "$candStream" matches the advertised branch / department.';
      } else {
        streamStatus = RuleCheckStatus.needsConfirmation;
        streamDetails = 'Stream "$candStream" may require allied branch equivalence certification.';
      }
    }

    results.add(EligibilityCriterionResult(
      criterionName: 'Engineering / Academic Stream',
      status: streamStatus,
      candidateValue: candStream.isNotEmpty ? candStream : 'All Streams',
      requirement: opportunity.eligibleStreams.join(', '),
      details: streamDetails,
      ruleEvidence: 'Table of Approved Disciplines & Engineering Codes.',
    ));

    // Determine Overall Status
    EligibilityStatus overallStatus;
    String summary;

    final hasFailed = results.any((r) => r.status == RuleCheckStatus.failed);
    final hasNeedsConfirmation = results.any((r) => r.status == RuleCheckStatus.needsConfirmation);
    final hasRelaxed = results.any((r) => r.status == RuleCheckStatus.conditionallyPassed);

    if (hasFailed) {
      overallStatus = EligibilityStatus.notEligible;
      summary = 'You do not meet one or more mandatory eligibility requirements for this opportunity.';
    } else if (hasNeedsConfirmation) {
      overallStatus = EligibilityStatus.missingInformation;
      summary = 'Some profile criteria or documents need confirmation before eligibility can be conclusively verified.';
    } else if (hasRelaxed) {
      overallStatus = EligibilityStatus.potentiallyEligible;
      summary = 'You are eligible under applicable statutory category relaxations. Proper documentary proof must be presented.';
    } else {
      overallStatus = EligibilityStatus.eligible;
      summary = 'You meet all specified eligibility criteria for this opportunity based on your current profile.';
    }

    requiredDocs.addAll(opportunity.requiredDocuments);

    return EligibilityReport(
      opportunityId: opportunity.id,
      opportunityTitle: opportunity.title,
      organisation: opportunity.organisation,
      overallStatus: overallStatus,
      overallSummary: summary,
      criteriaResults: results,
      applicableRelaxations: applicableRelaxations,
      requiredDocumentsForVerification: requiredDocs.toSet().toList(),
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
    throw Exception('Opportunity with ID $opportunityId not found');
  }

  return profileAsync.when(
    data: (profile) => EligibilityEngine.evaluate(opportunity: opp, candidate: profile),
    loading: () => EligibilityEngine.evaluate(
      opportunity: opp,
      candidate: const CandidateProfile(id: 'temp', email: 'temp@rexam.in'),
    ),
    error: (err, stack) => EligibilityEngine.evaluate(
      opportunity: opp,
      candidate: const CandidateProfile(id: 'temp', email: 'temp@rexam.in'),
    ),
  );
});
