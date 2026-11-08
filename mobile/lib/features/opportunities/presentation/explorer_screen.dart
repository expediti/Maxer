import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/empty_state.dart';
import '../domain/opportunity.dart';
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
    final theme = Theme.of(context);
    final filter = ref.watch(opportunityFilterProvider);
    final opportunitiesAsync = ref.watch(filteredOpportunitiesProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Explore Examinations'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.tune_rounded, size: 22),
                if (filter.hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filter & Sort',
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input with Clear Button
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
                  hintText: 'Search title, recruiting body, or branch...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
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

            // Category Filter Pills (Horizontal Scroll)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space4,
              ),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Categories'),
                    selected: filter.category == null,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(opportunityFilterProvider.notifier).state =
                            filter.copyWith(clearCategory: true);
                      }
                    },
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  ...ExaminationCategory.values.map((cat) {
                    final isSelected = filter.category == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppDimensions.space8),
                      child: ChoiceChip(
                        label: Text(cat.label),
                        selected: isSelected,
                        onSelected: (selected) {
                          ref.read(opportunityFilterProvider.notifier).state = filter.copyWith(
                            category: selected ? cat : null,
                            clearCategory: !selected,
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space8),

            // Main Content Area
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryBlue,
                onRefresh: () async {
                  ref.invalidate(filteredOpportunitiesProvider);
                },
                child: opportunitiesAsync.when(
                  data: (opportunities) {
                    if (opportunities.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 60),
                          EmptyStateView(
                            icon: Icons.search_off_rounded,
                            title: 'No Opportunities Found',
                            description: filter.hasActiveFilters || filter.searchQuery.isNotEmpty
                                ? 'No examinations match your current search and filter criteria. Try resetting filters.'
                                : 'No published examination notices available at this time.',
                            actionLabel: filter.hasActiveFilters || filter.searchQuery.isNotEmpty
                                ? 'Reset Filters'
                                : null,
                            onAction: () {
                              _searchController.clear();
                              ref.read(opportunityFilterProvider.notifier).state =
                                  const OpportunityFilter();
                            },
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space16,
                        vertical: AppDimensions.space8,
                      ),
                      itemCount: opportunities.length,
                      itemBuilder: (context, index) {
                        final opp = opportunities[index];
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
                    child: CircularProgressIndicator(color: AppColors.primaryBlue),
                  ),
                  error: (error, stack) => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 60),
                      EmptyStateView(
                        icon: Icons.cloud_off_rounded,
                        title: 'Unable to Load Opportunities',
                        description: '$error',
                        actionLabel: 'Retry',
                        onAction: () => ref.invalidate(filteredOpportunitiesProvider),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
