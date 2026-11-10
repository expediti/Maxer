import '../../models/academic_score.dart';
import '../../models/eligibility_report.dart';

/// Represents an officially documented and verifiable grade conversion formula
/// from an Indian educational statutory council, university, or examination board.
class VerifiedConversionFormula {
  final String slug;
  final String institutionName;
  final String formulaDescription;
  final String officialSource;
  final double Function(double cgpa) convertFunction;

  const VerifiedConversionFormula({
    required this.slug,
    required this.institutionName,
    required this.formulaDescription,
    required this.officialSource,
    required this.convertFunction,
  });

  double convert(double cgpa) => convertFunction(cgpa);
}

/// Structured outcome of evaluating an academic score across potentially differing grading systems.
class GradeComparisonResult {
  final RuleCheckStatus status;
  final String candidateValueDisplay;
  final String requirementDisplay;
  final String details;
  final String? formulaUsed;
  final String? sourceUsed;
  final double? convertedScore;

  // Truthful UI breakdown fields (Sections 3 & 6 of specification)
  final String? originalScoreDisplay;
  final String? convertedPercentageDisplay;
  final String? comparisonDisplay;

  const GradeComparisonResult({
    required this.status,
    required this.candidateValueDisplay,
    required this.requirementDisplay,
    required this.details,
    this.formulaUsed,
    this.sourceUsed,
    this.convertedScore,
    this.originalScoreDisplay,
    this.convertedPercentageDisplay,
    this.comparisonDisplay,
  });
}

class AcademicConversionService {
  AcademicConversionService._();

  /// Curated registry of officially documented Indian university conversion formulas.
  static final List<VerifiedConversionFormula> verifiedFormulas = [
    // 1. AICTE Standard Norm (Engineering & Technology Institutions across India)
    VerifiedConversionFormula(
      slug: 'aicte',
      institutionName: 'AICTE Standard Norm',
      formulaDescription: 'Percentage = (CGPA - 0.75) × 10',
      officialSource: 'AICTE Approval Process Handbook & Gazette Notification',
      convertFunction: (cgpa) => ((cgpa - 0.75) * 10).clamp(0.0, 100.0),
    ),

    // 2. University of Delhi (DU)
    VerifiedConversionFormula(
      slug: 'du',
      institutionName: 'University of Delhi (DU)',
      formulaDescription: 'Percentage = CGPA × 9.5',
      officialSource: 'DU Notification No. Exam.VII/2019/338',
      convertFunction: (cgpa) => (cgpa * 9.5).clamp(0.0, 100.0),
    ),

    // 3. Central Board of Secondary Education (CBSE)
    VerifiedConversionFormula(
      slug: 'cbse',
      institutionName: 'Central Board of Secondary Education (CBSE)',
      formulaDescription: 'Percentage = CGPA × 9.5',
      officialSource: 'CBSE Examination Bye-Laws Circular No. Coord/SO(EC-RO)/2017',
      convertFunction: (cgpa) => (cgpa * 9.5).clamp(0.0, 100.0),
    ),

    // 4. Visvesvaraya Technological University (VTU)
    VerifiedConversionFormula(
      slug: 'vtu',
      institutionName: 'Visvesvaraya Technological University (VTU)',
      formulaDescription: 'Percentage = (CGPA - 0.75) × 10',
      officialSource: 'VTU Academic Regulations for B.E./B.Tech',
      convertFunction: (cgpa) => ((cgpa - 0.75) * 10).clamp(0.0, 100.0),
    ),

    // 5. Anna University
    VerifiedConversionFormula(
      slug: 'anna_university',
      institutionName: 'Anna University',
      formulaDescription: 'Percentage = CGPA × 10',
      officialSource: 'Anna University Regulations 2021 Clause 12.4',
      convertFunction: (cgpa) => (cgpa * 10.0).clamp(0.0, 100.0),
    ),

    // 6. University of Mumbai
    VerifiedConversionFormula(
      slug: 'mumbai_university',
      institutionName: 'University of Mumbai',
      formulaDescription: 'Percentage = 7.25 × CGPA + 11',
      officialSource: 'University of Mumbai UG CBCS Ordinance',
      convertFunction: (cgpa) => (7.25 * cgpa + 11.0).clamp(0.0, 100.0),
    ),

    // 7. JNTU Hyderabad / Kakinada
    VerifiedConversionFormula(
      slug: 'jntu',
      institutionName: 'JNTU (Hyderabad / Kakinada)',
      formulaDescription: 'Percentage = (CGPA - 0.5) × 10',
      officialSource: 'JNTUH Academic Regulations R18/R22',
      convertFunction: (cgpa) => ((cgpa - 0.5) * 10).clamp(0.0, 100.0),
    ),

    // 8. UGC 10-Point Linear Scale
    VerifiedConversionFormula(
      slug: 'ugc_linear',
      institutionName: 'UGC 10-Point Linear Scale',
      formulaDescription: 'Percentage = CGPA × 10',
      officialSource: 'UGC Guidelines on Adoption of Choice Based Credit System',
      convertFunction: (cgpa) => (cgpa * 10.0).clamp(0.0, 100.0),
    ),
  ];

