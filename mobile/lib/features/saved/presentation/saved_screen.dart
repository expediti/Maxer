import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        backgroundColor: context.themeBackground,
        elevation: 0,
        title: Text(
          'Saved Examinations',
          style: AppTypography.screenTitle.copyWith(fontSize: 18, color: context.themeTextMain),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _sortByDeadline ? LucideIcons.clock : LucideIcons.calendar,
              size: 18,
              color: AppColors.primaryGreen,
            ),
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
                style: TextStyle(color: context.themeTextMain, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search within bookmarked opportunities...',
                  prefixIcon: Icon(LucideIcons.search, size: 18, color: context.themeTextMuted),
                ),
              ),
            ),

            // Status Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filtered.length} Saved Opportunities',
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  ),
                  Text(
                    _sortByDeadline ? 'Closing Soonest' : 'Recently Announced',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),

            // Content List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryGreen,
                onRefresh: () async {
                  await ref.read(savedProvider.notifier).loadSaved();
                },
                child: filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          EmptyStateView(
                            icon: LucideIcons.bookmark,
                            title: 'No Saved Examinations',
                            description: _searchQuery.isNotEmpty
                                ? 'No saved items match "$_searchQuery".'
                                : 'Bookmark examinations you want to track to receive timely notifications and statutory deadline alerts.',
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
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                                ),
                                child: const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
                              ),
                              onDismissed: (_) {
                                ref.read(savedProvider.notifier).remove(opp.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Removed "${opp.title}" from saved.'),
                                    backgroundColor: context.themeCard,
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      textColor: AppColors.primaryGreen,
                                      onPressed: () => ref.read(savedProvider.notifier).toggleSave(opp),
                                    ),
                                  ),
                                );
                              },
                              child: OpportunityCard(
                                opportunity: opp,
                                onTap: () => context.push('/opportunities/${opp.id}'),
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
