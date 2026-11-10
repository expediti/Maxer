import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/opportunity.dart';
import '../../domain/opportunity_filter.dart';
import '../providers/opportunities_provider.dart';

class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late OpportunitySortOption _sortOption;
  late TextEditingController _orgController;
  ExaminationCategory? _selectedCategory;
  String? _state;
  bool? _isCentralGovt;
  bool _closingSoonOnly = false;
  String? _educationLevel;
  String? _eligibilityStatusFilter;
  String? _applicationStatus;

  final List<String> _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
    'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
    'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab',
    'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
    'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Delhi (NCT)', 'Jammu and Kashmir', 'Ladakh', 'Chandigarh',
    'Puducherry', 'Andaman and Nicobar', 'Dadra and Nagar Haveli', 'Lakshadweep'
  ];

  final List<String> _commonOrgs = [
    'UPSC', 'SSC', 'IBPS', 'State PSC', 'DRDO', 'ISRO',
    'Railway Recruitment Control Board', 'Power Grid', 'IOCL', 'ONGC',
    'Scholarship', 'NTA', 'AICTE', 'CSIR'
  ];

  final List<String> _eduLevels = [
    '10th Pass (Matriculation)',
    '12th Pass (Higher Secondary)',
    'ITI / Trade Apprenticeship',
    'Diploma / Polytechnic',
    'Bachelor\'s Degree (UG)',
    'Master\'s Degree (PG)',
    'PhD / Doctorate / Post-Doc',
  ];

  @override
  void initState() {
    super.initState();
    final current = ref.read(opportunityFilterProvider);
    _sortOption = current.sortOption;
    _orgController = TextEditingController(text: current.organisation ?? '');
    _selectedCategory = current.category;
    _state = current.state;
    _isCentralGovt = current.isCentralGovernment;
    _closingSoonOnly = current.closingSoonOnly;
    _educationLevel = current.educationLevel;
    _eligibilityStatusFilter = current.eligibilityStatusFilter;
    _applicationStatus = current.applicationStatus;
  }

  @override
  void dispose() {
    _orgController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _sortOption = OpportunitySortOption.closingDateAsc;
      _orgController.clear();
      _selectedCategory = null;
      _state = null;
      _isCentralGovt = null;
      _closingSoonOnly = false;
      _educationLevel = null;
      _eligibilityStatusFilter = null;
      _applicationStatus = null;
    });
    ref.read(opportunityFilterProvider.notifier).state = const OpportunityFilter();
  }

  void _apply() {
    ref.read(opportunityFilterProvider.notifier).state = ref.read(opportunityFilterProvider).copyWith(
          sortOption: _sortOption,
          organisation: _orgController.text.trim().isEmpty ? null : _orgController.text.trim(),
          category: _selectedCategory,
          clearCategory: _selectedCategory == null,
          clearOrganisation: _orgController.text.trim().isEmpty,
          state: _state,
          clearState: _state == null,
          isCentralGovernment: _isCentralGovt,
          clearJurisdiction: _isCentralGovt == null,
          closingSoonOnly: _closingSoonOnly,
          educationLevel: _educationLevel,
          clearEducationLevel: _educationLevel == null,
          eligibilityStatusFilter: _eligibilityStatusFilter,
          clearEligibilityStatus: _eligibilityStatusFilter == null,
          applicationStatus: _applicationStatus,
          clearApplicationStatus: _applicationStatus == null,
        );
    Navigator.of(context).pop();
  }

  Widget _buildThemedChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: context.isDarkMode ? AppColors.white : AppColors.black,
      backgroundColor: context.themeCard,
      labelStyle: TextStyle(
        color: isSelected
            ? (context.isDarkMode ? AppColors.black : AppColors.white)
            : context.themeTextMuted,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected
            ? (context.isDarkMode ? AppColors.white : AppColors.black)
            : context.themeBorder,
      ),
      showCheckmark: false,
      onSelected: onSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeSurfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLarge)),
        border: Border(top: BorderSide(color: context.themeBorder)),
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
                    style: AppTypography.screenTitle.copyWith(color: context.themeTextMain),
                  ),
                  TextButton(
                    onPressed: _reset,
                    child: Text('Reset All', style: TextStyle(color: context.themeTextMuted)),
                  ),
                ],
              ),
              Divider(color: context.themeBorder),
              const SizedBox(height: AppDimensions.space12),

              // 1. Sort By
              Text('SORT ORDER', style: AppTypography.label.copyWith(color: context.themeTextMuted)),
              const SizedBox(height: AppDimensions.space8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: OpportunitySortOption.values.map((sort) {
                  return _buildThemedChip(
                    context: context,
                    label: sort.label,
                    isSelected: _sortOption == sort,
                    onSelected: (selected) {
                      if (selected) setState(() => _sortOption = sort);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimensions.space20),

              // 2. Eligibility Status Filter
              Text('ELIGIBILITY STATUS', style: AppTypography.label.copyWith(color: context.themeTextMuted)),
              const SizedBox(height: AppDimensions.space8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildThemedChip(
                    context: context,
                    label: 'All Statuses',
                    isSelected: _eligibilityStatusFilter == null,
                    onSelected: (selected) => setState(() => _eligibilityStatusFilter = null),
                  ),
                  _buildThemedChip(
                    context: context,
                    label: 'Eligible Only',
                    isSelected: _eligibilityStatusFilter == 'eligible',
                    onSelected: (selected) => setState(() => _eligibilityStatusFilter = selected ? 'eligible' : null),
                  ),
                  _buildThemedChip(
                    context: context,
                    label: 'Requires Verification',
                    isSelected: _eligibilityStatusFilter == 'needs_verification',
                    onSelected: (selected) => setState(() => _eligibilityStatusFilter = selected ? 'needs_verification' : null),
                  ),
                  _buildThemedChip(
                    context: context,
                    label: 'Ineligible Only',
                    isSelected: _eligibilityStatusFilter == 'ineligible',
                    onSelected: (selected) => setState(() => _eligibilityStatusFilter = selected ? 'ineligible' : null),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space20),

              // 3. Organisation Filter
              Text('ORGANISATION / RECRUITING BODY', style: AppTypography.label.copyWith(color: context.themeTextMuted)),
              const SizedBox(height: AppDimensions.space8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonOrgs.map((org) {
                  final isSelected = _orgController.text.trim().toLowerCase() == org.toLowerCase();
                  return _buildThemedChip(
                    context: context,
                    label: org,
                    isSelected: isSelected,
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
              Text('EXAMINATION CATEGORY', style: AppTypography.label.copyWith(color: context.themeTextMuted)),
              const SizedBox(height: AppDimensions.space8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExaminationCategory.values
                    .where((c) => c != ExaminationCategory.entranceExam && c != ExaminationCategory.internshipResearch)
                    .map((cat) {
                  return _buildThemedChip(
                    context: context,
                    label: cat.label,
                    isSelected: _selectedCategory == cat,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = selected ? cat : null);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimensions.space20),

              // 5. Education Level / Qualification
              Text('QUALIFICATION / EDUCATION LEVEL', style: AppTypography.label.copyWith(color: context.themeTextMuted)),
              const SizedBox(height: AppDimensions.space8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _eduLevels.map((lvl) {
                  return _buildThemedChip(
                    context: context,
                    label: lvl,
                    isSelected: _educationLevel == lvl,
                    onSelected: (selected) {
                      setState(() => _educationLevel = selected ? lvl : null);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimensions.space20),

              // 6. Application Status
              Text('APPLICATION STATUS', style: AppTypography.label.copyWith(color: context.themeTextMuted)),
              const SizedBox(height: AppDimensions.space8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildThemedChip(context: context, label: 'All', isSelected: _applicationStatus == null, onSelected: (_) => setState(() => _applicationStatus = null)),
                  _buildThemedChip(context: context, label: 'Open Now', isSelected: _applicationStatus == 'open', onSelected: (sel) => setState(() => _applicationStatus = sel ? 'open' : null)),
                  _buildThemedChip(context: context, label: 'Upcoming', isSelected: _applicationStatus == 'upcoming', onSelected: (sel) => setState(() => _applicationStatus = sel ? 'upcoming' : null)),
                  _buildThemedChip(context: context, label: 'Notification Released', isSelected: _applicationStatus == 'notification_released', onSelected: (sel) => setState(() => _applicationStatus = sel ? 'notification_released' : null)),
                  _buildThemedChip(context: context, label: 'Awaiting Notification', isSelected: _applicationStatus == 'awaiting_notification', onSelected: (sel) => setState(() => _applicationStatus = sel ? 'awaiting_notification' : null)),
                  _buildThemedChip(context: context, label: 'Closing Soon (15d)', isSelected: _applicationStatus == 'closing_soon', onSelected: (sel) => setState(() => _applicationStatus = sel ? 'closing_soon' : null)),
                  _buildThemedChip(context: context, label: 'Closed', isSelected: _applicationStatus == 'closed', onSelected: (sel) => setState(() => _applicationStatus = sel ? 'closed' : null)),
                ],
              ),
              const SizedBox(height: AppDimensions.space20),

              // 7. State / Union Territory Filter
              Text('STATE / UNION TERRITORY', style: AppTypography.label.copyWith(color: context.themeTextMuted)),
              const SizedBox(height: AppDimensions.space8),
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: context.themeCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  border: Border.all(color: context.themeBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _state,
                    isExpanded: true,
                    dropdownColor: context.themeSurfaceElevated,
                    hint: Text('All States & UTs (National)', style: TextStyle(color: context.themeTextMuted, fontSize: 13)),
                    icon: Icon(Icons.arrow_drop_down, color: context.themeTextMuted),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All States & UTs (National)', style: TextStyle(color: context.themeTextMain, fontSize: 13)),
                      ),
                      ..._indianStates.map((st) => DropdownMenuItem<String?>(
                        value: st,
                        child: Text(st, style: TextStyle(color: context.themeTextMain, fontSize: 13)),
                      )),
                    ],
                    onChanged: (val) {
                      setState(() => _state = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space20),

              // 8. Jurisdiction
              Text('JURISDICTION', style: AppTypography.label.copyWith(color: context.themeTextMuted)),
              const SizedBox(height: AppDimensions.space8),
              Row(
                children: [
                  _buildThemedChip(
                    context: context,
                    label: 'Central Govt / PSUs',
                    isSelected: _isCentralGovt == true,
                    onSelected: (selected) => setState(() => _isCentralGovt = selected ? true : null),
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  _buildThemedChip(
                    context: context,
                    label: 'State Services',
                    isSelected: _isCentralGovt == false,
                    onSelected: (selected) => setState(() => _isCentralGovt = selected ? false : null),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space20),

              // 9. Toggles
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Application Deadline <= 15 Days',
                    style: TextStyle(fontWeight: FontWeight.w600, color: context.themeTextMain, fontSize: 13.5)),
                value: _closingSoonOnly,
                activeTrackColor: context.isDarkMode ? AppColors.white : AppColors.black,
                activeThumbColor: context.isDarkMode ? AppColors.black : AppColors.white,
                onChanged: (val) => setState(() => _closingSoonOnly = val),
              ),

              const SizedBox(height: AppDimensions.space24),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.isDarkMode ? AppColors.white : AppColors.black,
                    foregroundColor: context.isDarkMode ? AppColors.black : AppColors.white,
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
}
