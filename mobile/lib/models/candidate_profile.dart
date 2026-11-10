import 'examination.dart';
import 'academic_score.dart';

export 'academic_score.dart';

class CandidateProfile {
  final String id;
  final String email;
  final String fullName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String nationality;
  final String? state;
  final String? district;
  final String countryOfResidence;
  final String? avatarUrl;

  // Background
  final String? currentStatus; // Studying in school, Pursuing undergraduate degree, etc.

  // Category & Reservations
  final String socialCategory;
  final bool isObcNcl;
  final bool isPwBD;
  final String? pwbdDisabilityType;
  final bool isExServiceman;
  final List<String> additionalRelaxations;

  // Secondary & Higher Secondary Education
  final int? class10Year;
  final double? class10Percentage;
  final int? class12Year;
  final String? class12Stream;
  final double? class12Percentage;
  final String class12GradingSystem; // 'percentage' | 'cgpa'

  // Tertiary Education Details
  final String? highestQualification;
  final String? degreeName;
  final String? stream;
  final String? institution;
  final String? university;
  final String? collegeName;
  final bool isInstitutionRecognized;
  final int? currentYearOfStudy; // 1, 2, 3, 4, 5
  final int? currentSemester; // 1 to 10
  final int degreeDurationYears; // 3, 4, 5
  final String academicStatus; // 'pursuing' | 'completed' | 'discontinued'
  final String gradingSystem; // 'cgpa' | 'percentage' | 'gpa'
  final double gradingScaleMax; // 10.0, 100.0, 4.0
  final double? cgpa;
  final double? percentage;
  final double? gpa;
  final AcademicScore? academicScore;
  final Map<String, dynamic> yearWisePerformance;
  final Map<String, dynamic> semesterWisePerformance;
  final String? conversionFormula;
  final String? conversionSource;
  final int? graduationYear;
  final DateTime? expectedGraduationDate;
  final double? cgpaOrPercentage;
  final String? degreeStatus; // 'Completed' | 'Ongoing'
  final bool hasActiveBacklogs;
  final int? gateScore;
  final int? gateYear;
  final bool hasNetJrf;
  final String? netSubject;
  final String? postgradDegree;
  final String? postgradStream;
  final int? postgradYear;
  final double? postgradScore;
  final double workExperienceYears;
  final int researchExperienceMonths;
  final List<String> certifications;

  // Preferences
  final List<ExaminationCategory> preferredCategories;
  final List<String> preferredStates;
  final bool willingToRelocate;
  final bool willingToWorkAnywhereInIndia;
  final num? maxApplicationFeeBudget;
  final List<String> careerInterests;

  const CandidateProfile({
    required this.id,
    required this.email,
    this.fullName = '',
    this.dateOfBirth,
    this.gender,
    this.nationality = 'Indian',
    this.state,
    this.district,
    this.countryOfResidence = 'India',
    this.avatarUrl,
    this.currentStatus,
    this.socialCategory = 'General',
    this.isObcNcl = false,
    this.isPwBD = false,
    this.pwbdDisabilityType,
    this.isExServiceman = false,
    this.additionalRelaxations = const [],
    this.class10Year,
    this.class10Percentage,
    this.class12Year,
    this.class12Stream,
    this.class12Percentage,
    this.class12GradingSystem = 'percentage',
    this.highestQualification,
    this.degreeName,
    this.stream,
    this.institution,
    this.university,
    this.collegeName,
    this.isInstitutionRecognized = true,
    this.currentYearOfStudy,
    this.currentSemester,
    this.degreeDurationYears = 4,
    this.academicStatus = 'completed',
    this.gradingSystem = 'cgpa',
    this.gradingScaleMax = 10.0,
    this.cgpa,
    this.percentage,
    this.gpa,
    this.academicScore,
    this.yearWisePerformance = const {},
    this.semesterWisePerformance = const {},
    this.conversionFormula,
    this.conversionSource,
    this.graduationYear,
    this.expectedGraduationDate,
    this.cgpaOrPercentage,
    this.degreeStatus = 'Completed',
    this.hasActiveBacklogs = false,
    this.gateScore,
    this.gateYear,
    this.hasNetJrf = false,
    this.netSubject,
    this.postgradDegree,
    this.postgradStream,
    this.postgradYear,
    this.postgradScore,
    this.workExperienceYears = 0.0,
    this.researchExperienceMonths = 0,
    this.certifications = const [],
    this.preferredCategories = const [
      ExaminationCategory.govtRecruitment,
      ExaminationCategory.psu,
      ExaminationCategory.entranceExam,
    ],
    this.preferredStates = const [],
    this.willingToRelocate = true,
    this.willingToWorkAnywhereInIndia = true,
    this.maxApplicationFeeBudget,
    this.careerInterests = const ['Engineering', 'Computer Science', 'Administration'],
  });

