import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/opportunity.dart';
import '../../domain/opportunity_filter.dart';

class FilterSheet extends StatefulWidget {
  final OpportunityFilter currentFilter;
  final ValueChanged<OpportunityFilter> onApply;

  const FilterSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late OpportunityCategory? _selectedCategory;
  late String? _organisation;
  late bool? _isCentralGovt;
  late String? _qualification;
  late String? _educationLevel;
  late String? _applicationStatus;
  late String? _eligibilityStatusFilter;
  late bool _closingSoonOnly;
  late OpportunitySortOption _sortOption;

  final TextEditingController _orgController = TextEditingController();

  static const List<String> _commonOrgs = [
    'UPSC',
    'SSC',
    'IBPS',
    'RRB',
    'NTA',
    'AICTE',
    'ISRO',
    'DRDO',
    'State PSC',
  ];

  static const List<String> _eduLevels = [
    'Class 10',
    'Class 12',
    'Diploma',
    'Bachelor’s Degree',
    'B.Tech / B.E.',
    'Master’s Degree',
    'Doctorate',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.currentFilter.category;
    _organisation = widget.currentFilter.organisation;
    _orgController.text = _organisation ?? '';
    _isCentralGovt = widget.currentFilter.isCentralGovernment;
    _qualification = widget.currentFilter.qualification;
    _educationLevel = widget.currentFilter.educationLevel;
    _applicationStatus = widget.currentFilter.applicationStatus;
    _eligibilityStatusFilter = widget.currentFilter.eligibilityStatusFilter;
    _closingSoonOnly = widget.currentFilter.closingSoonOnly;
    _sortOption = widget.currentFilter.sortOption;
  }