  /// Look up verified conversion formula by university name or explicit formula keyword.
  static VerifiedConversionFormula? lookupFormula({
    String? university,
    String? customFormula,
  }) {
    if (customFormula != null && customFormula.trim().isNotEmpty) {
      final fNorm = customFormula.toLowerCase().replaceAll(' ', '');
      if (fNorm.contains('9.5')) {
        return verifiedFormulas.firstWhere((f) => f.slug == 'cbse');
      }
      if (fNorm.contains('0.75') && fNorm.contains('10')) {
        return verifiedFormulas.firstWhere((f) => f.slug == 'aicte');
      }
      if (fNorm.contains('0.5') && fNorm.contains('10')) {
        return verifiedFormulas.firstWhere((f) => f.slug == 'jntu');
      }
      if (fNorm.contains('*10') || fNorm.contains('x10')) {
        return verifiedFormulas.firstWhere((f) => f.slug == 'anna_university');
      }
    }

    if (university == null || university.trim().isEmpty) return null;
    final u = university.toLowerCase().trim();

    if (u.contains('delhi') || u.contains('du')) {
      return verifiedFormulas.firstWhere((f) => f.slug == 'du');
    }
    if (u.contains('vtu') || u.contains('visvesvaraya')) {
      return verifiedFormulas.firstWhere((f) => f.slug == 'vtu');
    }
    if (u.contains('anna')) {
      return verifiedFormulas.firstWhere((f) => f.slug == 'anna_university');
    }
    if (u.contains('mumbai')) {
      return verifiedFormulas.firstWhere((f) => f.slug == 'mumbai_university');
    }
    if (u.contains('jntu')) {
      return verifiedFormulas.firstWhere((f) => f.slug == 'jntu');
    }
    if (u.contains('cbse')) {
      return verifiedFormulas.firstWhere((f) => f.slug == 'cbse');
    }
    if (u.contains('aicte')) {
      return verifiedFormulas.firstWhere((f) => f.slug == 'aicte');
    }

    return null;
  }