  String? get universityOrCollege => university ?? institution ?? collegeName;

  bool get isGraduated =>
      academicStatus.toLowerCase() == 'completed' || degreeStatus?.toLowerCase() == 'completed';
  bool get isUndergraduatePursuing =>
      academicStatus.toLowerCase() == 'pursuing' || degreeStatus?.toLowerCase() == 'ongoing';

  bool get isFinalYearStudent {
    if (isGraduated) return false;
    final curYear = currentYearOfStudy;
    if (curYear != null && curYear >= degreeDurationYears) return true;
    final curSem = currentSemester;
    if (curSem != null && curSem >= (degreeDurationYears * 2 - 1)) return true;
    return false;
  }

  /// Authoritative score resolution prioritizing strongly typed academic score model
  double? get effectiveScore =>
      academicScore?.scoreValue ?? cgpa ?? percentage ?? gpa ?? cgpaOrPercentage;

  /// Returns the strongly-typed AcademicScore encapsulating value, grading system, and scale.
  AcademicScore? get scoreModel {
    if (academicScore != null) return academicScore;
    final score = effectiveScore;
    if (score == null) return null;
    final type = AcademicGradingType.fromString(gradingSystem);
    return AcademicScore(
      scoreValue: score,
      gradingType: type,
      gradingScaleMax: gradingScaleMax,
    );
  }

  /// Truthful display of candidate academic score with scale context everywhere in the app.
  /// Example: '7.50 CGPA (10-point scale)' or '65.0%'
  String get formattedScoreDisplay {
    final s = scoreModel;
    if (s == null) return 'Not set';
    return s.formattedDisplay;
  }

  /// Compact display with unit.
  /// Example: '7.50 CGPA' or '65.0%'
  String get shortScoreDisplay {
    final s = scoreModel;
    if (s == null) return 'Not set';
    return s.shortDisplay;
  }

