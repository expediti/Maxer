import 'examination.dart';

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

  // Category
  final String socialCategory;
  final bool isPwBD;
  final String? pwbdDisabilityType;
  final bool isExServiceman;
  final List<String> additionalRelaxations;

  // Education
  final String? highestQualification;
  final String? degreeName;
  final String? stream;
  final String? institution;
  final bool isInstitutionRecognized;
  final int? graduationYear;
  final DateTime? expectedGraduationDate;
  final double? cgpaOrPercentage;
  final bool hasActiveBacklogs;
  final int? gateScore;
  final int? gateYear;
  final bool hasNetJrf;
  final String? netSubject;
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
    this.socialCategory = 'General',
    this.isPwBD = false,
    this.pwbdDisabilityType,
    this.isExServiceman = false,
    this.additionalRelaxations = const [],
    this.highestQualification,
    this.degreeName,
    this.stream,
    this.institution,
    this.isInstitutionRecognized = true,
    this.graduationYear,
    this.expectedGraduationDate,
    this.cgpaOrPercentage,
    this.hasActiveBacklogs = false,
    this.gateScore,
    this.gateYear,
    this.hasNetJrf = false,
    this.netSubject,
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
    int total = 12;
    int filled = 0;
    if (fullName.trim().isNotEmpty) filled++;
    if (dateOfBirth != null) filled++;
    if (gender != null) filled++;
    if (state != null) filled++;
    if (socialCategory.isNotEmpty) filled++;
    if (highestQualification != null) filled++;
    if (degreeName != null) filled++;
    if (stream != null) filled++;
    if (cgpaOrPercentage != null) filled++;
    if (preferredCategories.isNotEmpty) filled++;
    if (willingToRelocate || preferredStates.isNotEmpty) filled++;
    if (careerInterests.isNotEmpty) filled++;
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
    String? socialCategory,
    bool? isPwBD,
    String? pwbdDisabilityType,
    bool? isExServiceman,
    List<String>? additionalRelaxations,
    String? highestQualification,
    String? degreeName,
    String? stream,
    String? institution,
    bool? isInstitutionRecognized,
    int? graduationYear,
    DateTime? expectedGraduationDate,
    double? cgpaOrPercentage,
    bool? hasActiveBacklogs,
    int? gateScore,
    int? gateYear,
    bool? hasNetJrf,
    String? netSubject,
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
      socialCategory: socialCategory ?? this.socialCategory,
      isPwBD: isPwBD ?? this.isPwBD,
      pwbdDisabilityType: pwbdDisabilityType ?? this.pwbdDisabilityType,
      isExServiceman: isExServiceman ?? this.isExServiceman,
      additionalRelaxations: additionalRelaxations ?? this.additionalRelaxations,
      highestQualification: highestQualification ?? this.highestQualification,
      degreeName: degreeName ?? this.degreeName,
      stream: stream ?? this.stream,
      institution: institution ?? this.institution,
      isInstitutionRecognized: isInstitutionRecognized ?? this.isInstitutionRecognized,
      graduationYear: graduationYear ?? this.graduationYear,
      expectedGraduationDate: expectedGraduationDate ?? this.expectedGraduationDate,
      cgpaOrPercentage: cgpaOrPercentage ?? this.cgpaOrPercentage,
      hasActiveBacklogs: hasActiveBacklogs ?? this.hasActiveBacklogs,
      gateScore: gateScore ?? this.gateScore,
      gateYear: gateYear ?? this.gateYear,
      hasNetJrf: hasNetJrf ?? this.hasNetJrf,
      netSubject: netSubject ?? this.netSubject,
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
}