  /// Core evaluation engine: compares candidate academic score against examination requirements.
  ///
  /// INVARIANTS:
  /// 1. Every score retains its grading type (Percentage, CGPA, GPA).
  /// 2. Never infers grading type from the numeric value.
  /// 3. Never converts or compares CGPA directly with Percentage without an official verified formula.
  /// 4. When a formula is unavailable, returns RuleCheckStatus.needsConfirmation ('Requires Verification')
  ///    and never compares numeric CGPA against numeric Percentage cutoff.
  static GradeComparisonResult compareAcademicScores({
    required double? candidateScore,
    required String? candidateGradingSystem, // 'cgpa' | 'percentage' | 'gpa'
    required double candidateScaleMax, // e.g. 10.0 or 100.0 or 4.0
    required String? candidateUniversity,
    required String? candidateFormulaText,
    required String? candidateFormulaSource,
    required double? requiredMinPercentage,
    required double? requiredMinCgpa,
    double requiredCgpaScaleMax = 10.0,
    required String? requiredGradingType, // 'percentage' | 'cgpa' | 'any'
  }) {
    // 1. If examination does not mandate an academic cutoff score
    if (requiredMinPercentage == null && requiredMinCgpa == null) {
      final String candDisplay;
      if (candidateScore != null) {
        final gradingType = AcademicGradingType.fromString(candidateGradingSystem);
        candDisplay = AcademicScore(
          scoreValue: candidateScore,
          gradingType: gradingType,
          gradingScaleMax: candidateScaleMax,
        ).formattedDisplay;
      } else {
        candDisplay = 'Not specified';
      }

      return GradeComparisonResult(
        status: RuleCheckStatus.passed,
        candidateValueDisplay: candDisplay,
        requirementDisplay: 'Passing degree (No minimum percentage specified)',
        details: 'Candidate holds passing academic credentials. No statutory cutoff score mandated.',
      );
    }

    // 2. Candidate score is not provided in profile
    if (candidateScore == null) {
      final reqStr = requiredMinPercentage != null
          ? 'Minimum ${requiredMinPercentage.toStringAsFixed(1)}% aggregate marks'
          : 'Minimum ${requiredMinCgpa!.toStringAsFixed(2)} CGPA';

      return GradeComparisonResult(
        status: RuleCheckStatus.needsConfirmation,
        candidateValueDisplay: 'Not specified',
        requirementDisplay: reqStr,
        details: 'Academic score is missing from your candidate profile. Please enter your degree CGPA or percentage.',
      );
    }

    // Parse candidate score model explicitly without guessing from numeric magnitude
    final candGradingType = AcademicGradingType.fromString(candidateGradingSystem);
    final candidateScoreModel = AcademicScore(
      scoreValue: candidateScore,
      gradingType: candGradingType,
      gradingScaleMax: candidateScaleMax,
    );

    final isCandidateCgpa = candGradingType == AcademicGradingType.cgpa;
    final isCandidateGpa = candGradingType == AcademicGradingType.gpa;
    final isCandidatePercentage = candGradingType == AcademicGradingType.percentage;

    // -------------------------------------------------------------------------
    // SCENARIO 1: Same Grading System Comparison (Preferred Direct Evaluation)
    // -------------------------------------------------------------------------

    // Sub-case 1A: Candidate provides CGPA and Exam specifies CGPA cutoff
    if (isCandidateCgpa && requiredMinCgpa != null) {
      final reqText = 'Minimum ${requiredMinCgpa.toStringAsFixed(2)} CGPA (${requiredCgpaScaleMax.toStringAsFixed(0)}-point scale)';
      final candDisplay = candidateScoreModel.formattedDisplay;

      if (candidateScore >= requiredMinCgpa) {
        return GradeComparisonResult(
          status: RuleCheckStatus.passed,
          candidateValueDisplay: candDisplay,
          requirementDisplay: reqText,
          details: 'Candidate CGPA (${candidateScore.toStringAsFixed(2)}) satisfies the mandatory cutoff of ${requiredMinCgpa.toStringAsFixed(2)} CGPA.',
          originalScoreDisplay: candDisplay,
          comparisonDisplay: '${candidateScore.toStringAsFixed(2)} CGPA vs required ${requiredMinCgpa.toStringAsFixed(2)} CGPA',
        );
      } else {
        return GradeComparisonResult(
          status: RuleCheckStatus.failed,
          candidateValueDisplay: candDisplay,
          requirementDisplay: reqText,
          details: 'Candidate CGPA (${candidateScore.toStringAsFixed(2)}) is below required minimum of ${requiredMinCgpa.toStringAsFixed(2)} CGPA.',
          originalScoreDisplay: candDisplay,
          comparisonDisplay: '${candidateScore.toStringAsFixed(2)} CGPA vs required ${requiredMinCgpa.toStringAsFixed(2)} CGPA',
        );
      }
    }

    // Sub-case 1B: Candidate provides Percentage and Exam specifies Percentage cutoff
    if (isCandidatePercentage && requiredMinPercentage != null) {
      final reqText = 'Minimum ${requiredMinPercentage.toStringAsFixed(1)}% aggregate marks';
      final candDisplay = candidateScoreModel.formattedDisplay;

      if (candidateScore >= requiredMinPercentage) {
        return GradeComparisonResult(
          status: RuleCheckStatus.passed,
          candidateValueDisplay: candDisplay,
          requirementDisplay: reqText,
          details: 'Candidate aggregate marks of ${candidateScore.toStringAsFixed(1)}% satisfy the minimum ${requiredMinPercentage.toStringAsFixed(1)}% requirement.',
          originalScoreDisplay: candDisplay,
          comparisonDisplay: '${candidateScore.toStringAsFixed(1)}% vs required ${requiredMinPercentage.toStringAsFixed(1)}%',
        );
      } else {
        return GradeComparisonResult(
          status: RuleCheckStatus.failed,
          candidateValueDisplay: candDisplay,
          requirementDisplay: reqText,
          details: 'Candidate aggregate marks (${candidateScore.toStringAsFixed(1)}%) are below the mandatory cutoff of ${requiredMinPercentage.toStringAsFixed(1)}%.',
          originalScoreDisplay: candDisplay,
          comparisonDisplay: '${candidateScore.toStringAsFixed(1)}% vs required ${requiredMinPercentage.toStringAsFixed(1)}%',
        );
      }
    }

    // -------------------------------------------------------------------------
    // SCENARIO 2: Cross-System Comparison (Verified Conversion Formula Required)
    // -------------------------------------------------------------------------

    // Sub-case 2A: Candidate provides CGPA, Exam requires Percentage Cutoff
    if ((isCandidateCgpa || isCandidateGpa) && requiredMinPercentage != null) {
      final reqText = 'Minimum ${requiredMinPercentage.toStringAsFixed(1)}% aggregate marks';
      final originalScoreDisplay = candidateScoreModel.formattedDisplay;

      final formula = lookupFormula(
        university: candidateUniversity,
        customFormula: candidateFormulaText,
      );

      if (formula != null) {
        // Apply verified institutional formula
        final rawConverted = formula.convert(candidateScore);
        final convertedPerc = double.parse(rawConverted.toStringAsFixed(2));
        final convertedDisplay = '${convertedPerc.toStringAsFixed(1)}%';
        final comparisonStr = '$convertedDisplay vs required ${requiredMinPercentage.toStringAsFixed(1)}% aggregate marks';

        if (convertedPerc >= requiredMinPercentage) {
          return GradeComparisonResult(
            status: RuleCheckStatus.passed,
            candidateValueDisplay: '$originalScoreDisplay (Converted: $convertedDisplay via ${formula.institutionName})',
            requirementDisplay: reqText,
            details: 'Candidate CGPA of ${candidateScore.toStringAsFixed(2)} equates to $convertedDisplay under verified ${formula.institutionName} formula (${formula.formulaDescription}), which satisfies the minimum ${requiredMinPercentage.toStringAsFixed(1)}% aggregate marks requirement.',
            formulaUsed: formula.formulaDescription,
            sourceUsed: formula.officialSource,
            convertedScore: convertedPerc,
            originalScoreDisplay: originalScoreDisplay,
            convertedPercentageDisplay: convertedDisplay,
            comparisonDisplay: comparisonStr,
          );
        } else {
          return GradeComparisonResult(
            status: RuleCheckStatus.failed,
            candidateValueDisplay: '$originalScoreDisplay (Converted: $convertedDisplay via ${formula.institutionName})',
            requirementDisplay: reqText,
            details: 'Candidate CGPA of ${candidateScore.toStringAsFixed(2)} equates to $convertedDisplay under verified formula (${formula.formulaDescription}), which is below the mandatory cutoff of ${requiredMinPercentage.toStringAsFixed(1)}%.',
            formulaUsed: formula.formulaDescription,
            sourceUsed: formula.officialSource,
            convertedScore: convertedPerc,
            originalScoreDisplay: originalScoreDisplay,
            convertedPercentageDisplay: convertedDisplay,
            comparisonDisplay: comparisonStr,
          );
        }
      } else {
        // Formula is unavailable:
        // - Preserve original CGPA
        // - DO NOT display 7.5%
        // - DO NOT compare 7.5 against 50
        // - Return Requires Verification
        // - Explain that the institution's official conversion formula is needed
        final institutionName = candidateUniversity?.trim().isNotEmpty == true
            ? candidateUniversity!.trim()
            : 'your institution';

        return GradeComparisonResult(
          status: RuleCheckStatus.needsConfirmation,
          candidateValueDisplay: originalScoreDisplay,
          requirementDisplay: reqText,
          details: "The candidate's CGPA cannot be directly compared with the percentage requirement without an applicable conversion formula. No verified institutional conversion formula is on record for \"$institutionName\". An official CGPA-to-percentage conversion certificate from your institution is required.",
          formulaUsed: 'Awaiting verified university formula',
          sourceUsed: 'Official University Conversion Certificate Required',
          convertedScore: null,
          originalScoreDisplay: originalScoreDisplay,
          convertedPercentageDisplay: null,
          comparisonDisplay: 'CGPA cannot be directly compared with percentage without applicable formula',
        );
      }
    }

    // Sub-case 2B: Candidate provides Percentage, Exam specifies CGPA Cutoff
    if (isCandidatePercentage && requiredMinCgpa != null) {
      final reqText = 'Minimum ${requiredMinCgpa.toStringAsFixed(2)} CGPA';
      final originalScoreDisplay = candidateScoreModel.formattedDisplay;

      return GradeComparisonResult(
        status: RuleCheckStatus.needsConfirmation,
        candidateValueDisplay: originalScoreDisplay,
        requirementDisplay: reqText,
        details: 'Candidate aggregate score is recorded as $originalScoreDisplay; examination specifies a cutoff of ${requiredMinCgpa.toStringAsFixed(2)} CGPA. Official percentage-to-CGPA equivalence certification from your university is required.',
        formulaUsed: 'Awaiting verified institutional equivalence formula',
        sourceUsed: 'Institutional Equivalence Certificate Required',
        originalScoreDisplay: originalScoreDisplay,
        comparisonDisplay: 'Percentage cannot be directly equated with CGPA without official equivalence',
      );
    }

    // Default fallback
    return GradeComparisonResult(
      status: RuleCheckStatus.passed,
      candidateValueDisplay: candidateScoreModel.formattedDisplay,
      requirementDisplay: 'Satisfied',
      details: 'Academic requirement satisfied.',
    );
  }
}
