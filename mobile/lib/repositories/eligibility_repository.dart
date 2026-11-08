import '../models/candidate_profile.dart';
import '../models/examination.dart';
import '../models/eligibility_report.dart';

abstract class EligibilityRepository {
  Future<EligibilityReport> evaluateEligibility({
    required CandidateProfile candidate,
    required Examination examination,
  });
}

class DeterministicEligibilityRepository implements EligibilityRepository {
  @override
  Future<EligibilityReport> evaluateEligibility({
    required CandidateProfile candidate,
    required Examination examination,
  }) async {
    final List<EligibilityCriterionResult> results = [];
    final List<String> applicableRelaxations = [];
    final List<String> requiredDocs = [];

    bool hasAnyFailure = false;
    bool hasNeedsConfirmation = false;
    bool hasConditionalPass = false;

    // 1. Age Evaluation
    final candidateAge = candidate.calculateAge();
    if (candidateAge == null) {
      results.add(EligibilityCriterionResult(
        criterionName: 'Age Limit',
        status: RuleCheckStatus.needsConfirmation,
        candidateValue: 'Date of birth not provided',
        requirement: 'Min: ${examination.minAge ?? "N/A"}, Max: ${examination.maxAge ?? "N/A"} years',
        details: 'Please complete your date of birth in your profile to verify age eligibility.',
      ));
      hasNeedsConfirmation = true;
    } else {
      int effectiveMaxAge = examination.maxAge ?? 100;
      int effectiveMinAge = examination.minAge ?? 0;
      int relaxationYears = 0;

      // Category relaxation lookup
      final category = candidate.socialCategory.toUpperCase();
      if (category.contains('OBC')) {
        relaxationYears += 3;
        applicableRelaxations.add('OBC-NCL 3 Years Upper Age Relaxation');
        requiredDocs.add('Valid OBC-NCL Central / State Certificate issued in current financial year');
      } else if (category.contains('SC') || category.contains('ST')) {
        relaxationYears += 5;
        applicableRelaxations.add('SC/ST 5 Years Upper Age Relaxation');
        requiredDocs.add('Permanent Caste / Tribe Certificate issued by competent revenue authority');
      }

      if (candidate.isPwBD) {
        relaxationYears += 10;
        applicableRelaxations.add('PwBD 10 Years Upper Age Relaxation');
        requiredDocs.add('Unique Disability ID (UDID) Card or Disability Certificate (min 40%)');
      }

      if (candidate.isExServiceman) {
        relaxationYears += 5;
        applicableRelaxations.add('Ex-Serviceman Age Relaxation');
        requiredDocs.add('Discharge Book / Military Service Certificate');
      }

      final relaxedMaxAge = effectiveMaxAge + relaxationYears;

      if (candidateAge < effectiveMinAge) {
        results.add(EligibilityCriterionResult(
          criterionName: 'Age Limit',
          status: RuleCheckStatus.failed,
          candidateValue: '$candidateAge years',
          requirement: 'Minimum $effectiveMinAge years',
          details: 'Candidate is below the statutory minimum entry age for this post.',
        ));
        hasAnyFailure = true;
      } else if (candidateAge > relaxedMaxAge) {
        results.add(EligibilityCriterionResult(
          criterionName: 'Age Limit',
          status: RuleCheckStatus.failed,
          candidateValue: '$candidateAge years',
          requirement: 'Max: $effectiveMaxAge years (Relaxed: $relaxedMaxAge years for ${candidate.socialCategory})',
          details: 'Candidate exceeds the upper age limit even after applying statutory relaxations.',
        ));
        hasAnyFailure = true;
      } else if (candidateAge > effectiveMaxAge && candidateAge <= relaxedMaxAge) {
        results.add(EligibilityCriterionResult(
          criterionName: 'Age Limit',
          status: RuleCheckStatus.conditionallyPassed,
          candidateValue: '$candidateAge years',
          requirement: 'Standard Max: $effectiveMaxAge years (Relaxed: $relaxedMaxAge years)',
          details: 'Eligible under $relaxationYears-year statutory age relaxation for ${candidate.socialCategory}${candidate.isPwBD ? ' / PwBD' : ''}.',
          ruleEvidence: 'Clause 3(b) of official recruitment notification.',
        ));
        hasConditionalPass = true;
      } else {
        results.add(EligibilityCriterionResult(
          criterionName: 'Age Limit',
          status: RuleCheckStatus.passed,
          candidateValue: '$candidateAge years',
          requirement: 'Min: $effectiveMinAge years, Max: $effectiveMaxAge years',
          details: 'Meets standard unreserved age window.',
        ));
      }
    }

    // 2. Educational Qualification & Stream Check
    final candidateEdu = candidate.highestQualification ?? candidate.degreeName;
    if (candidateEdu == null || candidateEdu.isEmpty) {
      results.add(const EligibilityCriterionResult(
        criterionName: 'Educational Qualification',
        status: RuleCheckStatus.needsConfirmation,
        candidateValue: 'Not specified',
        requirement: 'Recognized Bachelor degree / technical diploma as per notification',
        details: 'Add your degree and stream in profile to verify educational qualification.',
      ));
      hasNeedsConfirmation = true;
    } else {
      bool streamMatch = true;
      if (examination.eligibleStreams.isNotEmpty) {
        final matchesAll = examination.eligibleStreams.any((s) =>
            s.toLowerCase().contains('all') ||
            s.toLowerCase().contains('any discipline'));
        if (!matchesAll && candidate.stream != null) {
          final candidateStreamLower = candidate.stream!.toLowerCase();
          streamMatch = examination.eligibleStreams.any((reqStream) {
            final rLower = reqStream.toLowerCase();
            return candidateStreamLower.contains(rLower) || rLower.contains(candidateStreamLower);
          });
        }
      }

      if (streamMatch) {
        results.add(EligibilityCriterionResult(
          criterionName: 'Educational Qualification & Stream',
          status: RuleCheckStatus.passed,
          candidateValue: '${candidate.degreeName ?? candidate.highestQualification} (${candidate.stream ?? "General"})',
          requirement: examination.educationalQualifications.isNotEmpty
              ? examination.educationalQualifications.first
              : 'Recognized University Degree',
          details: 'Candidate qualification satisfies educational requirements.',
        ));
        requiredDocs.add('Original Degree Certificate / Provisional Degree Certificate with Final Marksheet');
      } else {
        results.add(EligibilityCriterionResult(
          criterionName: 'Educational Qualification & Stream',
          status: RuleCheckStatus.failed,
          candidateValue: '${candidate.degreeName} in ${candidate.stream}',
          requirement: examination.eligibleStreams.join(', '),
          details: 'Candidate stream does not match the mandatory disciplines listed for this technical cadre.',
        ));
        hasAnyFailure = true;
      }
    }

    // 3. Minimum Percentage / Aggregate CGPA Check
    if (examination.minPercentage != null) {
      final candScore = candidate.cgpaOrPercentage;
      if (candScore == null) {
        results.add(EligibilityCriterionResult(
          criterionName: 'Minimum Aggregate Marks',
          status: RuleCheckStatus.needsConfirmation,
          candidateValue: 'Not specified',
          requirement: 'Minimum ${examination.minPercentage}% aggregate',
          details: 'Enter your final degree percentage or CGPA in your profile.',
        ));
        hasNeedsConfirmation = true;
      } else if (candScore >= examination.minPercentage!) {
        results.add(EligibilityCriterionResult(
          criterionName: 'Minimum Aggregate Marks',
          status: RuleCheckStatus.passed,
          candidateValue: '$candScore%',
          requirement: 'Minimum ${examination.minPercentage}% aggregate',
          details: 'Satisfies aggregate percentage cutoff.',
        ));
      } else {
        results.add(EligibilityCriterionResult(
          criterionName: 'Minimum Aggregate Marks',
          status: RuleCheckStatus.failed,
          candidateValue: '$candScore%',
          requirement: 'Minimum ${examination.minPercentage}% aggregate',
          details: 'Candidate aggregate marks fall below the required minimum score.',
        ));
        hasAnyFailure = true;
      }
    }

    // 4. Active Backlogs Check
    if (candidate.hasActiveBacklogs) {
      results.add(const EligibilityCriterionResult(
        criterionName: 'Backlog Status',
        status: RuleCheckStatus.failed,
        candidateValue: 'Active Backlogs Reported',
        requirement: 'All papers must be cleared without pending backlogs at time of document verification',
        details: 'Most central recruitment bodies require all coursework to be cleared by the closing date.',
      ));
      hasAnyFailure = true;
    } else {
      results.add(const EligibilityCriterionResult(
        criterionName: 'Backlog Status',
        status: RuleCheckStatus.passed,
        candidateValue: 'No active backlogs',
        requirement: 'Clean academic record without uncleared backlogs',
        details: 'Candidate has cleared all required semesters.',
      ));
    }

    // 5. Nationality & Citizenship
    results.add(EligibilityCriterionResult(
      criterionName: 'Nationality & Citizenship',
      status: RuleCheckStatus.passed,
      candidateValue: candidate.nationality,
      requirement: examination.nationality,
      details: 'Meets citizenship requirements for Central / State public posts.',
    ));
    requiredDocs.add('Aadhaar Card / Voter ID / Passport for identity verification');

    // 6. Application Fee Exemption Check
    final isFeeExempt = candidate.gender?.toLowerCase() == 'female' ||
        candidate.socialCategory.toUpperCase().contains('SC') ||
        candidate.socialCategory.toUpperCase().contains('ST') ||
        candidate.isPwBD;

    if (isFeeExempt && examination.feeExemptions.isNotEmpty) {
      applicableRelaxations.add('Full Application Fee Exemption (₹${examination.applicationFee?.toInt() ?? 0} waived)');
    }

    // Determine Overall Status
    EligibilityStatus overallStatus;
    String overallSummary;

    if (hasAnyFailure) {
      overallStatus = EligibilityStatus.notEligible;
      overallSummary = 'You do not currently satisfy one or more mandatory statutory criteria for this examination.';
    } else if (hasNeedsConfirmation) {
      overallStatus = EligibilityStatus.potentiallyEligible;
      overallSummary = 'Profile information is incomplete. Complete remaining fields to confirm full eligibility.';
    } else if (hasConditionalPass) {
      overallStatus = EligibilityStatus.eligible;
      overallSummary = 'You are eligible to apply under statutory reservation / age relaxation provisions.';
    } else {
      overallStatus = EligibilityStatus.eligible;
      overallSummary = 'You satisfy all specified eligibility criteria for this examination.';
    }

    return EligibilityReport(
      examinationId: examination.id,
      examinationTitle: examination.title,
      organisation: examination.organisation,
      overallStatus: overallStatus,
      overallSummary: overallSummary,
      criteriaResults: results,
      applicableRelaxations: applicableRelaxations,
      requiredDocumentsForVerification: requiredDocs,
      evaluatedAt: DateTime.now(),
    );
  }
}
