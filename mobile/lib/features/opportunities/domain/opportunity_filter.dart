import 'opportunity.dart';

enum OpportunitySortOption {
  latest('Latest Published'),
  deadline('Closing Soonest'),
  recentlyUpdated('Recently Updated'),
  alphabetical('Alphabetical (A-Z)'),
  relevance('Relevance'),
  feeLowToHigh('Fee: Low to High');

  final String label;
  const OpportunitySortOption(this.label);
}

class OpportunityFilter {
  final String searchQuery;
  final OpportunityCategory? category;
  final String? organisation;
  final bool? isCentralGovernment;
  final String? state;
  final String? qualification;
  final String? educationLevel;
  final String? stream;
  final int? maxAge;
  final num? maxFee;
  final bool closingSoonOnly;
  final bool eligibleOnly;
  final String? applicationStatus; // 'all' | 'open' | 'closing_soon' | 'upcoming' | 'closed'
  final String? eligibilityStatusFilter; // 'all' | 'eligible' | 'ineligible' | 'needs_verification'
  final OpportunitySortOption sortOption;

  const OpportunityFilter({
    this.searchQuery = '',
    this.category,
    this.organisation,
    this.isCentralGovernment,
    this.state,
    this.qualification,
    this.educationLevel,
    this.stream,
    this.maxAge,
    this.maxFee,
    this.closingSoonOnly = false,
    this.eligibleOnly = false,
    this.applicationStatus,
    this.eligibilityStatusFilter,
    this.sortOption = OpportunitySortOption.latest,
  });

  OpportunityFilter copyWith({
    String? searchQuery,
    OpportunityCategory? category,
    String? organisation,
    bool? isCentralGovernment,
    String? state,
    String? qualification,
    String? educationLevel,
    String? stream,
    int? maxAge,
    num? maxFee,
    bool? closingSoonOnly,
    bool? eligibleOnly,
    String? applicationStatus,
    String? eligibilityStatusFilter,
    OpportunitySortOption? sortOption,
    bool clearCategory = false,
    bool clearOrganisation = false,
    bool clearGovtType = false,
    bool clearState = false,
    bool clearQualification = false,
    bool clearEducationLevel = false,
    bool clearStream = false,
    bool clearApplicationStatus = false,
    bool clearEligibilityStatusFilter = false,
  }) {
    return OpportunityFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      category: clearCategory ? null : (category ?? this.category),
      organisation: clearOrganisation ? null : (organisation ?? this.organisation),
      isCentralGovernment: clearGovtType ? null : (isCentralGovernment ?? this.isCentralGovernment),
      state: clearState ? null : (state ?? this.state),
      qualification: clearQualification ? null : (qualification ?? this.qualification),
      educationLevel: clearEducationLevel ? null : (educationLevel ?? this.educationLevel),
      stream: clearStream ? null : (stream ?? this.stream),
      maxAge: maxAge ?? this.maxAge,
      maxFee: maxFee ?? this.maxFee,
      closingSoonOnly: closingSoonOnly ?? this.closingSoonOnly,
      eligibleOnly: eligibleOnly ?? this.eligibleOnly,
      applicationStatus: clearApplicationStatus ? null : (applicationStatus ?? this.applicationStatus),
      eligibilityStatusFilter: clearEligibilityStatusFilter ? null : (eligibilityStatusFilter ?? this.eligibilityStatusFilter),
      sortOption: sortOption ?? this.sortOption,
    );
  }

  bool get hasActiveFilters =>
      category != null ||
      (organisation != null && organisation!.isNotEmpty) ||
      isCentralGovernment != null ||
      (state != null && state!.isNotEmpty) ||
      (qualification != null && qualification!.isNotEmpty) ||
      (educationLevel != null && educationLevel!.isNotEmpty) ||
      (stream != null && stream!.isNotEmpty) ||
      maxAge != null ||
      maxFee != null ||
      closingSoonOnly ||
      eligibleOnly ||
      (applicationStatus != null && applicationStatus != 'all') ||
      (eligibilityStatusFilter != null && eligibilityStatusFilter != 'all');
}
