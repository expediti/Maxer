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
  final bool? isCentralGovernment;
  final String? state;
  final String? qualification;
  final String? stream;
  final int? maxAge;
  final num? maxFee;
  final bool closingSoonOnly;
  final bool eligibleOnly;
  final OpportunitySortOption sortOption;

  const OpportunityFilter({
    this.searchQuery = '',
    this.category,
    this.isCentralGovernment,
    this.state,
    this.qualification,
    this.stream,
    this.maxAge,
    this.maxFee,
    this.closingSoonOnly = false,
    this.eligibleOnly = false,
    this.sortOption = OpportunitySortOption.latest,
  });

  OpportunityFilter copyWith({
    String? searchQuery,
    OpportunityCategory? category,
    bool? isCentralGovernment,
    String? state,
    String? qualification,
    String? stream,
    int? maxAge,
    num? maxFee,
    bool? closingSoonOnly,
    bool? eligibleOnly,
    OpportunitySortOption? sortOption,
    bool clearCategory = false,
    bool clearGovtType = false,
    bool clearState = false,
    bool clearQualification = false,
    bool clearStream = false,
  }) {
    return OpportunityFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      category: clearCategory ? null : (category ?? this.category),
      isCentralGovernment: clearGovtType ? null : (isCentralGovernment ?? this.isCentralGovernment),
      state: clearState ? null : (state ?? this.state),
      qualification: clearQualification ? null : (qualification ?? this.qualification),
      stream: clearStream ? null : (stream ?? this.stream),
      maxAge: maxAge ?? this.maxAge,
      maxFee: maxFee ?? this.maxFee,
      closingSoonOnly: closingSoonOnly ?? this.closingSoonOnly,
      eligibleOnly: eligibleOnly ?? this.eligibleOnly,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  bool get hasActiveFilters =>
      category != null ||
      isCentralGovernment != null ||
      state != null ||
      qualification != null ||
      stream != null ||
      maxAge != null ||
      maxFee != null ||
      closingSoonOnly ||
      eligibleOnly;
}
