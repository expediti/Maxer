import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state.dart';
import '../presentation/providers/saved_provider.dart';
import '../../opportunities/presentation/widgets/opportunity_card.dart';

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
    final theme = Theme.of(context);
    final savedItems = ref.watch(savedProvider);

    final filtered = savedItems.where((opp) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return opp.title.toLowerCase().contains(q) ||
          opp.organisation.toLowerCase().contains(q);
    }).toList();

    if (_sortByDeadline) {
      filtered.sort((a, b) {
        if (a.applicationDeadline == null) return 1;
        if (b.applicationDeadline == null) return -1;
        return a.applicationDeadline!.compareTo(b.applicationDeadline!);
      });
    } else {
      filtered.sort((a, b) {
        final aTime = a.lastVerifiedAt ?? DateTime(2026);
        final bTime = b.lastVerifiedAt ?? DateTime(2026);
        return bTime.compareTo(aTime);
      });
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Saved Examinations'),
        actions: [
          IconButton(
            icon: Icon(_sortByDeadline ? Icons.schedule_rounded : Icons.calendar_today_rounded, size: 20),
            tooltip: _sortByDeadline ? 'Sorted by Closing Deadline' : 'Sorted by Announcement Date',
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
                  prefixIcon: Icon(Icons.search, size: 20),
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
                    '${filtered.length} Saved Opportunities',
                    style: AppTypography.caption,
                  ),
                  Text(
                    _sortByDeadline ? 'Closing Soonest' : 'Recently Announced',
                    style: AppTypography.caption.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Divider(color: theme.colorScheme.outline),

            // Content
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryBlue,
                onRefresh: () async {
                  await ref.read(savedProvider.notifier).loadSaved();
                },
                child: filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          EmptyStateView(
                            icon: Icons.bookmark_border_rounded,
                            title: 'No Saved Examinations',
                            description: _searchQuery.isNotEmpty
                                ? 'No saved items match "$_searchQuery".'
                                : 'Bookmark examinations you want to track to receive notifications and deadline alerts.',
                            actionLabel: 'Explore Opportunities',
                            onAction: () => context.go('/explorer'),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space16,
                          vertical: AppDimensions.space8,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final opp = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppDimensions.space12),
                            child: Dismissible(
                              key: Key(opp.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: AppDimensions.roundedDefault,
                                ),
                                child: const Icon(Icons.delete_outline, color: Colors.white),
                              ),
                              onDismissed: (_) {
                                ref.read(savedProvider.notifier).remove(opp.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Removed "${opp.title}" from saved.'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () => ref.read(savedProvider.notifier).toggleSave(opp),
                                    ),
                                  ),
                                );
                              },
                              child: OpportunityCard(
                                opportunity: opp,
                                onTap: () => context.go('/opportunities/${opp.id}'),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
