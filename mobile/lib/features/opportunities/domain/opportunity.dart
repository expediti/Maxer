enum OpportunityCategory {
  govtRecruitment('Government Recruitment'),
  psu('PSU Recruitment'),
  privateJob('Private Jobs & Graduate Programmes'),
  entranceExam('Entrance Examinations'),
  admissions('University Admissions'),
  scholarship('Scholarships & Fellowships'),
  internshipResearch('Research & Internships'),
  certification('Professional Certifications');

  final String label;
  const OpportunityCategory(this.label);
}

enum EligibilityStatus {
  eligible('Eligible'),
  potentiallyEligible('Potentially Eligible'),
  notEligible('Not Eligible'),
  missingInformation('Review Needed');

  final String label;
  const EligibilityStatus(this.label);
}

class Opportunity {
  final String id;
  final String title;
  final String organisation;
  final String issuingAuthority;
  final OpportunityCategory category;
  final String overview;
  final int? vacancies;
  final String eligibilityCriteriaSummary;
  final int minAge;
  final int maxAge;
  final Map<String, String> categoryAgeRelaxation;
  final List<String> educationalQualifications;
  final List<String> eligibleStreams;
  final double? minPercentage;
  final String nationality;
  final String genderRequirements;
  final String workExperience;
  final num? applicationFee;
  final String feeExemptions;
  final List<String> requiredDocuments;
  final Map<String, DateTime?> importantDates;
  final String selectionProcedure;
  final String? examPattern;
  final String? salaryOrPayScale;
  final String location;
  final String applicationInstructions;
  final String? officialNotificationPdfUrl;
  final String officialApplicationUrl;
  final String sourceUrl;
  final DateTime lastVerifiedAt;
  final bool isOfficialSource;
  final DateTime applicationDeadline;
  final bool isCentralGovernment;
  final String? state;
  final bool isConfirmed;
  final List<String> uncertainFields;

  const Opportunity({
    required this.id,
    required this.title,
    required this.organisation,
    required this.issuingAuthority,
    required this.category,
    required this.overview,
    this.vacancies,
    required this.eligibilityCriteriaSummary,
    required this.minAge,
    required this.maxAge,
    required this.categoryAgeRelaxation,
    required this.educationalQualifications,
    required this.eligibleStreams,
    this.minPercentage,
    required this.nationality,
    required this.genderRequirements,
    required this.workExperience,
    this.applicationFee,
    required this.feeExemptions,
    required this.requiredDocuments,
    required this.importantDates,
    required this.selectionProcedure,
    this.examPattern,
    this.salaryOrPayScale,
    required this.location,
    required this.applicationInstructions,
    this.officialNotificationPdfUrl,
    required this.officialApplicationUrl,
    required this.sourceUrl,
    required this.lastVerifiedAt,
    required this.isOfficialSource,
    required this.applicationDeadline,
    required this.isCentralGovernment,
    this.state,
    this.isConfirmed = true,
    this.uncertainFields = const [],
  });
}

