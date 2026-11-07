import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexam/core/constants/app_colors.dart';
import 'package:rexam/core/constants/app_dimensions.dart';
import 'package:rexam/core/theme/app_typography.dart';
import 'package:rexam/features/saved/presentation/providers/saved_provider.dart';
import 'package:rexam/features/opportunities/presentation/widgets/opportunity_card.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  String _searchQuery = '';
  bool _sortByDeadline = true;

  @override
  Widget build(BuildContext context) {
    final savedItems = ref.watch(savedProvider);

    final filtered = savedItems.where((opp) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return opp.title.toLowerCase().contains(q) ||
          opp.organisation.toLowerCase().contains(q);
    }).toList();

    if (_sortByDeadline) {
      filtered.sort((a, b) => a.applicationDeadline.compareTo(b.applicationDeadline));
    } else {
      filtered.sort((a, b) => b.lastVerifiedAt.compareTo(a.lastVerifiedAt));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Opportunities'),
        actions: [
          IconButton(
            icon: Icon(_sortByDeadline ? Icons.schedule : Icons.calendar_today, size: 20),
            tooltip: _sortByDeadline ? 'Sorted by Deadline' : 'Sorted by Latest',
            onPressed: () {
              setState(() => _sortByDeadline = !_sortByDeadline);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search in Saved
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space8,
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Search within bookmarked opportunities...',
                  prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted),
                ),
              ),
            ),

            // Status Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: AppDimensions.space4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filtered.length} saved bookmarks',
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  ),
                  Text(
                    _sortByDeadline ? 'Order: Closing Soonest' : 'Order: Recently Verified',
                    style: AppTypography.caption.copyWith(color: AppColors.textSubtle, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border),

            // Content
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bookmark_border, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: AppDimensions.space16),
                          Text('No saved opportunities yet', style: AppTypography.sectionHeader),
                          const SizedBox(height: AppDimensions.space4),
                          Text(
                            'Bookmark notifications from Discover to track their deadlines here.',
                            style: AppTypography.bodyMuted,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppDimensions.space16),
                          ElevatedButton(
                            onPressed: () => context.go('/discover'),
                            child: const Text('Explore Opportunities'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final opp = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppDimensions.space12),
                          child: OpportunityCard(
                            opportunity: opp,
                            onTap: () => context.go('/opportunities/${opp.id}'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
