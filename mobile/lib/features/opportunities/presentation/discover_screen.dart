import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../alerts/presentation/providers/alerts_provider.dart';
import '../../profile/presentation/providers/profile_provider.dart';
import '../../saved/presentation/providers/saved_provider.dart';
import '../../applications/presentation/providers/applications_provider.dart';
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
    if (query.trim().isEmpty) return;
    ref.read(opportunityFilterProvider.notifier).state =
        ref.read(opportunityFilterProvider).copyWith(searchQuery: query.trim());
    context.go('/explorer');
  }

  void _onQuickAccessTapped(String tag) {
    ref.read(opportunityFilterProvider.notifier).state =
        ref.read(opportunityFilterProvider).copyWith(searchQuery: tag);
    context.go('/explorer');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authState = ref.watch(authProvider);
    final profileAsync = ref.watch(profileProvider);
    final unreadAlerts = ref.watch(unreadAlertsCountProvider);
    final savedItems = ref.watch(savedProvider);
    final applications = ref.watch(applicationsProvider);
    final recommendedAsync = ref.watch(recommendedOpportunitiesProvider);
    final closingSoonAsync = ref.watch(closingSoonOpportunitiesProvider);
    final recentlyUpdatedAsync = ref.watch(recentlyUpdatedOpportunitiesProvider);

    final todayFormatted = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryBlue,
          onRefresh: () async {
            ref.invalidate(recommendedOpportunitiesProvider);
            ref.invalidate(closingSoonOpportunitiesProvider);
            ref.invalidate(recentlyUpdatedOpportunitiesProvider);
            ref.invalidate(filteredOpportunitiesProvider);
            await ref.read(savedProvider.notifier).loadSaved();
            await ref.read(applicationsProvider.notifier).loadApplications();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Top Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space16,
                    vertical: AppDimensions.space12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Logo, Date, Bell, Profile Avatar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : Colors.white,
                                  borderRadius: AppDimensions.roundedSmall,
                                  border: Border.all(color: theme.colorScheme.outline),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.space8),
                              Text(
                                'REXAM',
                                style: AppTypography.brandTitle.copyWith(
                                  fontSize: 18,
                                  letterSpacing: 2.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Notification Bell Icon with Badge
                              Stack(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.notifications_none_rounded, size: 24),
                                    onPressed: () => context.go('/alerts'),
                                    tooltip: 'Notification Center',
                                  ),
                                  if (unreadAlerts > 0)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                        child: Center(
                                          child: Text(
                                            '$unreadAlerts',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: AppDimensions.space4),

                              // Profile Avatar
                              InkWell(
                                onTap: () => context.go('/profile'),
                                borderRadius: BorderRadius.circular(20),
                                child: profileAsync.when(
                                  data: (profile) {
                                    final initials = profile.fullName.trim().isNotEmpty
                                        ? profile.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
                                        : 'R';
                                    return CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppColors.primaryBlue,
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  },
                                  loading: () => const CircleAvatar(radius: 18, backgroundColor: AppColors.primaryBlue),
                                  error: (err, stack) => const CircleAvatar(radius: 18, backgroundColor: AppColors.primaryBlue),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space12),

                      // Candidate Greeting & Date
                      profileAsync.when(
                        data: (profile) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${profile.fullName.isNotEmpty ? profile.fullName.split(' ').first : "Candidate"}',
                              style: AppTypography.screenTitle.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              todayFormatted,
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (err, stack) => const SizedBox.shrink(),
                      ),

                      // Guest Banner if applicable
                      if (authState.isGuest) ...[
                        const SizedBox(height: AppDimensions.space12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space12, vertical: AppDimensions.space8),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: AppDimensions.roundedSmall,
                            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                              const SizedBox(width: AppDimensions.space8),
                              Expanded(
                                child: Text(
                                  'Browsing in Guest Mode. Sign in to save bookmarks and track applications.',
                                  style: AppTypography.caption.copyWith(color: AppColors.warning),
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/auth'),
                                child: const Text('Sign In', style: TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold)),
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
                          hintText: 'Search examinations, jobs, organisations...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.tune, size: 18),
                            onPressed: () => context.go('/explorer'),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      // Important Statistics Cards (4 Cards)
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context: context,
                              title: 'Eligible',
                              value: '${recommendedAsync.valueOrNull?.length ?? 0}',
                              icon: Icons.check_circle_outline,
                              color: AppColors.success,
                              onTap: () => context.go('/explorer'),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space8),
                          Expanded(
                            child: _buildStatCard(
                              context: context,
                              title: 'Saved',
                              value: '${savedItems.length}',
                              icon: Icons.bookmark_outline_rounded,
                              color: AppColors.primaryBlue,
                              onTap: () => context.go('/saved'),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space8),
                          Expanded(
                            child: _buildStatCard(
                              context: context,
                              title: 'Applied',
                              value: '${applications.length}',
                              icon: Icons.assignment_outlined,
                              color: Colors.purple,
                              onTap: () => context.go('/applications'),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space8),
                          Expanded(
                            child: _buildStatCard(
                              context: context,
                              title: 'Closing',
                              value: '${closingSoonAsync.valueOrNull?.length ?? 0}',
                              icon: Icons.schedule_rounded,
                              color: AppColors.warning,
                              onTap: () => context.go('/explorer'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Access Shortcuts (UPSC, SSC, Banking, Railways, State PSC, Defence, Research, Scholarships)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: 4),
                      child: Text('Quick Access', style: AppTypography.sectionHeader),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: AppDimensions.space8),
                      child: Row(
                        children: [
                          _buildQuickShortcut('UPSC', 'upsc'),
                          _buildQuickShortcut('SSC', 'ssc'),
                          _buildQuickShortcut('Banking', 'banking'),
                          _buildQuickShortcut('Railways', 'railway'),
                          _buildQuickShortcut('State PSC', 'state'),
                          _buildQuickShortcut('Defence', 'defence'),
                          _buildQuickShortcut('Research & Science', 'research'),
                          _buildQuickShortcut('Scholarships', 'scholarship'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Section: Upcoming Deadlines
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppDimensions.space16, AppDimensions.space16, AppDimensions.space16, AppDimensions.space8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 3, height: 16, color: AppColors.warning),
                          const SizedBox(width: AppDimensions.space8),
                          Text('Upcoming Deadlines', style: AppTypography.sectionHeader),
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
              closingSoonAsync.when(
                data: (deadlines) {
                  if (deadlines.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: 8),
                        child: Text('No deadlines closing in the next 15 days.', style: TextStyle(color: AppColors.lightTextMuted, fontSize: 13)),
                      ),
                    );
                  }
                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                        itemCount: deadlines.length,
                        itemBuilder: (context, index) {
                          final opp = deadlines[index];
                          final deadline = opp.applicationDeadline;
                          final diff = deadline != null ? deadline.difference(DateTime.now()).inDays : 0;
                          final isUrgent = diff <= 3;

                          return Container(
                            width: 260,
                            margin: const EdgeInsets.only(right: AppDimensions.space12),
                            padding: const EdgeInsets.all(AppDimensions.space12),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: AppDimensions.roundedDefault,
                              border: Border.all(
                                color: isUrgent ? AppColors.warning : theme.colorScheme.outline,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        opp.organisation,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.primaryBlue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isUrgent ? AppColors.warningLight : AppColors.primaryBlueLight,
                                        borderRadius: AppDimensions.roundedSmall,
                                      ),
                                      child: Text(
                                        diff <= 0 ? 'Closes Today' : '$diff days left',
                                        style: TextStyle(
                                          color: isUrgent ? AppColors.warning : AppColors.primaryBlueDark,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  opp.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      deadline != null ? DateFormat('d MMM yyyy').format(deadline) : 'TBA',
                                      style: AppTypography.caption,
                                    ),
                                    InkWell(
                                      onTap: () => context.go('/opportunities/${opp.id}'),
                                      child: const Text('Details →', style: TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (err, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // Section: Recommended For You
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppDimensions.space16, AppDimensions.space20, AppDimensions.space16, AppDimensions.space8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 3, height: 16, color: AppColors.primaryBlue),
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
                  if (recommendations.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(AppDimensions.space16),
                        child: EmptyStateView(
                          icon: Icons.search_off_rounded,
                          title: 'No Matching Opportunities Yet',
                          description: 'We couldn\'t find opportunities directly matching your stream and preferences right now.',
                        ),
                      ),
                    );
                  }
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
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (err, stack) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    child: Text('Error loading recommendations: $err'),
                  ),
                ),
              ),

              // Section: Recently Updated / Announced
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppDimensions.space16, AppDimensions.space16, AppDimensions.space16, AppDimensions.space8),
                  child: Row(
                    children: [
                      Container(width: 3, height: 16, color: AppColors.success),
                      const SizedBox(width: AppDimensions.space8),
                      Text('Recently Updated & Announced', style: AppTypography.sectionHeader),
                    ],
                  ),
                ),
              ),
              recentlyUpdatedAsync.when(
                data: (updatedList) {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final opp = updatedList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppDimensions.space12),
                            child: OpportunityCard(
                              opportunity: opp,
                              onTap: () => context.go('/opportunities/${opp.id}'),
                            ),
                          );
                        },
                        childCount: updatedList.length > 2 ? 2 : updatedList.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (err, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: AppDimensions.roundedDefault,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: AppDimensions.roundedDefault,
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: AppDimensions.space8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontSize: 10.5,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickShortcut(String label, String tag) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: () => _onQuickAccessTapped(tag),
      ),
    );
  }
}
