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
      _sortOption = OpportunitySortOption.latest;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLarge)),
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
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
                    child: const Text('Reset All'),
                  ),
                ],
              ),
              Divider(color: theme.colorScheme.outline),
              const SizedBox(height: AppDimensions.space12),

              // Sort By
              Text('SORT ORDER', style: AppTypography.label.copyWith(color: AppColors.primaryBlue)),
              const SizedBox(height: AppDimensions.space8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: OpportunitySortOption.values.map((sort) {
                  final isSelected = _sortOption == sort;
                  return ChoiceChip(
                    label: Text(sort.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _sortOption = sort);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimensions.space20),

              // Category Filter
              Text('EXAMINATION CATEGORY', style: AppTypography.label.copyWith(color: AppColors.primaryBlue)),
              const SizedBox(height: AppDimensions.space8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExaminationCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = selected ? cat : null);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimensions.space20),

              // Governing Body Type
              Text('JURISDICTION', style: AppTypography.label.copyWith(color: AppColors.primaryBlue)),
              const SizedBox(height: AppDimensions.space8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Central Govt / PSUs'),
                    selected: _isCentralGovt == true,
                    onSelected: (selected) {
                      setState(() => _isCentralGovt = selected ? true : null);
                    },
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  ChoiceChip(
                    label: const Text('State Services'),
                    selected: _isCentralGovt == false,
                    onSelected: (selected) {
                      setState(() => _isCentralGovt = selected ? false : null);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space20),

              // Toggles
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Closing Soon (Next 15 Days)', style: TextStyle(fontWeight: FontWeight.w600)),
                value: _closingSoonOnly,
                activeTrackColor: AppColors.primaryBlue,
                activeThumbColor: Colors.white,
                onChanged: (val) => setState(() => _closingSoonOnly = val),
              ),

              const SizedBox(height: AppDimensions.space24),

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
