enum ExaminationCategory {
  govtRecruitment('Government Recruitment'),
  psu('PSU Recruitment'),
  privateJob('Private Jobs & Graduate Programmes'),
  entranceExam('Entrance Examinations'),
  admissions('University Admissions'),
  scholarship('Scholarships & Fellowships'),
  internshipResearch('Research & Internships'),
  certification('Professional Certifications');

  final String label;
  const ExaminationCategory(this.label);

  static ExaminationCategory fromString(String val) {
    for (final c in ExaminationCategory.values) {
      if (c.label.toLowerCase() == val.toLowerCase() || c.name.toLowerCase() == val.toLowerCase()) {
        return c;
      }
    }
    return ExaminationCategory.govtRecruitment;
  }
}

enum ExaminationStatus {
  draft('Draft'),
  published('Published'),
  updated('Updated'),
  expired('Expired'),
  underReview('Under Review');

  final String label;
  const ExaminationStatus(this.label);
}

enum EligibilityStatus {
  eligible('Eligible'),
  potentiallyEligible('Potentially Eligible'),
  notEligible('Not Eligible'),
  missingInformation('Review Needed');

  final String label;
  const EligibilityStatus(this.label);
}

class Examination {
  final String id;
  final String organisationId;
  final String? sourceId;
  final String title;
  final String organisation;
  final String issuingAuthority;
  final ExaminationCategory category;
  final ExaminationStatus status;
  final String overview;
  final int? vacancies;
  final String eligibilityCriteriaSummary;
  final int? minAge;
  final int? maxAge;
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
  final DateTime? lastVerifiedAt;
  final bool isOfficialSource;
  final DateTime? applicationDeadline;
  final bool isCentralGovernment;
  final String? state;
  final bool isConfirmed;
  final List<String> uncertainFields;

  const Examination({
    required this.id,
    this.organisationId = '',
    this.sourceId,
    required this.title,
    required this.organisation,
    this.issuingAuthority = '',
    required this.category,
    this.status = ExaminationStatus.published,
    this.overview = '',
    this.vacancies,
    this.eligibilityCriteriaSummary = '',
    this.minAge,
    this.maxAge,
    this.categoryAgeRelaxation = const {},
    this.educationalQualifications = const [],
    this.eligibleStreams = const [],
    this.minPercentage,
    this.nationality = 'Indian',
    this.genderRequirements = 'All genders eligible.',
    this.workExperience = 'Not required',
    this.applicationFee,
    this.feeExemptions = '',
    this.requiredDocuments = const [],
    this.importantDates = const {},
    this.selectionProcedure = '',
    this.examPattern,
    this.salaryOrPayScale,
    this.location = 'All India',
    this.applicationInstructions = '',
    this.officialNotificationPdfUrl,
    this.officialApplicationUrl = '',
    this.sourceUrl = '',
    this.lastVerifiedAt,
    this.isOfficialSource = true,
    this.applicationDeadline,
    this.isCentralGovernment = true,
    this.state,
    this.isConfirmed = true,
    this.uncertainFields = const [],
  });

  factory Examination.fromSupabase(Map<String, dynamic> json, {Map<String, dynamic>? datesJson, Map<String, dynamic>? rulesJson, Map<String, dynamic>? orgJson}) {
    final dates = datesJson ?? json['examination_dates'] as Map<String, dynamic>? ?? {};
    final rules = rulesJson ?? json['eligibility_rules'] as Map<String, dynamic>? ?? {};
    final org = orgJson ?? json['organisations'] as Map<String, dynamic>? ?? {};

    DateTime? closingDate;
    if (dates['application_closing_date'] != null) {
      closingDate = DateTime.tryParse(dates['application_closing_date'].toString());
    }
    closingDate ??= DateTime.now().add(const Duration(days: 30));

    Map<String, DateTime?> importantDatesMap = {};
    if (dates['notification_date'] != null) {
      importantDatesMap['Notification Date'] = DateTime.tryParse(dates['notification_date'].toString());
    }
    if (dates['application_closing_date'] != null) {
      importantDatesMap['Application Deadline'] = DateTime.tryParse(dates['application_closing_date'].toString());
    }
    if (dates['examination_start_date'] != null) {
      importantDatesMap['Examination Date'] = DateTime.tryParse(dates['examination_start_date'].toString());
    }

    return Examination(
      id: json['id']?.toString() ?? '',
      organisationId: json['organisation_id']?.toString() ?? '',
      sourceId: json['source_id']?.toString(),
      title: json['name']?.toString() ?? '',
      organisation: org['name']?.toString() ?? json['organisation_name']?.toString() ?? 'Official Authority',
      issuingAuthority: org['parent_ministry']?.toString() ?? 'Government of India',
      category: ExaminationCategory.fromString(json['category']?.toString() ?? ''),
      status: ExaminationStatus.published,
      overview: json['overview']?.toString() ?? '',
      vacancies: json['vacancies'] != null ? int.tryParse(json['vacancies'].toString()) : null,
      eligibilityCriteriaSummary: rules['extracted_rule_text']?.toString() ?? 'Refer official notification.',
      minAge: rules['min_age'] != null ? int.tryParse(rules['min_age'].toString()) ?? 18 : 18,
      maxAge: rules['max_age'] != null ? int.tryParse(rules['max_age'].toString()) ?? 35 : 35,
      categoryAgeRelaxation: rules['category_age_relaxations'] is Map
          ? (rules['category_age_relaxations'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()))
          : {},
      educationalQualifications: (rules['educational_qualifications'] as List?)?.map((e) => e.toString()).toList() ?? ['Graduate degree in relevant stream'],
      eligibleStreams: (rules['eligible_branches'] as List?)?.map((e) => e.toString()).toList() ?? ['All Disciplines'],
      minPercentage: rules['min_percentage'] != null ? double.tryParse(rules['min_percentage'].toString()) : null,
      nationality: rules['nationality']?.toString() ?? 'Citizen of India',
      genderRequirements: rules['gender_requirements']?.toString() ?? 'All genders eligible',
      workExperience: rules['work_experience_requirement']?.toString() ?? 'None required',
      applicationFee: rules['fee_general'] != null ? num.tryParse(rules['fee_general'].toString()) : null,
      feeExemptions: rules['fee_exemptions']?.toString() ?? 'SC/ST/PwBD and Female candidates exempted',
      requiredDocuments: (rules['required_documents'] as List?)?.map((e) => e.toString()).toList() ?? ['Class 10 Certificate', 'Degree Marksheet', 'Category Certificate if claiming relaxation'],
      importantDates: importantDatesMap,
      selectionProcedure: json['selection_procedure']?.toString() ?? 'Written examination followed by interview.',
      examPattern: json['exam_pattern']?.toString(),
      salaryOrPayScale: json['salary_or_pay_scale']?.toString(),
      location: json['location']?.toString() ?? 'All India',
      applicationInstructions: json['application_instructions']?.toString() ?? 'Apply online via the conducting authority portal.',
      officialNotificationPdfUrl: json['official_notification_url']?.toString(),
      officialApplicationUrl: json['official_application_url']?.toString() ?? 'https://upsconline.nic.in',
      sourceUrl: json['source_url']?.toString() ?? 'https://upsc.gov.in',
      lastVerifiedAt: DateTime.tryParse(json['last_verified_at']?.toString() ?? '') ?? DateTime.now(),
      isOfficialSource: json['is_official_source'] == true,
      applicationDeadline: closingDate,
      isCentralGovernment: json['is_central_government'] != false,
      state: json['state']?.toString(),
      isConfirmed: json['is_confirmed'] != false,
      uncertainFields: (json['uncertain_fields'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
