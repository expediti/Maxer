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
  late bool? _isCentralGovt;
  late int? _maxAge;
  late num? _maxFee;
  late bool _closingSoonOnly;
  late OpportunitySortOption _sortOption;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.currentFilter.category;
    _isCentralGovt = widget.currentFilter.isCentralGovernment;
    _maxAge = widget.currentFilter.maxAge;
    _maxFee = widget.currentFilter.maxFee;
    _closingSoonOnly = widget.currentFilter.closingSoonOnly;
    _sortOption = widget.currentFilter.sortOption;
  }

  void _reset() {
    setState(() {
      _selectedCategory = null;
      _isCentralGovt = null;
      _maxAge = null;
      _maxFee = null;
      _closingSoonOnly = false;
      _sortOption = OpportunitySortOption.relevance;
    });
  }

  void _apply() {
    widget.onApply(
      widget.currentFilter.copyWith(
        category: _selectedCategory,
        clearCategory: _selectedCategory == null,
        isCentralGovernment: _isCentralGovt,
        clearGovtType: _isCentralGovt == null,
        maxAge: _maxAge,
        maxFee: _maxFee,
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
        color: AppColors.surface,
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
                  Text('Filters & Sorting', style: AppTypography.screenTitle),
                  TextButton(
                    onPressed: _reset,
                    child: Text('Reset All', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                  ),
                ],
              ),
              const Divider(color: AppColors.border),
              const SizedBox(height: AppDimensions.space12),

              // Sort By
              Text('SORT BY', style: AppTypography.label.copyWith(color: AppColors.textSubtle)),
              const SizedBox(height: AppDimensions.space8),
              Wrap(
                spacing: AppDimensions.space8,
                runSpacing: AppDimensions.space8,
                children: OpportunitySortOption.values.map((sort) {
                  final isSelected = _sortOption == sort;
                  return ChoiceChip(
                    label: Text(sort.label),
                    selected: isSelected,
                    selectedColor: AppColors.secondaryGreen,
                    backgroundColor: AppColors.secondaryBackground,
                    labelStyle: AppTypography.caption.copyWith(
                      color: isSelected ? AppColors.textMain : AppColors.textMuted,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDimensions.roundedSmall,
                      side: BorderSide(color: isSelected ? AppColors.primaryGreen : AppColors.border),
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _sortOption = sort);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimensions.space16),

              // Category Filter
              Text('OPPORTUNITY CATEGORY', style: AppTypography.label.copyWith(color: AppColors.textSubtle)),
              const SizedBox(height: AppDimensions.space8),
              Wrap(
                spacing: AppDimensions.space8,
                runSpacing: AppDimensions.space8,
                children: OpportunityCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return FilterChip(
                    label: Text(cat.label),
                    selected: isSelected,
                    selectedColor: AppColors.secondaryGreen,
                    backgroundColor: AppColors.secondaryBackground,
                    labelStyle: AppTypography.caption.copyWith(
                      color: isSelected ? AppColors.textMain : AppColors.textMuted,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDimensions.roundedSmall,
                      side: BorderSide(color: isSelected ? AppColors.primaryGreen : AppColors.border),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? cat : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimensions.space16),

              // Authority Type
              Text('SECTOR / GOVERNANCE', style: AppTypography.label.copyWith(color: AppColors.textSubtle)),
              const SizedBox(height: AppDimensions.space8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Sectors'),
                    selected: _isCentralGovt == null,
                    selectedColor: AppColors.secondaryGreen,
                    backgroundColor: AppColors.secondaryBackground,
                    labelStyle: AppTypography.caption.copyWith(
                      color: _isCentralGovt == null ? AppColors.textMain : AppColors.textMuted,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDimensions.roundedSmall,
                      side: BorderSide(color: _isCentralGovt == null ? AppColors.primaryGreen : AppColors.border),
                    ),
                    onSelected: (_) => setState(() => _isCentralGovt = null),
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  ChoiceChip(
                    label: const Text('Central Govt / PSU'),
                    selected: _isCentralGovt == true,
                    selectedColor: AppColors.secondaryGreen,
                    backgroundColor: AppColors.secondaryBackground,
                    labelStyle: AppTypography.caption.copyWith(
                      color: _isCentralGovt == true ? AppColors.textMain : AppColors.textMuted,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDimensions.roundedSmall,
                      side: BorderSide(color: _isCentralGovt == true ? AppColors.primaryGreen : AppColors.border),
                    ),
                    onSelected: (_) => setState(() => _isCentralGovt = true),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),

              // Closing Soon Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Closing Soon (Next 15 Days)', style: AppTypography.body),
                subtitle: Text('Show opportunities whose application window is concluding', style: AppTypography.caption),
                value: _closingSoonOnly,
                activeThumbColor: AppColors.primaryGreen,
                onChanged: (val) => setState(() => _closingSoonOnly = val),
              ),
              const SizedBox(height: AppDimensions.space20),

              // Apply Button
              ElevatedButton(
                onPressed: _apply,
                child: const Text('Apply Filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
