import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/opportunity_filter.dart';
import 'providers/opportunities_provider.dart';
import 'widgets/opportunity_card.dart';
import 'widgets/filter_sheet.dart';

class ExplorerScreen extends ConsumerStatefulWidget {
  const ExplorerScreen({super.key});

  @override
  ConsumerState<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends ConsumerState<ExplorerScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final filter = ref.read(opportunityFilterProvider);
    _searchController.text = filter.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    final current = ref.read(opportunityFilterProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FilterSheet(
        currentFilter: current,
        onApply: (updated) {
          ref.read(opportunityFilterProvider.notifier).state = updated;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(opportunityFilterProvider);
    final opportunitiesAsync = ref.watch(filteredOpportunitiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Opportunity Explorer'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.tune, size: 20),
                if (filter.hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter trigger
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space8,
              ),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (val) {
                  ref.read(opportunityFilterProvider.notifier).state =
                      filter.copyWith(searchQuery: val);
                },
                decoration: InputDecoration(
                  hintText: 'Filter by title, organisation, or stream...',
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(opportunityFilterProvider.notifier).state =
                                filter.copyWith(searchQuery: '');
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Horizontal Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: AppDimensions.space4),
              child: Row(
                children: [
                  // Filter trigger chip
                  ActionChip(
                    avatar: const Icon(Icons.filter_list, size: 14, color: AppColors.primaryGreen),
                    label: Text(
                      filter.hasActiveFilters ? 'Filters (Active)' : 'All Filters',
                      style: AppTypography.caption.copyWith(color: AppColors.textMain),
                    ),
                    backgroundColor: filter.hasActiveFilters ? AppColors.secondaryGreen : AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: AppDimensions.roundedSmall),
                    onPressed: _openFilterSheet,
                  ),
                  const SizedBox(width: AppDimensions.space8),

                  // Quick toggle: Closing Soon
                  FilterChip(
                    label: const Text('Closing Soon'),
                    selected: filter.closingSoonOnly,
                    selectedColor: AppColors.secondaryGreen,
                    backgroundColor: AppColors.surface,
                    labelStyle: AppTypography.caption.copyWith(
                      color: filter.closingSoonOnly ? AppColors.textMain : AppColors.textMuted,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDimensions.roundedSmall,
                      side: BorderSide(color: filter.closingSoonOnly ? AppColors.primaryGreen : AppColors.border),
                    ),
                    onSelected: (val) {
                      ref.read(opportunityFilterProvider.notifier).state =
                          filter.copyWith(closingSoonOnly: val);
                    },
                  ),
                  const SizedBox(width: AppDimensions.space8),

                  // Quick toggle: Central Govt
                  FilterChip(
                    label: const Text('Central Govt / PSU'),
                    selected: filter.isCentralGovernment == true,
                    selectedColor: AppColors.secondaryGreen,
                    backgroundColor: AppColors.surface,
                    labelStyle: AppTypography.caption.copyWith(
                      color: filter.isCentralGovernment == true ? AppColors.textMain : AppColors.textMuted,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDimensions.roundedSmall,
                      side: BorderSide(color: filter.isCentralGovernment == true ? AppColors.primaryGreen : AppColors.border),
                    ),
                    onSelected: (val) {
                      ref.read(opportunityFilterProvider.notifier).state = filter.copyWith(
                        isCentralGovernment: val ? true : null,
                        clearGovtType: !val,
                      );
                    },
                  ),

                  // Active Category chip if set
                  if (filter.category != null) ...[
                    const SizedBox(width: AppDimensions.space8),
                    Chip(
                      label: Text(filter.category!.label),
                      backgroundColor: AppColors.secondaryGreen,
                      side: const BorderSide(color: AppColors.primaryGreen),
                      shape: RoundedRectangleBorder(borderRadius: AppDimensions.roundedSmall),
                      labelStyle: AppTypography.caption.copyWith(color: AppColors.textMain),
                      onDeleted: () {
                        ref.read(opportunityFilterProvider.notifier).state =
                            filter.copyWith(clearCategory: true);
                      },
                    ),
                  ],
                ],
              ),
            ),
            const Divider(color: AppColors.border),

            // Results count and active sorting display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: AppDimensions.space8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  opportunitiesAsync.when(
                    data: (items) => Text(
                      '${items.length} verified opportunities found',
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    ),
                    loading: () => Text('Searching catalog...', style: AppTypography.caption),
                    error: (_, __) => Text('Search error', style: AppTypography.caption),
                  ),
                  Text(
                    'Sorted by: ${filter.sortOption.label}',
                    style: AppTypography.caption.copyWith(color: AppColors.textSubtle, fontSize: 11),
                  ),
                ],
              ),
            ),

            // Main Opportunity List
            Expanded(
              child: opportunitiesAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_outlined, size: 40, color: AppColors.textMuted),
                          const SizedBox(height: AppDimensions.space12),
                          Text('No opportunities match your filter', style: AppTypography.sectionHeader),
                          const SizedBox(height: AppDimensions.space4),
                          Text('Try broadening your criteria or reset filters.', style: AppTypography.bodyMuted),
                          const SizedBox(height: AppDimensions.space16),
                          OutlinedButton(
                            onPressed: () {
                              ref.read(opportunityFilterProvider.notifier).state = const OpportunityFilter();
                              _searchController.clear();
                            },
                            child: const Text('Reset All Filters'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final opp = items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppDimensions.space12),
                        child: OpportunityCard(
                          opportunity: opp,
                          onTap: () => context.go('/opportunities/${opp.id}'),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryGreen),
                ),
                error: (err, _) => Center(
                  child: Text('Error loading opportunities: $err', style: AppTypography.body),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