  int? get ageInYears {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month || (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  int get completionPercentage {
    int total = 14;
    int filled = 0;
    if (fullName.trim().isNotEmpty) filled++;
    if (dateOfBirth != null) filled++;
    if (gender != null && gender!.isNotEmpty) filled++;
    if (socialCategory.isNotEmpty) filled++;
    if (state != null && state!.isNotEmpty) filled++;
    if (district != null && district!.isNotEmpty) filled++;
    if (currentStatus != null && currentStatus!.isNotEmpty) filled++;
    if (class10Year != null || class12Year != null) filled++;
    if (highestQualification != null && highestQualification!.isNotEmpty) filled++;
    if ((degreeName != null && degreeName!.isNotEmpty) || (stream != null && stream!.isNotEmpty)) filled++;
    if (effectiveScore != null && effectiveScore! > 0) filled++;
    if (preferredCategories.isNotEmpty) filled++;
    if (careerInterests.isNotEmpty) filled++;
    if (avatarUrl != null && avatarUrl!.isNotEmpty) filled++;
    return ((filled / total) * 100).round();
  }

  int? calculateAge([DateTime? atDate]) {
    if (dateOfBirth == null) return null;
    final reference = atDate ?? DateTime.now();
    int age = reference.year - dateOfBirth!.year;
    if (reference.month < dateOfBirth!.month ||
        (reference.month == dateOfBirth!.month && reference.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  CandidateProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? nationality,
    String? state,
    String? district,
    String? countryOfResidence,
    String? avatarUrl,
    String? currentStatus,
    String? socialCategory,
    bool? isObcNcl,
    bool? isPwBD,
    String? pwbdDisabilityType,
    bool? isExServiceman,
    List<String>? additionalRelaxations,
    int? class10Year,
    double? class10Percentage,
    int? class12Year,
    String? class12Stream,
    double? class12Percentage,
    String? class12GradingSystem,
    String? highestQualification,
    String? degreeName,
    String? stream,
    String? institution,
    String? university,
    String? collegeName,
    bool? isInstitutionRecognized,
    int? currentYearOfStudy,
    int? currentSemester,
    int? degreeDurationYears,
    String? academicStatus,
    String? gradingSystem,
    double? gradingScaleMax,
    double? cgpa,
    double? percentage,
    double? gpa,
    AcademicScore? academicScore,
    Map<String, dynamic>? yearWisePerformance,
    Map<String, dynamic>? semesterWisePerformance,
    String? conversionFormula,
    String? conversionSource,
    int? graduationYear,
    DateTime? expectedGraduationDate,
    double? cgpaOrPercentage,
    String? degreeStatus,
    bool? hasActiveBacklogs,
    int? gateScore,
    int? gateYear,
    bool? hasNetJrf,
    String? netSubject,
    String? postgradDegree,
    String? postgradStream,
    int? postgradYear,
    double? postgradScore,
    double? workExperienceYears,
    int? researchExperienceMonths,
    List<String>? certifications,
    List<ExaminationCategory>? preferredCategories,
    List<String>? preferredStates,
    bool? willingToRelocate,
    bool? willingToWorkAnywhereInIndia,
    num? maxApplicationFeeBudget,
    List<String>? careerInterests,
  }) {
    return CandidateProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      nationality: nationality ?? this.nationality,
      state: state ?? this.state,
      district: district ?? this.district,
      countryOfResidence: countryOfResidence ?? this.countryOfResidence,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      currentStatus: currentStatus ?? this.currentStatus,
      socialCategory: socialCategory ?? this.socialCategory,
      isObcNcl: isObcNcl ?? this.isObcNcl,
      isPwBD: isPwBD ?? this.isPwBD,
      pwbdDisabilityType: pwbdDisabilityType ?? this.pwbdDisabilityType,
      isExServiceman: isExServiceman ?? this.isExServiceman,
      additionalRelaxations: additionalRelaxations ?? this.additionalRelaxations,
      class10Year: class10Year ?? this.class10Year,
      class10Percentage: class10Percentage ?? this.class10Percentage,
      class12Year: class12Year ?? this.class12Year,
      class12Stream: class12Stream ?? this.class12Stream,
      class12Percentage: class12Percentage ?? this.class12Percentage,
      class12GradingSystem: class12GradingSystem ?? this.class12GradingSystem,
      highestQualification: highestQualification ?? this.highestQualification,
      degreeName: degreeName ?? this.degreeName,
      stream: stream ?? this.stream,
      institution: institution ?? this.institution,
      university: university ?? this.university,
      collegeName: collegeName ?? this.collegeName,
      isInstitutionRecognized: isInstitutionRecognized ?? this.isInstitutionRecognized,
      currentYearOfStudy: currentYearOfStudy ?? this.currentYearOfStudy,
      currentSemester: currentSemester ?? this.currentSemester,
      degreeDurationYears: degreeDurationYears ?? this.degreeDurationYears,
      academicStatus: academicStatus ?? this.academicStatus,
      gradingSystem: gradingSystem ?? this.gradingSystem,
      gradingScaleMax: gradingScaleMax ?? this.gradingScaleMax,
      cgpa: cgpa ?? this.cgpa,
      percentage: percentage ?? this.percentage,
      gpa: gpa ?? this.gpa,
      academicScore: academicScore ?? this.academicScore,
      yearWisePerformance: yearWisePerformance ?? this.yearWisePerformance,
      semesterWisePerformance: semesterWisePerformance ?? this.semesterWisePerformance,
      conversionFormula: conversionFormula ?? this.conversionFormula,
      conversionSource: conversionSource ?? this.conversionSource,
      graduationYear: graduationYear ?? this.graduationYear,
      expectedGraduationDate: expectedGraduationDate ?? this.expectedGraduationDate,
      cgpaOrPercentage: cgpaOrPercentage ?? this.cgpaOrPercentage,
      degreeStatus: degreeStatus ?? this.degreeStatus,
      hasActiveBacklogs: hasActiveBacklogs ?? this.hasActiveBacklogs,
      gateScore: gateScore ?? this.gateScore,
      gateYear: gateYear ?? this.gateYear,
      hasNetJrf: hasNetJrf ?? this.hasNetJrf,
      netSubject: netSubject ?? this.netSubject,
      postgradDegree: postgradDegree ?? this.postgradDegree,
      postgradStream: postgradStream ?? this.postgradStream,
      postgradYear: postgradYear ?? this.postgradYear,
      postgradScore: postgradScore ?? this.postgradScore,
      workExperienceYears: workExperienceYears ?? this.workExperienceYears,
      researchExperienceMonths: researchExperienceMonths ?? this.researchExperienceMonths,
      certifications: certifications ?? this.certifications,
      preferredCategories: preferredCategories ?? this.preferredCategories,
      preferredStates: preferredStates ?? this.preferredStates,
      willingToRelocate: willingToRelocate ?? this.willingToRelocate,
      willingToWorkAnywhereInIndia: willingToWorkAnywhereInIndia ?? this.willingToWorkAnywhereInIndia,
      maxApplicationFeeBudget: maxApplicationFeeBudget ?? this.maxApplicationFeeBudget,
      careerInterests: careerInterests ?? this.careerInterests,
    );
  }

  factory CandidateProfile.fromSupabase(Map<String, dynamic> data, {String? email}) {
    DateTime? dob;
    if (data['date_of_birth'] != null) {
      dob = DateTime.tryParse(data['date_of_birth'].toString());
    }

    Map<String, dynamic>? eduRes;
    if (data['candidate_education'] is List && (data['candidate_education'] as List).isNotEmpty) {
      eduRes = Map<String, dynamic>.from((data['candidate_education'] as List).first as Map);
    } else if (data['candidate_education'] is Map) {
      eduRes = Map<String, dynamic>.from(data['candidate_education'] as Map);
    }

    final categories = <ExaminationCategory>[];
    if (data['candidate_preferences'] is List) {
      for (final p in (data['candidate_preferences'] as List)) {
        if (p is Map && p['preferred_category'] != null) {
          categories.add(ExaminationCategory.fromString(p['preferred_category'].toString()));
        }
      }
    }

    int? gScore;
    int? gYear;
    if (data['candidate_competitive_exams'] is List) {
      for (final exam in (data['candidate_competitive_exams'] as List)) {
        if (exam is Map && exam['exam_name'] == 'GATE') {
          gScore = exam['score'] is num ? (exam['score'] as num).toInt() : null;
          gYear = exam['year'] is num ? (exam['year'] as num).toInt() : null;
        }
      }
    }

    // Resolving grading system and score fields
    final rawSystem = eduRes?['grading_system']?.toString() ??
        (eduRes?['cgpa'] != null
            ? 'cgpa'
            : (eduRes?['percentage'] != null ? 'percentage' : null));

    final effectiveSystem = rawSystem ?? 'cgpa';
    final scaleMax = eduRes?['grading_scale_max'] is num
        ? (eduRes!['grading_scale_max'] as num).toDouble()
        : (effectiveSystem == 'percentage' ? 100.0 : (effectiveSystem == 'gpa' ? 4.0 : 10.0));

    double? parsedCgpa = eduRes?['cgpa'] is num ? (eduRes!['cgpa'] as num).toDouble() : null;
    double? parsedPercentage = eduRes?['percentage'] is num ? (eduRes!['percentage'] as num).toDouble() : null;
    double? parsedGpa = eduRes?['gpa'] is num ? (eduRes!['gpa'] as num).toDouble() : null;

    final rawScoreVal = (eduRes?['cgpa_or_percentage'] ?? data['cgpa_or_percentage']) is num
        ? ((eduRes?['cgpa_or_percentage'] ?? data['cgpa_or_percentage']) as num).toDouble()
        : null;

    if (rawScoreVal != null) {
      if (effectiveSystem == 'cgpa' && parsedCgpa == null) parsedCgpa = rawScoreVal;
      if (effectiveSystem == 'percentage' && parsedPercentage == null) parsedPercentage = rawScoreVal;
      if (effectiveSystem == 'gpa' && parsedGpa == null) parsedGpa = rawScoreVal;
    }

    final activeScoreValue = parsedCgpa ?? parsedPercentage ?? parsedGpa ?? rawScoreVal;
    AcademicScore? resolvedAcademicScore;
    if (activeScoreValue != null) {
      resolvedAcademicScore = AcademicScore(
        scoreValue: activeScoreValue,
        gradingType: AcademicGradingType.fromString(effectiveSystem),
        gradingScaleMax: scaleMax,
      );
    }

    return CandidateProfile(
      id: data['id']?.toString() ?? '',
      email: email ?? data['email']?.toString() ?? '',
      fullName: data['full_name']?.toString() ?? '',
      dateOfBirth: dob,
      gender: data['gender']?.toString(),
      nationality: data['nationality']?.toString() ?? 'Indian',
      state: data['state']?.toString(),
      district: data['district']?.toString(),
      avatarUrl: data['avatar_url']?.toString(),
      socialCategory: data['social_category']?.toString() ?? 'General',
      isObcNcl: data['is_obc_ncl'] == true,
      isPwBD: data['is_pwbd'] == true,
      pwbdDisabilityType: data['pwbd_disability_type']?.toString(),
      isExServiceman: data['is_ex_serviceman'] == true,
      currentStatus: data['current_status']?.toString(),
      class10Year: data['class_10_year'] is num ? (data['class_10_year'] as num).toInt() : null,
      class10Percentage: data['class_10_percentage'] is num ? (data['class_10_percentage'] as num).toDouble() : null,
      class12Year: data['class_12_year'] is num ? (data['class_12_year'] as num).toInt() : null,
      class12Stream: data['class_12_stream']?.toString(),
      class12Percentage: data['class_12_percentage'] is num ? (data['class_12_percentage'] as num).toDouble() : null,
      class12GradingSystem: data['class_12_grading_system']?.toString() ?? 'percentage',
      highestQualification: data['highest_qualification']?.toString() ?? eduRes?['highest_qualification']?.toString(),
      degreeName: data['degree_name']?.toString() ?? eduRes?['degree_name']?.toString(),
      stream: data['stream']?.toString() ?? eduRes?['stream']?.toString(),
      institution: data['institution']?.toString() ?? eduRes?['institution']?.toString(),
      graduationYear: data['graduation_year'] is num
          ? (data['graduation_year'] as num).toInt()
          : (eduRes?['graduation_year'] is num ? (eduRes!['graduation_year'] as num).toInt() : null),
      cgpaOrPercentage: activeScoreValue,
      degreeStatus: data['degree_status']?.toString() ?? eduRes?['degree_status']?.toString(),
      hasActiveBacklogs: data['has_active_backlogs'] == true || eduRes?['has_active_backlogs'] == true,
      university: eduRes?['university']?.toString(),
      collegeName: eduRes?['college_name']?.toString(),
      currentYearOfStudy: eduRes?['current_year_of_study'] is num ? (eduRes!['current_year_of_study'] as num).toInt() : null,
      currentSemester: eduRes?['current_semester'] is num ? (eduRes!['current_semester'] as num).toInt() : null,
      degreeDurationYears: eduRes?['degree_duration_years'] is num ? (eduRes!['degree_duration_years'] as num).toInt() : 4,
      academicStatus: eduRes?['academic_status']?.toString() ?? 'completed',
      gradingSystem: effectiveSystem,
      gradingScaleMax: scaleMax,
      cgpa: parsedCgpa,
      percentage: parsedPercentage,
      gpa: parsedGpa,
      academicScore: resolvedAcademicScore,
      yearWisePerformance: eduRes?['year_wise_performance'] is Map
          ? Map<String, dynamic>.from(eduRes!['year_wise_performance'] as Map)
          : const {},
      semesterWisePerformance: eduRes?['semester_wise_performance'] is Map
          ? Map<String, dynamic>.from(eduRes!['semester_wise_performance'] as Map)
          : const {},
      conversionFormula: eduRes?['conversion_formula']?.toString(),
      conversionSource: eduRes?['conversion_source']?.toString(),
      gateScore: gScore,
      gateYear: gYear,
      preferredCategories: categories.isNotEmpty
          ? categories
          : const [
              ExaminationCategory.govtRecruitment,
              ExaminationCategory.psu,
              ExaminationCategory.entranceExam,
            ],
    );
  }
}
