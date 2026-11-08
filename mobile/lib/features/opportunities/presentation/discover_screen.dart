import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../alerts/presentation/providers/alerts_provider.dart';
import '../../profile/presentation/providers/profile_provider.dart';

import 'providers/opportunities_provider.dart';
import 'widgets/opportunity_card.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    ref.read(opportunityFilterProvider.notifier).state =
        ref.read(opportunityFilterProvider).copyWith(searchQuery: query);
    context.go('/explorer');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profileAsync = ref.watch(profileProvider);
    final unreadAlerts = ref.watch(unreadAlertsCountProvider);
    final recommendedAsync = ref.watch(recommendedOpportunitiesProvider);
    final closingSoonAsync = ref.watch(closingSoonOpportunitiesProvider);
    final allOpportunitiesAsync = ref.watch(filteredOpportunitiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryGreen,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            ref.invalidate(recommendedOpportunitiesProvider);
            ref.invalidate(closingSoonOpportunitiesProvider);
            ref.invalidate(filteredOpportunitiesProvider);
          },
          child: CustomScrollView(
            slivers: [
              // Top Header Sliver
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space16,
                    vertical: AppDimensions.space12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: AppDimensions.roundedSmall,
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.space8),
                              Text(
                                'REXAM',
                                style: AppTypography.brandTitle.copyWith(
                                  fontSize: 18,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Profile Completion Pill
                              profileAsync.when(
                                data: (profile) => InkWell(
                                  onTap: () => context.go('/profile/wizard'),
                                  borderRadius: AppDimensions.roundedSmall,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppDimensions.space8,
                                      vertical: AppDimensions.space4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryBackground,
                                      borderRadius: AppDimensions.roundedSmall,
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.verified_user_outlined, size: 12, color: AppColors.primaryGreen),
                                        const SizedBox(width: AppDimensions.space4),
                                        Text(
                                          '${profile.completionPercentage}% Complete',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.textMain,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                              const SizedBox(width: AppDimensions.space12),

                              // Notification Icon with badge
                              Stack(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.notifications_none_outlined, size: 22),
                                    onPressed: () => context.go('/alerts'),
                                  ),
                                  if (unreadAlerts > 0)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryGreen,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                        child: Center(
                                          child: Text(
                                            '$unreadAlerts',
                                            style: const TextStyle(
                                              color: AppColors.background,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space12),

                      // Candidate Greeting
                      profileAsync.when(
                        data: (profile) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${profile.fullName.isNotEmpty ? profile.fullName.split(' ').first : "Candidate"}',
                              style: AppTypography.screenTitle.copyWith(fontSize: 20),
                            ),
                            const SizedBox(height: AppDimensions.space2),
                            Text(
                              '${profile.highestQualification ?? "Graduate"} • ${profile.socialCategory} • ${profile.state ?? "India"}',
                              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      // Guest Banner if applicable
                      if (authState.isGuest) ...[
                        const SizedBox(height: AppDimensions.space12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space12, vertical: AppDimensions.space8),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: AppDimensions.roundedSmall,
                            border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                              const SizedBox(width: AppDimensions.space8),
                              Expanded(
                                child: Text(
                                  'Browsing in Guest Mode. Sign in to save bookmarks and track application status.',
                                  style: AppTypography.caption.copyWith(color: AppColors.warning),
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/auth'),
                                child: const Text('Sign In', style: TextStyle(color: AppColors.warning, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppDimensions.space16),

                      // Search Input Field
                      TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _onSearchSubmitted,
                        decoration: InputDecoration(
                          hintText: 'Search exams, PSUs, universities, branches...',
                          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.tune, size: 18, color: AppColors.primaryGreen),
                            onPressed: () => context.go('/explorer'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Section 1: Recommended For You
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppDimensions.space16,
                    right: AppDimensions.space16,
                    top: AppDimensions.space12,
                    bottom: AppDimensions.space8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 3, height: 14, color: AppColors.primaryGreen),
                          const SizedBox(width: AppDimensions.space8),
                          Text('Recommended for You', style: AppTypography.sectionHeader),
                        ],
                      ),
                      TextButton(
                        onPressed: () => context.go('/explorer'),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),
              ),
              recommendedAsync.when(
                data: (recommendations) {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final opp = recommendations[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppDimensions.space12),
                            child: OpportunityCard(
                              opportunity: opp,
                              onTap: () => context.go('/opportunities/${opp.id}'),
                            ),
                          );
                        },
                        childCount: recommendations.length > 3 ? 3 : recommendations.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppDimensions.space24),
                      child: CircularProgressIndicator(color: AppColors.primaryGreen),
                    ),
                  ),
                ),
                error: (err, _) => SliverToBoxAdapter(
                  child: Center(child: Text('Error loading recommendations: $err', style: AppTypography.caption)),
                ),
              ),

              // Section 2: Closing Soon
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppDimensions.space16,
                    right: AppDimensions.space16,
                    top: AppDimensions.space16,
                    bottom: AppDimensions.space8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 3, height: 14, color: AppColors.warning),
                          const SizedBox(width: AppDimensions.space8),
                          Text('Closing Soon (Urgent Deadlines)', style: AppTypography.sectionHeader),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(opportunityFilterProvider.notifier).state =
                              ref.read(opportunityFilterProvider).copyWith(closingSoonOnly: true);
                          context.go('/explorer');
                        },
                        child: const Text('Filter'),
                      ),
                    ],
                  ),
                ),
              ),
              closingSoonAsync.when(
                data: (closingList) {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final opp = closingList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppDimensions.space12),
                            child: OpportunityCard(
                              opportunity: opp,
                              onTap: () => context.go('/opportunities/${opp.id}'),
                            ),
                          );
                        },
                        childCount: closingList.length > 2 ? 2 : closingList.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // Section 3: All Opportunities List Preview
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppDimensions.space16,
                    right: AppDimensions.space16,
                    top: AppDimensions.space16,
                    bottom: AppDimensions.space8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 3, height: 14, color: AppColors.textMuted),
                          const SizedBox(width: AppDimensions.space8),
                          Text('All Verified Opportunities', style: AppTypography.sectionHeader),
                        ],
                      ),
                      TextButton(
                        onPressed: () => context.go('/explorer'),
                        child: const Text('Explore Catalog'),
                      ),
                    ],
                  ),
                ),
              ),
              allOpportunitiesAsync.when(
                data: (allList) {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final opp = allList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppDimensions.space12),
                            child: OpportunityCard(
                              opportunity: opp,
                              onTap: () => context.go('/opportunities/${opp.id}'),
                            ),
                          );
                        },
                        childCount: allList.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space32)),
            ],
          ),
        ),
      ),
    );
  }
}
