enum ExaminationCategory {
  govtRecruitment('Government Examinations'),
  stateGovt('State Government Jobs'),
  railway('Railways'),
  banking('Banking & Finance'),
  defence('Defence & Police'),
  research('Research & Science'),
  psu('PSU Recruitment'),
  teaching('Teaching & Academia'),
  healthcare('Healthcare & Medical'),
  lawJudicial('Law & Courts'),
  aviationTransport('Aviation & Transport'),
  agricultureEnv('Agriculture & Environment'),
  apprenticeship('Apprenticeships'),
  internship('Internships'),
  fellowship('Fellowships'),
  scholarship('Scholarships & Funding'),
  privateJob('Private Jobs'),
  admissions('Admissions & Entrance'),
  entranceExam('Entrance Examinations'), // Backwards compatibility alias
  internshipResearch('Research & Internships'), // Backwards compatibility alias
  certification('Professional Qualifications');

  final String label;
  const ExaminationCategory(this.label);

  static ExaminationCategory fromString(String val) {
    final lower = val.toLowerCase().trim();
    if (lower.contains('scholarship')) return ExaminationCategory.scholarship;
    if (lower.contains('fellowship')) return ExaminationCategory.fellowship;
    if (lower.contains('internship')) return ExaminationCategory.internship;
    if (lower.contains('apprentice')) return ExaminationCategory.apprenticeship;
    if (lower.contains('railway') || lower.contains('rrb') || lower.contains('rrc')) return ExaminationCategory.railway;
    if (lower.contains('bank') || lower.contains('ibps') || lower.contains('sbi') || lower.contains('rbi') || lower.contains('nabard') || lower.contains('sebi')) {
      return ExaminationCategory.banking;
    }
    if (lower.contains('defence') || lower.contains('army') || lower.contains('navy') || lower.contains('air force') || lower.contains('police') || lower.contains('rpf')) {
      return ExaminationCategory.defence;
    }
    if (lower.contains('state') || lower.contains('psc') || lower.contains('dsssb')) return ExaminationCategory.stateGovt;
    if (lower.contains('research') || lower.contains('science') || lower.contains('isro') || lower.contains('drdo') || lower.contains('barc') || lower.contains('csir')) {
      return ExaminationCategory.research;
    }
    if (lower.contains('psu') || lower.contains('powergrid') || lower.contains('iocl') || lower.contains('ongc') || lower.contains('ntpc') || lower.contains('bhel') || lower.contains('sail')) {
      return ExaminationCategory.psu;
    }
    if (lower.contains('teach') || lower.contains('ctet') || lower.contains('tet') || lower.contains('kvs') || lower.contains('nvs') || lower.contains('professor') || lower.contains('faculty')) {
      return ExaminationCategory.teaching;
    }
    if (lower.contains('health') || lower.contains('medical') || lower.contains('aiims') || lower.contains('norcet') || lower.contains('nursing') || lower.contains('esic') || lower.contains('doctor')) {
      return ExaminationCategory.healthcare;
    }
    if (lower.contains('law') || lower.contains('court') || lower.contains('judicial') || lower.contains('aibe')) return ExaminationCategory.lawJudicial;
    if (lower.contains('aviation') || lower.contains('maritime') || lower.contains('transport') || lower.contains('pilot') || lower.contains('dgca') || lower.contains('aai')) {
      return ExaminationCategory.aviationTransport;
    }
    if (lower.contains('agri') || lower.contains('icar') || lower.contains('forest') || lower.contains('fssai')) return ExaminationCategory.agricultureEnv;
    if (lower.contains('private') || lower.contains('corporate') || lower.contains('company')) return ExaminationCategory.privateJob;
    if (lower.contains('admission') || lower.contains('entrance') || lower.contains('gate') || lower.contains('jam') || lower.contains('neet') || lower.contains('jee') || lower.contains('cuet') || lower.contains('clat')) {
      return ExaminationCategory.admissions;
    }
    if (lower.contains('certif') || lower.contains('licens') || lower.contains('ca ') || lower.contains('cma') || lower.contains('cs ')) {
      return ExaminationCategory.certification;
    }

    for (final c in ExaminationCategory.values) {
      if (c.label.toLowerCase() == lower || c.name.toLowerCase() == lower) {
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

  // Static constants for backward-compatibility with tests and legacy references
  static const EligibilityStatus needsVerification = EligibilityStatus.missingInformation;
  static const EligibilityStatus unconfirmed = EligibilityStatus.missingInformation;

  final String label;
  const EligibilityStatus(this.label);
}

class Examination {
  final String id;
  final String slug;
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
  final double? minCgpa;
  final double cgpaScaleMax;
  final String gradingType; // 'percentage' | 'cgpa' | 'any'
  final List<String> acceptedGradingSystems;
  final bool acceptsFinalYearStudents;
  final bool acceptsAppearingCandidates;
  final int? minAcademicYearRequired; // e.g. 3 for GATE / CDS pre-final year
  final DateTime? degreeCompletionCutoffDate;
  final bool requiresConversionCertificate;
  final String? institutionConversionRequirements;
  final String nationality;
  final String genderRequirements;
  final String workExperience;
  final num? applicationFee;
  final String feeExemptions;
  final List<String> requiredDocuments;
  final Map<String, DateTime?> importantDates;
  // 10 Independent, unmerged statutory date fields
  final DateTime? notificationDate;
  final DateTime? applicationStartDate;
  final DateTime? applicationEndDate;
  final DateTime? correctionStartDate;
  final DateTime? correctionEndDate;
  final DateTime? admitCardDate;
  final DateTime? examStartDate;
  final DateTime? examEndDate;
  final DateTime? resultDate;
  final DateTime? ageCutoffDate;
  final String selectionProcedure;
  final String? examPattern;
  final String? salaryOrPayScale;
  final String? stipend;
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

  // Master opportunity extensions
  final String? opportunityType;
  final String? sector;
  final String? subSector;
  final String? requisitionId;
  final String? advertisementNumber;
  final String verificationStatus;
  final String verificationTier;
  final bool isApplicationUrlVerified;
  final String applicationUrlStatus;
  final String? verifiedApplicationUrl;
  final String? verifiedNotificationUrl;
  final String applicationStatus;
  final Map<String, dynamic> evidence;

  const Examination({
    required this.id,
    this.slug = '',
    this.organisationId = '',
    this.sourceId,
    required this.title,
    required this.organisation,
    this.issuingAuthority = '',
    required this.category,
    this.status = ExaminationStatus.published,
    this.applicationStatus = 'open',
    this.overview = '',
    this.vacancies,
    this.eligibilityCriteriaSummary = '',
    this.minAge,
    this.maxAge,
    this.categoryAgeRelaxation = const {},
    this.educationalQualifications = const [],
    this.eligibleStreams = const [],
    this.minPercentage,
    this.minCgpa,
    this.cgpaScaleMax = 10.0,
    this.gradingType = 'percentage',
    this.acceptedGradingSystems = const ['percentage', 'cgpa'],
    this.acceptsFinalYearStudents = false,
    this.acceptsAppearingCandidates = false,
    this.minAcademicYearRequired,
    this.degreeCompletionCutoffDate,
    this.requiresConversionCertificate = false,
    this.institutionConversionRequirements,
    this.nationality = 'Indian',
    this.genderRequirements = 'All genders eligible.',
    this.workExperience = 'Not required',
    this.applicationFee,
    this.feeExemptions = '',
    this.requiredDocuments = const [],
    this.importantDates = const {},
    this.notificationDate,
    this.applicationStartDate,
    this.applicationEndDate,
    this.correctionStartDate,
    this.correctionEndDate,
    this.admitCardDate,
    this.examStartDate,
    this.examEndDate,
    this.resultDate,
    this.ageCutoffDate,
    this.selectionProcedure = '',
    this.examPattern,
    this.salaryOrPayScale,
    this.stipend,
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
    this.opportunityType,
    this.sector,
    this.subSector,
    this.requisitionId,
    this.advertisementNumber,
    this.verificationStatus = 'verified',
    this.verificationTier = 'PARTIALLY_VERIFIED',
    this.isApplicationUrlVerified = false,
    this.applicationUrlStatus = 'NEEDS_REVIEW',
    this.verifiedApplicationUrl,
    this.verifiedNotificationUrl,
    this.evidence = const {},
  });

  Examination copyWith({
    String? id,
    String? slug,
    String? organisationId,
    String? sourceId,
    String? title,
    String? organisation,
    String? issuingAuthority,
    ExaminationCategory? category,
    ExaminationStatus? status,
    String? overview,
    int? vacancies,
    String? eligibilityCriteriaSummary,
    int? minAge,
    int? maxAge,
    Map<String, String>? categoryAgeRelaxation,
    List<String>? educationalQualifications,
    List<String>? eligibleStreams,
    double? minPercentage,
    double? minCgpa,
    double? cgpaScaleMax,
    String? gradingType,
    List<String>? acceptedGradingSystems,
    bool? acceptsFinalYearStudents,
    bool? acceptsAppearingCandidates,
    int? minAcademicYearRequired,
    DateTime? degreeCompletionCutoffDate,
    bool? requiresConversionCertificate,
    String? institutionConversionRequirements,
    String? nationality,
    String? genderRequirements,
    String? workExperience,
    num? applicationFee,
    String? feeExemptions,
    List<String>? requiredDocuments,
    Map<String, DateTime?>? importantDates,
    DateTime? notificationDate,
    DateTime? applicationStartDate,
    DateTime? applicationEndDate,
    DateTime? correctionStartDate,
    DateTime? correctionEndDate,
    DateTime? admitCardDate,
    DateTime? examStartDate,
    DateTime? examEndDate,
    DateTime? resultDate,
    DateTime? ageCutoffDate,
    String? selectionProcedure,
    String? examPattern,
    String? salaryOrPayScale,
    String? stipend,
    String? location,
    String? applicationInstructions,
    String? officialNotificationPdfUrl,
    String? officialApplicationUrl,
    String? sourceUrl,
    DateTime? lastVerifiedAt,
    bool? isOfficialSource,
    DateTime? applicationDeadline,
    bool? isCentralGovernment,
    String? state,
    bool? isConfirmed,
    List<String>? uncertainFields,
    String? opportunityType,
    String? sector,
    String? subSector,
    String? requisitionId,
    String? advertisementNumber,
    String? verificationStatus,
    String? applicationStatus,
    Map<String, dynamic>? evidence,
  }) {
    return Examination(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      organisationId: organisationId ?? this.organisationId,
      sourceId: sourceId ?? this.sourceId,
      title: title ?? this.title,
      organisation: organisation ?? this.organisation,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      category: category ?? this.category,
      status: status ?? this.status,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      overview: overview ?? this.overview,
      vacancies: vacancies ?? this.vacancies,
      eligibilityCriteriaSummary: eligibilityCriteriaSummary ?? this.eligibilityCriteriaSummary,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      categoryAgeRelaxation: categoryAgeRelaxation ?? this.categoryAgeRelaxation,
      educationalQualifications: educationalQualifications ?? this.educationalQualifications,
      eligibleStreams: eligibleStreams ?? this.eligibleStreams,
      minPercentage: minPercentage ?? this.minPercentage,
      minCgpa: minCgpa ?? this.minCgpa,
      cgpaScaleMax: cgpaScaleMax ?? this.cgpaScaleMax,
      gradingType: gradingType ?? this.gradingType,
      acceptedGradingSystems: acceptedGradingSystems ?? this.acceptedGradingSystems,
      acceptsFinalYearStudents: acceptsFinalYearStudents ?? this.acceptsFinalYearStudents,
      acceptsAppearingCandidates: acceptsAppearingCandidates ?? this.acceptsAppearingCandidates,
      minAcademicYearRequired: minAcademicYearRequired ?? this.minAcademicYearRequired,
      degreeCompletionCutoffDate: degreeCompletionCutoffDate ?? this.degreeCompletionCutoffDate,
      requiresConversionCertificate: requiresConversionCertificate ?? this.requiresConversionCertificate,
      institutionConversionRequirements: institutionConversionRequirements ?? this.institutionConversionRequirements,
      nationality: nationality ?? this.nationality,
      genderRequirements: genderRequirements ?? this.genderRequirements,
      workExperience: workExperience ?? this.workExperience,
      applicationFee: applicationFee ?? this.applicationFee,
      feeExemptions: feeExemptions ?? this.feeExemptions,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
      importantDates: importantDates ?? this.importantDates,
      notificationDate: notificationDate ?? this.notificationDate,
      applicationStartDate: applicationStartDate ?? this.applicationStartDate,
      applicationEndDate: applicationEndDate ?? this.applicationEndDate,
      correctionStartDate: correctionStartDate ?? this.correctionStartDate,
      correctionEndDate: correctionEndDate ?? this.correctionEndDate,
      admitCardDate: admitCardDate ?? this.admitCardDate,
      examStartDate: examStartDate ?? this.examStartDate,
      examEndDate: examEndDate ?? this.examEndDate,
      resultDate: resultDate ?? this.resultDate,
      ageCutoffDate: ageCutoffDate ?? this.ageCutoffDate,
      selectionProcedure: selectionProcedure ?? this.selectionProcedure,
      examPattern: examPattern ?? this.examPattern,
      salaryOrPayScale: salaryOrPayScale ?? this.salaryOrPayScale,
      stipend: stipend ?? this.stipend,
      location: location ?? this.location,
      applicationInstructions: applicationInstructions ?? this.applicationInstructions,
      officialNotificationPdfUrl: officialNotificationPdfUrl ?? this.officialNotificationPdfUrl,
      officialApplicationUrl: officialApplicationUrl ?? this.officialApplicationUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      isOfficialSource: isOfficialSource ?? this.isOfficialSource,
      applicationDeadline: applicationDeadline ?? this.applicationDeadline,
      isCentralGovernment: isCentralGovernment ?? this.isCentralGovernment,
      state: state ?? this.state,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      uncertainFields: uncertainFields ?? this.uncertainFields,
      opportunityType: opportunityType ?? this.opportunityType,
      sector: sector ?? this.sector,
      subSector: subSector ?? this.subSector,
      requisitionId: requisitionId ?? this.requisitionId,
      advertisementNumber: advertisementNumber ?? this.advertisementNumber,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      evidence: evidence ?? this.evidence,
    );
  }

  factory Examination.fromSupabase(
    Map<String, dynamic> json, {
    Map<String, dynamic>? datesJson,
    Map<String, dynamic>? rulesJson,
    Map<String, dynamic>? orgJson,
  }) {
    Map<String, dynamic> dates = {};
    if (datesJson != null) {
      dates = datesJson;
    } else if (json['examination_dates'] is List && (json['examination_dates'] as List).isNotEmpty) {
      dates = Map<String, dynamic>.from((json['examination_dates'] as List).first as Map);
    } else if (json['examination_dates'] is Map) {
      dates = Map<String, dynamic>.from(json['examination_dates'] as Map);
    }

    Map<String, dynamic> rules = {};
    if (rulesJson != null) {
      rules = rulesJson;
    } else if (json['eligibility_rules'] is List && (json['eligibility_rules'] as List).isNotEmpty) {
      rules = Map<String, dynamic>.from((json['eligibility_rules'] as List).first as Map);
    } else if (json['eligibility_rules'] is Map) {
      rules = Map<String, dynamic>.from(json['eligibility_rules'] as Map);
    }

    Map<String, dynamic> org = {};
    if (orgJson != null) {
      org = orgJson;
    } else if (json['organisations'] is List && (json['organisations'] as List).isNotEmpty) {
      org = Map<String, dynamic>.from((json['organisations'] as List).first as Map);
    } else if (json['organisations'] is Map) {
      org = Map<String, dynamic>.from(json['organisations'] as Map);
    }

    // -------------------------------------------------------------------------
    // Exact parsing of 10 independent date fields (No fallback generation)
    // -------------------------------------------------------------------------
    final DateTime? notificationDate = DateTime.tryParse(dates['notification_date']?.toString() ?? '') ??
        DateTime.tryParse(json['notification_date']?.toString() ?? '');

    final DateTime? applicationStartDate = DateTime.tryParse(dates['application_opening_date']?.toString() ?? '') ??
        DateTime.tryParse(dates['application_start_date']?.toString() ?? '') ??
        DateTime.tryParse(json['application_start_date']?.toString() ?? '') ??
        DateTime.tryParse(json['application_open_date']?.toString() ?? '');

    final DateTime? applicationEndDate = DateTime.tryParse(dates['application_closing_date']?.toString() ?? '') ??
        DateTime.tryParse(dates['application_end_date']?.toString() ?? '') ??
        DateTime.tryParse(json['application_end_date']?.toString() ?? '') ??
        DateTime.tryParse(json['application_close_date']?.toString() ?? '');

    final DateTime? correctionStartDate = DateTime.tryParse(dates['correction_window_start']?.toString() ?? '') ??
        DateTime.tryParse(dates['correction_start_date']?.toString() ?? '') ??
        DateTime.tryParse(json['correction_start_date']?.toString() ?? '');

    final DateTime? correctionEndDate = DateTime.tryParse(dates['correction_window_end']?.toString() ?? '') ??
        DateTime.tryParse(dates['correction_end_date']?.toString() ?? '') ??
        DateTime.tryParse(json['correction_end_date']?.toString() ?? '');

    final DateTime? admitCardDate = DateTime.tryParse(dates['admit_card_release_date']?.toString() ?? '') ??
        DateTime.tryParse(dates['admit_card_date']?.toString() ?? '') ??
        DateTime.tryParse(json['admit_card_date']?.toString() ?? '');

    final DateTime? examStartDate = DateTime.tryParse(dates['examination_start_date']?.toString() ?? '') ??
        DateTime.tryParse(dates['exam_start_date']?.toString() ?? '') ??
        DateTime.tryParse(dates['prelims_date']?.toString() ?? '') ??
        DateTime.tryParse(json['exam_start_date']?.toString() ?? '') ??
        DateTime.tryParse(json['examination_date']?.toString() ?? '');

    final DateTime? examEndDate = DateTime.tryParse(dates['examination_end_date']?.toString() ?? '') ??
        DateTime.tryParse(dates['exam_end_date']?.toString() ?? '') ??
        DateTime.tryParse(json['exam_end_date']?.toString() ?? '');

    final DateTime? resultDate = DateTime.tryParse(dates['result_date']?.toString() ?? '') ??
        DateTime.tryParse(json['result_date']?.toString() ?? '');

    final DateTime? ageCutoffDate = DateTime.tryParse(rules['age_cutoff_date']?.toString() ?? '') ??
        DateTime.tryParse(json['age_cutoff_date']?.toString() ?? '');

    // Synchronize importantDates map with clean human labels
    Map<String, DateTime?> importantDatesMap = {};
    if (notificationDate != null) importantDatesMap['Notification Date'] = notificationDate;
    if (applicationStartDate != null) importantDatesMap['Application Start'] = applicationStartDate;
    if (applicationEndDate != null) importantDatesMap['Application Deadline'] = applicationEndDate;
    if (correctionStartDate != null) importantDatesMap['Correction Start'] = correctionStartDate;
    if (correctionEndDate != null) importantDatesMap['Correction Deadline'] = correctionEndDate;
    if (admitCardDate != null) importantDatesMap['Admit Card Release'] = admitCardDate;
    if (examStartDate != null) importantDatesMap['Examination Date'] = examStartDate;
    if (examEndDate != null) importantDatesMap['Examination Concludes'] = examEndDate;
    if (resultDate != null) importantDatesMap['Result Declaration'] = resultDate;
    if (ageCutoffDate != null) importantDatesMap['Age Cutoff Date'] = ageCutoffDate;

    final categoryStr = json['category']?.toString() ?? '';
    final oppTypeStr = json['opportunity_type']?.toString();

    return Examination(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      organisationId: json['organisation_id']?.toString() ?? '',
      sourceId: json['source_id']?.toString(),
      title: json['name']?.toString() ?? json['title']?.toString() ?? '',
      organisation: org['name']?.toString() ?? json['organisation_name']?.toString() ?? 'Official Authority',
      issuingAuthority: org['parent_ministry']?.toString() ?? 'Government of India',
      category: ExaminationCategory.fromString(categoryStr),
      status: ExaminationStatus.published,
      overview: json['overview']?.toString() ?? '',
      vacancies: json['vacancies'] != null
          ? int.tryParse(json['vacancies'].toString())
          : (json['vacancy_count'] != null ? int.tryParse(json['vacancy_count'].toString()) : null),
      eligibilityCriteriaSummary: rules['extracted_rule_text']?.toString() ?? 'Refer official notification.',
      minAge: rules['min_age'] != null
          ? int.tryParse(rules['min_age'].toString()) ?? 18
          : (json['minimum_age'] != null ? int.tryParse(json['minimum_age'].toString()) : 18),
      maxAge: rules['max_age'] != null
          ? int.tryParse(rules['max_age'].toString()) ?? 35
          : (json['maximum_age'] != null ? int.tryParse(json['maximum_age'].toString()) : 35),
      categoryAgeRelaxation: rules['category_age_relaxations'] is Map
          ? (rules['category_age_relaxations'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()))
          : {},
      educationalQualifications: (rules['educational_qualifications'] as List?)?.map((e) => e.toString()).toList() ??
          (json['educational_eligibility'] as List?)?.map((e) => e.toString()).toList() ??
          (json['qualification_levels'] as List?)?.map((e) => e.toString()).toList() ??
          ['Graduate degree in relevant stream'],
      eligibleStreams: (rules['eligible_branches'] as List?)?.map((e) => e.toString()).toList() ??
          (json['required_disciplines'] as List?)?.map((e) => e.toString()).toList() ??
          ['All Disciplines'],
      minPercentage: rules['min_percentage'] != null
          ? double.tryParse(rules['min_percentage'].toString())
          : (json['minimum_percentage'] != null ? double.tryParse(json['minimum_percentage'].toString()) : null),
      minCgpa: rules['min_cgpa'] != null
          ? double.tryParse(rules['min_cgpa'].toString())
          : (json['minimum_cgpa'] != null ? double.tryParse(json['minimum_cgpa'].toString()) : null),
      cgpaScaleMax: rules['cgpa_scale_max'] != null ? (double.tryParse(rules['cgpa_scale_max'].toString()) ?? 10.0) : 10.0,
      gradingType: rules['grading_type']?.toString() ??
          (rules['min_cgpa'] != null && rules['min_percentage'] == null ? 'cgpa' : 'percentage'),
      acceptedGradingSystems: (rules['accepted_grading_systems'] as List?)?.map((e) => e.toString()).toList() ??
          ['percentage', 'cgpa'],
      acceptsFinalYearStudents: rules['accepts_final_year_students'] == true,
      acceptsAppearingCandidates: rules['accepts_appearing_candidates'] == true,
      minAcademicYearRequired: rules['min_academic_year_required'] != null
          ? int.tryParse(rules['min_academic_year_required'].toString())
          : null,
      degreeCompletionCutoffDate: rules['degree_completion_cutoff_date'] != null
          ? DateTime.tryParse(rules['degree_completion_cutoff_date'].toString())
          : null,
      requiresConversionCertificate: rules['requires_conversion_certificate'] == true,
      institutionConversionRequirements: rules['institution_conversion_requirements']?.toString(),
      nationality: rules['nationality']?.toString() ?? 'Citizen of India',
      genderRequirements: rules['gender_requirements']?.toString() ?? 'All genders eligible',
      workExperience: rules['work_experience_requirement']?.toString() ?? 'None required',
      applicationFee: rules['fee_general'] != null
          ? num.tryParse(rules['fee_general'].toString())
          : (json['application_fee'] != null ? num.tryParse(json['application_fee'].toString()) : null),
      feeExemptions: rules['fee_exemptions']?.toString() ?? 'SC/ST/PwBD and Female candidates exempted',
      requiredDocuments: (rules['required_documents'] as List?)?.map((e) => e.toString()).toList() ??
          (json['required_documents'] as List?)?.map((e) => e.toString()).toList() ??
          ['Class 10 Certificate', 'Degree Marksheet', 'Category Certificate if claiming relaxation'],
      importantDates: importantDatesMap,
      notificationDate: notificationDate,
      applicationStartDate: applicationStartDate,
      applicationEndDate: applicationEndDate,
      correctionStartDate: correctionStartDate,
      correctionEndDate: correctionEndDate,
      admitCardDate: admitCardDate,
      examStartDate: examStartDate,
      examEndDate: examEndDate,
      resultDate: resultDate,
      ageCutoffDate: ageCutoffDate,
      selectionProcedure: json['selection_procedure']?.toString() ??
          json['selection_process']?.toString() ??
          'Written examination followed by interview.',
      examPattern: json['exam_pattern']?.toString(),
      salaryOrPayScale: json['salary_or_pay_scale']?.toString() ?? json['salary']?.toString(),
      stipend: json['stipend']?.toString(),
      location: json['location']?.toString() ?? 'All India',
      applicationInstructions: json['application_instructions']?.toString() ?? 'Apply online via the conducting authority portal.',
      officialNotificationPdfUrl: json['official_notification_url']?.toString() ?? json['notification_url']?.toString(),
      officialApplicationUrl: json['official_application_url']?.toString() ?? json['application_url']?.toString() ?? '',
      sourceUrl: json['source_url']?.toString() ?? '',
      lastVerifiedAt: DateTime.tryParse(json['last_verified_at']?.toString() ?? '') ?? DateTime.now(),
      isOfficialSource: json['is_official_source'] == true,
      applicationDeadline: applicationEndDate,
      isCentralGovernment: json['is_central_government'] != false,
      state: json['state']?.toString(),
      isConfirmed: json['is_confirmed'] != false,
      uncertainFields: (json['uncertain_fields'] as List?)?.map((e) => e.toString()).toList() ?? [],
      opportunityType: oppTypeStr,
      sector: json['sector']?.toString(),
      subSector: json['sub_sector']?.toString(),
      requisitionId: json['requisition_id']?.toString(),
      advertisementNumber: json['advertisement_number']?.toString(),
      verificationStatus: json['verification_status']?.toString() ?? 'verified',
      verificationTier: json['verification_tier']?.toString() ??
          (json['verification_status']?.toString().toUpperCase() == 'VERIFIED' ? 'VERIFIED' : 'PARTIALLY_VERIFIED'),
      isApplicationUrlVerified: json['is_application_url_verified'] == true,
      applicationUrlStatus: json['application_url_status']?.toString() ?? 'NEEDS_REVIEW',
      verifiedApplicationUrl: json['verified_application_url']?.toString(),
      verifiedNotificationUrl: json['verified_notification_url']?.toString(),
      applicationStatus: json['application_status']?.toString() ?? 'open',
      evidence: json['evidence'] is Map ? Map<String, dynamic>.from(json['evidence'] as Map) : {},
    );
  }
}
