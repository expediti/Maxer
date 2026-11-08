import 'package:rexam/features/opportunities/domain/opportunity.dart';

class CandidateProfile {
  final String id;
  final String email;

  // A. Personal Information
  final String fullName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String nationality;
  final String? state;
  final String? district;
  final String countryOfResidence;

  // B. Category
  final String socialCategory; // General, OBC-NCL, SC, ST, EWS
  final bool isPwBD;
  final String? pwbdDisabilityType;
  final bool isExServiceman;
  final List<String> additionalRelaxations;

  // C. Educational Information
  final String? highestQualification;
  final String? currentQualification;
  final String? degreeName;
  final String? stream;
  final String? universityOrCollege;
  final bool isUniversityRecognized;
  final int? graduationYear;
  final int? expectedGraduationYear;
  final double? cgpaOrPercentage;
  final bool hasActiveBacklogs;
  final int? currentSemester;

  // D. Additional Qualifications
  final int? gateScore;
  final int? gateYear;
  final bool hasNetJrf;
  final String? netSubject;
  final Map<String, String> competitiveExamScores;
  final List<String> certifications;
  final double workExperienceYears;
  final int researchExperienceMonths;

  // E. Opportunity Preferences
  final List<OpportunityCategory> preferredCategories;

  // F. Financial & Location Preferences
  final num? maxApplicationFeeBudget;
  final bool willingToRelocate;
  final List<String> preferredStates;
  final bool willingToWorkAnywhereInIndia;

  // G. Career Interests
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
    this.socialCategory = 'General',
    this.isPwBD = false,
    this.pwbdDisabilityType,
    this.isExServiceman = false,
    this.additionalRelaxations = const [],
    this.highestQualification,
    this.currentQualification,
    this.degreeName,
    this.stream,
    this.universityOrCollege,
    this.isUniversityRecognized = true,
    this.graduationYear,
    this.expectedGraduationYear,
    this.cgpaOrPercentage,
    this.hasActiveBacklogs = false,
    this.currentSemester,
    this.gateScore,
    this.gateYear,
    this.hasNetJrf = false,
    this.netSubject,
    this.competitiveExamScores = const {},
    this.certifications = const [],
    this.workExperienceYears = 0.0,
    this.researchExperienceMonths = 0,
    this.preferredCategories = const [
      OpportunityCategory.govtRecruitment,
      OpportunityCategory.psu,
      OpportunityCategory.entranceExam,
    ],
    this.maxApplicationFeeBudget,
    this.willingToRelocate = true,
    this.preferredStates = const [],
    this.willingToWorkAnywhereInIndia = true,
    this.careerInterests = const ['Engineering', 'Computer Science', 'Administration'],
  });

  /// Calculates candidate's age today
  int? get ageInYears {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month || (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  /// Calculates completion percentage for profile setup
  int get completionPercentage {
    int totalPoints = 12;
    int earned = 0;

    if (fullName.trim().isNotEmpty) earned++;
    if (dateOfBirth != null) earned++;
    if (gender != null && gender!.isNotEmpty) earned++;
    if (state != null && state!.isNotEmpty) earned++;
    if (socialCategory.isNotEmpty) earned++;
    if (highestQualification != null && highestQualification!.isNotEmpty) earned++;
    if (degreeName != null && degreeName!.isNotEmpty) earned++;
    if (stream != null && stream!.isNotEmpty) earned++;
    if (cgpaOrPercentage != null) earned++;
    if (preferredCategories.isNotEmpty) earned++;
    if (preferredStates.isNotEmpty || willingToWorkAnywhereInIndia) earned++;
    if (careerInterests.isNotEmpty) earned++;

    return ((earned / totalPoints) * 100).round();
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
    String? socialCategory,
    bool? isPwBD,
    String? pwbdDisabilityType,
    bool? isExServiceman,
    List<String>? additionalRelaxations,
    String? highestQualification,
    String? currentQualification,
    String? degreeName,
    String? stream,
    String? universityOrCollege,
    bool? isUniversityRecognized,
    int? graduationYear,
    int? expectedGraduationYear,
    double? cgpaOrPercentage,
    bool? hasActiveBacklogs,
    int? currentSemester,
    int? gateScore,
    int? gateYear,
    bool? hasNetJrf,
    String? netSubject,
    Map<String, String>? competitiveExamScores,
    List<String>? certifications,
    double? workExperienceYears,
    int? researchExperienceMonths,
    List<OpportunityCategory>? preferredCategories,
    num? maxApplicationFeeBudget,
    bool? willingToRelocate,
    List<String>? preferredStates,
    bool? willingToWorkAnywhereInIndia,
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
      socialCategory: socialCategory ?? this.socialCategory,
      isPwBD: isPwBD ?? this.isPwBD,
      pwbdDisabilityType: pwbdDisabilityType ?? this.pwbdDisabilityType,
      isExServiceman: isExServiceman ?? this.isExServiceman,
      additionalRelaxations: additionalRelaxations ?? this.additionalRelaxations,
      highestQualification: highestQualification ?? this.highestQualification,
      currentQualification: currentQualification ?? this.currentQualification,
      degreeName: degreeName ?? this.degreeName,
      stream: stream ?? this.stream,
      universityOrCollege: universityOrCollege ?? this.universityOrCollege,
      isUniversityRecognized: isUniversityRecognized ?? this.isUniversityRecognized,
      graduationYear: graduationYear ?? this.graduationYear,
      expectedGraduationYear: expectedGraduationYear ?? this.expectedGraduationYear,
      cgpaOrPercentage: cgpaOrPercentage ?? this.cgpaOrPercentage,
      hasActiveBacklogs: hasActiveBacklogs ?? this.hasActiveBacklogs,
      currentSemester: currentSemester ?? this.currentSemester,
      gateScore: gateScore ?? this.gateScore,
      gateYear: gateYear ?? this.gateYear,
      hasNetJrf: hasNetJrf ?? this.hasNetJrf,
      netSubject: netSubject ?? this.netSubject,
      competitiveExamScores: competitiveExamScores ?? this.competitiveExamScores,
      certifications: certifications ?? this.certifications,
      workExperienceYears: workExperienceYears ?? this.workExperienceYears,
      researchExperienceMonths: researchExperienceMonths ?? this.researchExperienceMonths,
      preferredCategories: preferredCategories ?? this.preferredCategories,
      maxApplicationFeeBudget: maxApplicationFeeBudget ?? this.maxApplicationFeeBudget,
      willingToRelocate: willingToRelocate ?? this.willingToRelocate,
      preferredStates: preferredStates ?? this.preferredStates,
      willingToWorkAnywhereInIndia: willingToWorkAnywhereInIndia ?? this.willingToWorkAnywhereInIndia,
      careerInterests: careerInterests ?? this.careerInterests,
    );
  }
}