  @override
  void dispose() {
    _orgController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _selectedCategory = null;
      _organisation = null;
      _orgController.clear();
      _isCentralGovt = null;
      _qualification = null;
      _educationLevel = null;
      _applicationStatus = null;
      _eligibilityStatusFilter = null;
      _closingSoonOnly = false;
      _sortOption = OpportunitySortOption.latest;
    });
  }

  void _apply() {
    final orgText = _orgController.text.trim();
    widget.onApply(
      widget.currentFilter.copyWith(
        category: _selectedCategory,
        clearCategory: _selectedCategory == null,
        organisation: orgText.isNotEmpty ? orgText : null,
        clearOrganisation: orgText.isEmpty,
        isCentralGovernment: _isCentralGovt,
        clearGovtType: _isCentralGovt == null,
        qualification: _qualification,
        clearQualification: _qualification == null,
        educationLevel: _educationLevel,
        clearEducationLevel: _educationLevel == null,
        applicationStatus: _applicationStatus,
        clearApplicationStatus: _applicationStatus == null,
        eligibilityStatusFilter: _eligibilityStatusFilter,
        clearEligibilityStatusFilter: _eligibilityStatusFilter == null,
        closingSoonOnly: _closingSoonOnly,
        sortOption: _sortOption,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLarge)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(AppDimensions.space20),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters & Sorting',
                    style: AppTypography.screenTitle.copyWith(color: AppColors.primaryText),
                  ),
                  TextButton(
                    onPressed: _reset,
                    child: const Text('Reset All', style: TextStyle(color: AppColors.secondaryText)),
                  ),
                ],
              ),
              const Divider(color: AppColors.divider),
              const SizedBox(height: AppDimensions.space12),

              // 1. Sort By
              Text('SORT ORDER', style: AppTypography.label.copyWith(color: AppColors.secondaryText)),
              const SizedBox(height: AppDimensions.space8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: OpportunitySortOption.values.map((sort) {
                  final isSelected = _sortOption == sort;
                  return ChoiceChip(
                    label: Text(sort.label),
                    selected: isSelected,
                    selectedColor: AppColors.white,
                    backgroundColor: AppColors.cardBackground,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.black : AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    side: BorderSide(color: isSelected ? AppColors.white : AppColors.border),
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) setState(() => _sortOption = sort);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimensions.space20),

              // 2. Eligibility Status Filter
              Text('ELIGIBILITY STATUS', style: AppTypography.label.copyWith(color: AppColors.secondaryText)),
              const SizedBox(height: AppDimensions.space8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildEligibilityChip('All Statuses', null),
                  _buildEligibilityChip('Eligible Only', 'eligible'),
                  _buildEligibilityChip('Requires Verification', 'needs_verification'),
                  _buildEligibilityChip('Ineligible Only', 'ineligible'),
                ],
              ),
              const SizedBox(height: AppDimensions.space20),

              // 3. Organisation Filter
              Text('ORGANISATION / RECRUITING BODY', style: AppTypography.label.copyWith(color: AppColors.secondaryText)),
              const SizedBox(height: AppDimensions.space8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonOrgs.map((org) {
                  final isSelected = _orgController.text.trim().toLowerCase() == org.toLowerCase();
                  return ChoiceChip(
                    label: Text(org),
                    selected: isSelected,
                    selectedColor: AppColors.white,
                    backgroundColor: AppColors.cardBackground,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.black : AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    side: BorderSide(color: isSelected ? AppColors.white : AppColors.border),
                    showCheckmark: false,
                    onSelected: (selected) {
                      setState(() {
                        _orgController.text = selected ? org : '';
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimensions.space20),

              // 4. Examination Category
              Text('EXAMINATION CATEGORY', style: AppTypography.label.copyWith(color: AppColors.secondaryText)),
              const SizedBox(height: AppDimensions.space8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExaminationCategory.values
                    .where((c) => c != ExaminationCategory.entranceExam && c != ExaminationCategory.internshipResearch)
                    .map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat.label),
                    selected: isSelected,
                    selectedColor: AppColors.white,
                    backgroundColor: AppColors.cardBackground,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.black : AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    side: BorderSide(color: isSelected ? AppColors.white : AppColors.border),
                    showCheckmark: false,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = selected ? cat : null);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimensions.space20),

              // 5. Education Level / Qualification
              Text('QUALIFICATION / EDUCATION LEVEL', style: AppTypography.label.copyWith(color: AppColors.secondaryText)),
              const SizedBox(height: AppDimensions.space8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _eduLevels.map((lvl) {
                  final isSelected = _educationLevel == lvl;
                  return ChoiceChip(
                    label: Text(lvl),
                    selected: isSelected,
                    selectedColor: AppColors.white,
                    backgroundColor: AppColors.cardBackground,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.black : AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    side: BorderSide(color: isSelected ? AppColors.white : AppColors.border),
                    showCheckmark: false,
                    onSelected: (selected) {
                      setState(() => _educationLevel = selected ? lvl : null);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimensions.space20),

              // 6. Application Status
              Text('APPLICATION STATUS', style: AppTypography.label.copyWith(color: AppColors.secondaryText)),
              const SizedBox(height: AppDimensions.space8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildAppStatusChip('All', null),
                  _buildAppStatusChip('Open Now', 'open'),
                  _buildAppStatusChip('Closing Soon (15d)', 'closing_soon'),
                  _buildAppStatusChip('Upcoming', 'upcoming'),
                  _buildAppStatusChip('Closed', 'closed'),
                ],
              ),
              const SizedBox(height: AppDimensions.space20),

              // 7. Jurisdiction
              Text('JURISDICTION', style: AppTypography.label.copyWith(color: AppColors.secondaryText)),
              const SizedBox(height: AppDimensions.space8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Central Govt / PSUs'),
                    selected: _isCentralGovt == true,
                    selectedColor: AppColors.white,
                    backgroundColor: AppColors.cardBackground,
                    labelStyle: TextStyle(
                      color: _isCentralGovt == true ? AppColors.black : AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    side: BorderSide(color: _isCentralGovt == true ? AppColors.white : AppColors.border),
                    showCheckmark: false,
                    onSelected: (selected) {
                      setState(() => _isCentralGovt = selected ? true : null);
                    },
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  ChoiceChip(
                    label: const Text('State Services'),
                    selected: _isCentralGovt == false,
                    selectedColor: AppColors.white,
                    backgroundColor: AppColors.cardBackground,
                    labelStyle: TextStyle(
                      color: _isCentralGovt == false ? AppColors.black : AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    side: BorderSide(color: _isCentralGovt == false ? AppColors.white : AppColors.border),
                    showCheckmark: false,
                    onSelected: (selected) {
                      setState(() => _isCentralGovt = selected ? false : null);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space20),

              // 8. Toggles
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Application Deadline <= 15 Days',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryText, fontSize: 13.5)),
                value: _closingSoonOnly,
                activeTrackColor: AppColors.white,
                activeThumbColor: AppColors.black,
                onChanged: (val) => setState(() => _closingSoonOnly = val),
              ),

              const SizedBox(height: AppDimensions.space24),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEligibilityChip(String label, String? value) {
    final isSelected = _eligibilityStatusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.white,
      backgroundColor: AppColors.cardBackground,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.black : AppColors.secondaryText,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      side: BorderSide(color: isSelected ? AppColors.white : AppColors.border),
      showCheckmark: false,
      onSelected: (selected) {
        setState(() => _eligibilityStatusFilter = selected ? value : null);
      },
    );
  }

  Widget _buildAppStatusChip(String label, String? value) {
    final isSelected = _applicationStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.white,
      backgroundColor: AppColors.cardBackground,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.black : AppColors.secondaryText,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      side: BorderSide(color: isSelected ? AppColors.white : AppColors.border),
      showCheckmark: false,
      onSelected: (selected) {
        setState(() => _applicationStatus = selected ? value : null);
      },
    );
  }
}
