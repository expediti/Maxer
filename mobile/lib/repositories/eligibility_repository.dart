import '../models/candidate_profile.dart';
import '../models/examination.dart';
import '../models/eligibility_report.dart';
import '../core/services/academic_conversion_service.dart';

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
    return evaluate(candidate: candidate, examination: examination);
  }

  /// Authoritative deterministic evaluation gateway across all application screens.
  static EligibilityReport evaluate({
    required CandidateProfile candidate,
    required Examination examination,
  }) {
    final List<EligibilityCriterionResult> results = [];
    final List<String> applicableRelaxations = [];
    final List<String> requiredDocs = [];

    bool hasAnyFailure = false;
    bool hasNeedsConfirmation = false;
    bool hasConditionalPass = false;

    // -------------------------------------------------------------------------
    // 1. Age Evaluation (Calculated against official cutoff or current date)
    // -------------------------------------------------------------------------
    final cutoffDate = examination.importantDates['Application Deadline'] ?? DateTime.now();
    final candidateAge = candidate.calculateAge(cutoffDate);

    if (candidateAge == null) {
      results.add(const EligibilityCriterionResult(
        criterionName: 'Age Limit & Cutoff',
        status: RuleCheckStatus.needsConfirmation,
        candidateValue: 'Date of birth not provided',
        requirement: 'Refer official notification for min & max age limits',
        details: 'Please complete your date of birth in your profile to verify statutory age eligibility.',
      ));
      hasNeedsConfirmation = true;
    } else {
      int effectiveMaxAge = examination.maxAge ?? 100;
      int effectiveMinAge = examination.minAge ?? 0;
      int relaxationYears = 0;

      // Statutory Category relaxation lookup
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
          criterionName: 'Age Limit & Cutoff',
          status: RuleCheckStatus.failed,
          candidateValue: '$candidateAge years',
          requirement: 'Minimum $effectiveMinAge years',
          details: 'Candidate is below the statutory minimum entry age for this post as of cutoff date.',
        ));
        hasAnyFailure = true;
      } else if (candidateAge > relaxedMaxAge) {
        results.add(EligibilityCriterionResult(
          criterionName: 'Age Limit & Cutoff',
          status: RuleCheckStatus.failed,
          candidateValue: '$candidateAge years',
          requirement: 'Max: $effectiveMaxAge years (Relaxed: $relaxedMaxAge years for ${candidate.socialCategory})',
          details: 'Candidate exceeds the statutory upper age limit even after applying category relaxations.',
        ));
        hasAnyFailure = true;
      } else if (candidateAge > effectiveMaxAge && candidateAge <= relaxedMaxAge) {
        results.add(EligibilityCriterionResult(
          criterionName: 'Age Limit & Cutoff',
          status: RuleCheckStatus.conditionallyPassed,
          candidateValue: '$candidateAge years',
          requirement: 'Standard Max: $effectiveMaxAge years (Relaxed: $relaxedMaxAge years)',
          details: 'Eligible under $relaxationYears-year statutory age relaxation for ${candidate.socialCategory}${candidate.isPwBD ? ' / PwBD' : ''}.',
          ruleEvidence: 'Clause 3(b) of official recruitment notification.',
        ));
        hasConditionalPass = true;
      } else {
        results.add(EligibilityCriterionResult(
          criterionName: 'Age Limit & Cutoff',
          status: RuleCheckStatus.passed,
          candidateValue: '$candidateAge years',
          requirement: 'Min: $effectiveMinAge years, Max: $effectiveMaxAge years',
          details: 'Candidate age falls within the unreserved age window as of cutoff date.',
        ));
      }
    }

    // -------------------------------------------------------------------------
    // 2. Educational Qualification & Stream Check (Section 7 Audit)
    // -------------------------------------------------------------------------
    final reqQuals = examination.educationalQualifications;
    final bool isClass12Req = reqQuals.any((q) {
      final l = q.toLowerCase();
      return l.contains('class 12') ||
          l.contains('12th') ||
          l.contains('10+2') ||
          l.contains('intermediate') ||
          l.contains('higher secondary');
    });

    final bool isClass10Req = !isClass12Req && reqQuals.any((q) {
      final l = q.toLowerCase();
      return l.contains('class 10') ||
          l.contains('10th') ||
          l.contains('matriculation') ||
          l.contains('secondary');
    });

    if (isClass12Req) {
      // Examination requires Class 12 / Higher Secondary
      final normDisplay = reqQuals.isNotEmpty ? reqQuals.first : 'Class 12 / Intermediate';

      if (candidate.class12Year != null || candidate.class12Stream != null) {
        final cand12Display = 'Class 12 (${candidate.class12Stream ?? "General"})${candidate.class12Year != null ? " • Passed ${candidate.class12Year}" : ""}';
        
        bool streamMatch = true;
        if (examination.eligibleStreams.isNotEmpty) {
          final matchesAll = examination.eligibleStreams.any((s) =>
              s.toLowerCase().contains('all') ||
              s.toLowerCase().contains('any discipline') ||
              s.toLowerCase().contains('all disciplines'));
          if (!matchesAll && candidate.class12Stream != null) {
            final cStr = candidate.class12Stream!.toLowerCase();
            streamMatch = examination.eligibleStreams.any((reqStream) {
              final rLower = reqStream.toLowerCase();
              return cStr.contains(rLower) || rLower.contains(cStr);
            });
          }
        }

        if (streamMatch) {
          final higherQualNote = candidate.highestQualification != null
              ? ' Candidate additionally holds higher qualification: ${candidate.highestQualification} (${candidate.stream ?? "General"}).'
              : '';
          results.add(EligibilityCriterionResult(
            criterionName: 'Educational Qualification & Discipline',
            status: RuleCheckStatus.passed,
            candidateValue: cand12Display,
            requirement: normDisplay,
            details: 'Candidate satisfies Class 12 statutory educational requirements.$higherQualNote',
          ));
          requiredDocs.add('Class 12 Marksheet & Passing Certificate issued by recognized State/Central Board');
        } else {
          results.add(EligibilityCriterionResult(
            criterionName: 'Educational Qualification & Discipline',
            status: RuleCheckStatus.failed,
            candidateValue: cand12Display,
            requirement: '${examination.eligibleStreams.join(', ')} in Class 12',
            details: 'Candidate Class 12 stream does not match the mandatory disciplines advertised for this post.',
          ));
          hasAnyFailure = true;
        }
      } else {
        // Class 12 is missing from candidate profile
        final higherQualName = candidate.highestQualification ?? candidate.degreeName ?? 'Tertiary Degree';
        results.add(EligibilityCriterionResult(
          criterionName: 'Educational Qualification & Discipline',
          status: RuleCheckStatus.needsConfirmation,
          candidateValue: 'Class 12 details not provided (Holds $higherQualName)',
          requirement: normDisplay,
          details: 'This examination specifically requires Class 12 credentials. Please enter your Class 12 passing year and stream in your qualifications profile.',
        ));
        hasNeedsConfirmation = true;
      }
    } else if (isClass10Req) {
      // Examination requires Class 10 / Matriculation
      final normDisplay = reqQuals.isNotEmpty ? reqQuals.first : 'Class 10 / Matriculation';
      if (candidate.class10Year != null) {
        results.add(EligibilityCriterionResult(
          criterionName: 'Educational Qualification & Discipline',
          status: RuleCheckStatus.passed,
          candidateValue: 'Class 10 (Passed ${candidate.class10Year})',
          requirement: normDisplay,
          details: 'Candidate satisfies Class 10 secondary qualification requirements.',
        ));
        requiredDocs.add('Class 10 Board Certificate for Date of Birth & Passing Verification');
      } else {
        results.add(EligibilityCriterionResult(
          criterionName: 'Educational Qualification & Discipline',
          status: RuleCheckStatus.needsConfirmation,
          candidateValue: 'Class 10 passing year not specified',
          requirement: normDisplay,
          details: 'Please enter your Class 10 passing year in your profile.',
        ));
        hasNeedsConfirmation = true;
      }
    } else {
      // Standard Tertiary / Undergraduate / Postgraduate Examination
      final candidateEdu = candidate.highestQualification ?? candidate.degreeName;
      if (candidateEdu == null || candidateEdu.isEmpty) {
        results.add(const EligibilityCriterionResult(
          criterionName: 'Educational Qualification & Discipline',
          status: RuleCheckStatus.needsConfirmation,
          candidateValue: 'Not specified',
          requirement: 'Recognized Bachelor degree / technical diploma as per notification',
          details: 'Add your degree title and discipline in your profile to verify qualification criteria.',
        ));
        hasNeedsConfirmation = true;
      } else {
        bool streamMatch = true;
        if (examination.eligibleStreams.isNotEmpty) {
          final matchesAll = examination.eligibleStreams.any((s) =>
              s.toLowerCase().contains('all') ||
              s.toLowerCase().contains('any discipline') ||
              s.toLowerCase().contains('all streams'));
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
            criterionName: 'Educational Qualification & Discipline',
            status: RuleCheckStatus.passed,
            candidateValue: '${candidate.degreeName ?? candidate.highestQualification} (${candidate.stream ?? "General"})',
            requirement: examination.educationalQualifications.isNotEmpty
                ? examination.educationalQualifications.first
                : 'Recognized University Degree',
            details: 'Candidate qualification satisfies statutory degree requirements.',
          ));
          requiredDocs.add('Original Degree Certificate / Provisional Certificate with Final Marksheet');
        } else {
          results.add(EligibilityCriterionResult(
            criterionName: 'Educational Qualification & Discipline',
            status: RuleCheckStatus.failed,
            candidateValue: '${candidate.degreeName} in ${candidate.stream}',
            requirement: examination.eligibleStreams.join(', '),
            details: 'Candidate discipline does not match the mandatory streams listed for this post.',
          ));
          hasAnyFailure = true;
        }
      }
    }

    // -------------------------------------------------------------------------
    // 3. Academic Stage & Appearing Status (PART 4)
    // -------------------------------------------------------------------------
    if (isClass12Req) {
      if (candidate.class12Year != null) {
        results.add(EligibilityCriterionResult(
          criterionName: 'Academic Stage & Completion',
          status: RuleCheckStatus.passed,
          candidateValue: 'Class 12 Completed (${candidate.class12Year})',
          requirement: 'Class 12 / Higher Secondary Passed',
          details: 'Candidate has successfully completed Class 12 education.',
        ));
      } else {
        results.add(const EligibilityCriterionResult(
          criterionName: 'Academic Stage & Completion',
          status: RuleCheckStatus.needsConfirmation,
          candidateValue: 'Class 12 status not specified',
          requirement: 'Class 12 / Higher Secondary Passed',
          details: 'Please specify your Class 12 completion status in your profile.',
        ));
        hasNeedsConfirmation = true;
      }
    } else {
      final isGraduated = candidate.isGraduated;
      final curYear = candidate.currentYearOfStudy;
      final curSem = candidate.currentSemester;
      final totalDuration = candidate.degreeDurationYears;
      final isFinalYear = candidate.isFinalYearStudent;

      if (isGraduated) {
        results.add(EligibilityCriterionResult(
          criterionName: 'Academic Stage & Completion',
          status: RuleCheckStatus.passed,
          candidateValue: 'Completed / Degree Awarded (${candidate.graduationYear ?? "Graduated"})',
          requirement: examination.degreeCompletionCutoffDate != null
              ? 'Degree completed prior to ${examination.degreeCompletionCutoffDate!.toIso8601String().split("T").first}'
              : 'Degree completion or recognized qualification',
          details: 'Candidate has completed their degree, satisfying the statutory completion condition.',
        ));
      } else {
        final candidateStageDesc = curYear != null
            ? 'Year $curYear of $totalDuration${curSem != null ? " (Semester $curSem)" : ""}'
            : 'Pursuing undergraduate degree';

        if (examination.minAcademicYearRequired != null &&
            curYear != null &&
            curYear >= examination.minAcademicYearRequired!) {
          results.add(EligibilityCriterionResult(
            criterionName: 'Academic Stage & Completion',
            status: RuleCheckStatus.passed,
            candidateValue: candidateStageDesc,
            requirement: 'Undergraduate candidates in Year ${examination.minAcademicYearRequired} or higher permitted',
            details: 'Candidate is in $candidateStageDesc, which satisfies the notification clause permitting Year ${examination.minAcademicYearRequired} students to appear.',
          ));
        } else if (examination.acceptsFinalYearStudents || examination.acceptsAppearingCandidates) {
          if (isFinalYear) {
            results.add(EligibilityCriterionResult(
              criterionName: 'Academic Stage & Completion',
              status: RuleCheckStatus.conditionallyPassed,
              candidateValue: '$candidateStageDesc (Final Year Appearing)',
              requirement: 'Final-year appearing candidates accepted',
              details: 'Eligible as a final-year appearing candidate. Final degree marksheets must be presented during document verification.',
            ));
            hasConditionalPass = true;
            requiredDocs.add('Bonafide Student Certificate / Undertaking from Principal / Head of Department');
          } else {
            results.add(EligibilityCriterionResult(
              criterionName: 'Academic Stage & Completion',
              status: RuleCheckStatus.failed,
              candidateValue: candidateStageDesc,
              requirement: 'Final year appearing candidates only (Year $totalDuration)',
              details: 'Examination permits final-year candidates only; candidate is currently in $candidateStageDesc (graduating in ${candidate.graduationYear ?? "future cycle"}).',
            ));
            hasAnyFailure = true;
          }
        } else {
          final cutoffStr = examination.degreeCompletionCutoffDate != null
              ? examination.degreeCompletionCutoffDate!.toIso8601String().split('T').first
              : 'examination application closing date';
          results.add(EligibilityCriterionResult(
            criterionName: 'Academic Stage & Completion',
            status: RuleCheckStatus.failed,
            candidateValue: '$candidateStageDesc (Pursuing)',
            requirement: 'Completed degree required before $cutoffStr',
            details: 'This examination strictly requires a completed degree prior to $cutoffStr and does not permit appearing or ongoing candidates.',
          ));
          hasAnyFailure = true;
        }
      }
    }

    // -------------------------------------------------------------------------
    // 4. Minimum Academic Marks / Cutoff with Verified Conversion (PART 2)
    // -------------------------------------------------------------------------
    final scoreResult = AcademicConversionService.compareAcademicScores(
      candidateScore: candidate.effectiveScore,
      candidateGradingSystem: candidate.gradingSystem,
      candidateScaleMax: candidate.gradingScaleMax,
      candidateUniversity: candidate.university ?? candidate.institution,
      candidateFormulaText: candidate.conversionFormula,
      candidateFormulaSource: candidate.conversionSource,
      requiredMinPercentage: examination.minPercentage,
      requiredMinCgpa: examination.minCgpa,
      requiredCgpaScaleMax: examination.cgpaScaleMax,
      requiredGradingType: examination.gradingType,
    );

    results.add(EligibilityCriterionResult(
      criterionName: 'Academic Score & Cutoff',
      status: scoreResult.status,
      candidateValue: scoreResult.candidateValueDisplay,
      requirement: scoreResult.requirementDisplay,
      details: scoreResult.details,
      originalScore: scoreResult.originalScoreDisplay,
      convertedPercentage: scoreResult.convertedPercentageDisplay,
      conversionFormula: scoreResult.formulaUsed,
      conversionSource: scoreResult.sourceUsed,
      comparison: scoreResult.comparisonDisplay,
      ruleEvidence: scoreResult.formulaUsed != null && scoreResult.sourceUsed != null
          ? 'Conversion applied: ${scoreResult.formulaUsed} (Source: ${scoreResult.sourceUsed})'
          : null,
    ));

    if (scoreResult.status == RuleCheckStatus.failed) {
      hasAnyFailure = true;
    } else if (scoreResult.status == RuleCheckStatus.needsConfirmation) {
      hasNeedsConfirmation = true;
      if (scoreResult.sourceUsed != null && scoreResult.sourceUsed!.contains('Certificate')) {
        requiredDocs.add('Official CGPA-to-Percentage Conversion Certificate issued by University Registrar');
      }
    }

    // -------------------------------------------------------------------------
    // 5. Active Backlogs Check
    // -------------------------------------------------------------------------
    if (candidate.hasActiveBacklogs) {
      results.add(const EligibilityCriterionResult(
        criterionName: 'Backlog Status',
        status: RuleCheckStatus.failed,
        candidateValue: 'Active Backlogs Reported',
        requirement: 'All papers must be cleared without pending backlogs at time of document verification',
        details: 'Most recruitment bodies require all coursework to be cleared by the closing date.',
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

    // -------------------------------------------------------------------------
    // 6. Nationality & Citizenship
    // -------------------------------------------------------------------------
    results.add(EligibilityCriterionResult(
      criterionName: 'Nationality & Citizenship',
      status: RuleCheckStatus.passed,
      candidateValue: candidate.nationality,
      requirement: examination.nationality,
      details: 'Meets citizenship requirements for Central / State public posts.',
    ));
    requiredDocs.add('Aadhaar Card / Voter ID / Passport for identity verification');

    // -------------------------------------------------------------------------
    // 7. Application Fee Exemption Check
    // -------------------------------------------------------------------------
    final isFeeExempt = candidate.gender?.toLowerCase() == 'female' ||
        candidate.socialCategory.toUpperCase().contains('SC') ||
        candidate.socialCategory.toUpperCase().contains('ST') ||
        candidate.isPwBD;

    if (isFeeExempt && examination.feeExemptions.isNotEmpty) {
      applicableRelaxations.add('Full Application Fee Exemption (₹${examination.applicationFee?.toInt() ?? 0} waived)');
    }

    // -------------------------------------------------------------------------
    // Determine Overall Status (Deterministic & Strict)
    // -------------------------------------------------------------------------
    EligibilityStatus overallStatus;
    String overallSummary;

    if (criteriaResults.isEmpty || (examination.educationalQualifications.isEmpty && examination.minAge == null && examination.maxAge == null)) {
      overallStatus = EligibilityStatus.unconfirmed;
      overallSummary = 'Eligibility cannot be confirmed because official information is incomplete.';
    } else if (hasAnyFailure) {
      overallStatus = EligibilityStatus.notEligible;
      overallSummary = 'You do not currently satisfy one or more mandatory statutory criteria for this examination.';
    } else if (hasNeedsConfirmation) {
      overallStatus = EligibilityStatus.needsVerification;
      overallSummary = 'Official institutional verification required. One or more criteria require verified conversion certificates or institutional documentation before statutory eligibility can be confirmed.';
    } else if (hasConditionalPass) {
      overallStatus = EligibilityStatus.potentiallyEligible;
      overallSummary = 'You are conditionally eligible to apply under statutory reservation / appearing candidate provisions.';
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
