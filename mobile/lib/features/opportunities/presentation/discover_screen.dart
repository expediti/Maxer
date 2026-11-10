import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/organisation_logo.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../alerts/presentation/providers/alerts_provider.dart';
import '../../profile/presentation/providers/profile_provider.dart';
import '../../saved/presentation/providers/saved_provider.dart';
import '../../applications/presentation/providers/applications_provider.dart';
import '../domain/opportunity_filter.dart';
import '../../../models/examination.dart';
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
    if (tag.toLowerCase() == 'scholarship' || tag.toLowerCase() == 'scholarships') {
      ref.read(opportunityFilterProvider.notifier).state =
          const OpportunityFilter(category: ExaminationCategory.scholarship);
    } else {
      ref.read(opportunityFilterProvider.notifier).state =
          ref.read(opportunityFilterProvider).copyWith(searchQuery: tag, clearCategory: true);
    }
    context.go('/explorer');
  }

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: AppColors.mainBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryGreen,
          backgroundColor: AppColors.elevatedSurface,
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
                                  color: AppColors.elevatedSurface,
                                  borderRadius: AppDimensions.roundedSmall,
                                  border: Border.all(color: AppColors.borders),
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
                                  letterSpacing: 2.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.mainText,
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
                                    icon: const Icon(LucideIcons.bell, size: 20, color: AppColors.mainText),
                                    onPressed: () => context.push('/alerts'),
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
                                        : (authState.user?.displayName?.isNotEmpty == true
                                            ? authState.user!.displayName![0]
                                            : 'R');
                                    return CircleAvatar(
                                      radius: 17,
                                      backgroundColor: AppColors.elevatedSurface,
                                      child: Text(
                                        initials.toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.primaryGreen,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  },
                                  loading: () => const CircleAvatar(radius: 17, backgroundColor: AppColors.elevatedSurface),
                                  error: (err, stack) => const CircleAvatar(radius: 17, backgroundColor: AppColors.elevatedSurface),
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
                              'Hello, ${profile.fullName.isNotEmpty ? profile.fullName.split(' ').first : (authState.user?.displayName ?? "Candidate")}',
                              style: AppTypography.screenTitle.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.mainText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              todayFormatted,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                        loading: () => Text(
                          'Welcome to REXAM',
                          style: AppTypography.screenTitle.copyWith(color: AppColors.mainText),
                        ),
                        error: (err, stack) => Text(
                          'Welcome to REXAM',
                          style: AppTypography.screenTitle.copyWith(color: AppColors.mainText),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      // Search Input Field
                      TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _onSearchSubmitted,
                        style: const TextStyle(color: AppColors.mainText),
                        decoration: InputDecoration(
                          hintText: 'Search exams, organisations, posts...',
                          prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.secondaryText),
                          suffixIcon: IconButton(
                            icon: const Icon(LucideIcons.slidersHorizontal, size: 16, color: AppColors.secondaryText),
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
                              icon: LucideIcons.checkCircle2,
                              color: AppColors.primaryGreen,
                              onTap: () => context.go('/explorer?section=eligible'),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space8),
                          Expanded(
                            child: _buildStatCard(
                              context: context,
                              title: 'Saved',
                              value: '${savedItems.length}',
                              icon: LucideIcons.bookmark,
                              color: AppColors.mainText,
                              onTap: () => context.go('/saved'),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space8),
                          Expanded(
                            child: _buildStatCard(
                              context: context,
                              title: 'Applied',
                              value: '${applications.length}',
                              icon: LucideIcons.clipboardList,
                              color: AppColors.info,
                              onTap: () => context.go('/applications'),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space8),
                          Expanded(
                            child: _buildStatCard(
                              context: context,
                              title: 'Closing',
                              value: '${closingSoonAsync.valueOrNull?.length ?? 0}',
                              icon: LucideIcons.clock,
                              color: AppColors.warning,
                              onTap: () => context.go('/explorer?section=eligible'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Access Shortcuts
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: 4),
                      child: Text('Quick Access', style: AppTypography.sectionHeader.copyWith(color: AppColors.mainText)),
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
                          Text('Upcoming Deadlines', style: AppTypography.sectionHeader.copyWith(color: AppColors.mainText)),
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
                        child: Text(
                          'No upcoming verified deadlines at this time.',
                          style: TextStyle(color: AppColors.mutedText, fontSize: 13),
                        ),
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
                              color: AppColors.elevatedSurface,
                              borderRadius: AppDimensions.roundedDefault,
                              border: Border.all(
                                color: isUrgent ? AppColors.warning : AppColors.borders,
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
                                      child: Row(
                                        children: [
                                          OrganisationLogo(
                                            slug: opp.slug,
                                            name: opp.organisation,
                                            size: 26,
                                            borderRadius: 6,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              opp.organisation,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.caption.copyWith(
                                                color: AppColors.primaryGreen,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isUrgent ? AppColors.warningBg : AppColors.greenTint,
                                        borderRadius: AppDimensions.roundedSmall,
                                      ),
                                      child: Text(
                                        diff <= 0 ? 'Closes Today' : '$diff days left',
                                        style: TextStyle(
                                          color: isUrgent ? AppColors.warning : AppColors.primaryGreen,
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppColors.mainText,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      deadline != null ? DateFormat('d MMM yyyy').format(deadline) : 'TBA',
                                      style: AppTypography.caption.copyWith(color: AppColors.secondaryText),
                                    ),
                                    InkWell(
                                      onTap: () => context.push('/opportunities/${opp.id}'),
                                      child: const Text(
                                        'Details →',
                                        style: TextStyle(
                                          color: AppColors.primaryGreen,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen)),
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
                          Container(width: 3, height: 16, color: AppColors.primaryGreen),
                          const SizedBox(width: AppDimensions.space8),
                          Text('Recommended for You', style: AppTypography.sectionHeader.copyWith(color: AppColors.mainText)),
                        ],
                      ),
                      TextButton(
                        onPressed: () => context.go('/explorer?section=eligible'),
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
                          icon: LucideIcons.searchX,
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
                              onTap: () => context.push('/opportunities/${opp.id}'),
                            ),
                          );
                        },
                        childCount: recommendations.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen)),
                    ),
                  ),
                ),
                error: (err, stack) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error loading recommendations: $err', style: const TextStyle(color: AppColors.error)),
                  ),
                ),
              ),

              // Section: Recently Updated
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppDimensions.space16, AppDimensions.space20, AppDimensions.space16, AppDimensions.space8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 3, height: 16, color: AppColors.info),
                          const SizedBox(width: AppDimensions.space8),
                          Text('Recently Updated', style: AppTypography.sectionHeader.copyWith(color: AppColors.mainText)),
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
              recentlyUpdatedAsync.when(
                data: (recent) {
                  if (recent.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: 8),
                        child: Text('No recently updated examinations at this time.', style: TextStyle(color: AppColors.mutedText, fontSize: 13)),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final opp = recent[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppDimensions.space12),
                            child: OpportunityCard(
                              opportunity: opp,
                              onTap: () => context.push('/opportunities/${opp.id}'),
                            ),
                          );
                        },
                        childCount: recent.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen)),
                    ),
                  ),
                ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: AppDimensions.roundedDefault,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space10,
          vertical: AppDimensions.space12,
        ),
        decoration: BoxDecoration(
          color: AppColors.elevatedSurface,
          borderRadius: AppDimensions.roundedDefault,
          border: Border.all(color: AppColors.borders),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 16, color: color),
                Text(
                  value,
                  style: AppTypography.screenTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.secondaryText,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickShortcut(String label, String tag) {
    return Padding(
      padding: const EdgeInsets.only(right: AppDimensions.space8),
      child: ActionChip(
        label: Text(label),
        backgroundColor: AppColors.secondarySurface,
        labelStyle: AppTypography.caption.copyWith(
          color: AppColors.mainText,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: AppColors.borders),
        onPressed: () => _onQuickAccessTapped(tag),
      ),
    );
  }
}
