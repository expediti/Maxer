import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/candidate_profile.dart';
import '../../../models/eligibility_report.dart';
import '../../../repositories/eligibility_repository.dart';
import '../../profile/presentation/providers/profile_provider.dart';
import '../domain/opportunity.dart';
import '../domain/opportunity_filter.dart';
import 'providers/opportunities_provider.dart';
import 'widgets/opportunity_card.dart';
import 'widgets/filter_sheet.dart';

class ExplorerScreen extends ConsumerStatefulWidget {
  final int initialSection;

  const ExplorerScreen({
    super.key,
    this.initialSection = 0,
  });

  @override
  ConsumerState<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends ConsumerState<ExplorerScreen> {
  final TextEditingController _searchController = TextEditingController();
  late int _selectedSectionIndex; // 0: All Examinations, 1: Eligible for Me
  bool _showVerificationExams = false;

  @override
  void initState() {
    super.initState();
    _selectedSectionIndex = widget.initialSection;
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
    final profileAsync = ref.watch(profileProvider);
    final CandidateProfile? candidate = profileAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        backgroundColor: AppColors.mainBackground,
        title: const Text('Examinations & Discoveries'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(LucideIcons.slidersHorizontal, size: 20, color: AppColors.primaryText),
                if (filter.hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
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
            // Top Section Selector: Two Distinct Sections
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space8,
              ),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.elevatedSurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSectionTab(
                        title: 'All Examinations',
                        index: 0,
                        icon: LucideIcons.layers,
                      ),
                    ),
                    Expanded(
                      child: _buildSectionTab(
                        title: 'Eligible for Me',
                        index: 1,
                        icon: LucideIcons.badgeCheck,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space4,
              ),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                style: const TextStyle(color: AppColors.primaryText),
                onChanged: (val) {
                  ref.read(opportunityFilterProvider.notifier).state =
                      filter.copyWith(searchQuery: val);
                },
                decoration: InputDecoration(
                  hintText: _selectedSectionIndex == 0
                      ? 'Search all published exams, PSUs, scholarships...'
                      : 'Search eligible examinations...',
                  prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.secondaryText),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 16, color: AppColors.secondaryText),
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
                vertical: AppDimensions.space6,
              ),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: filter.category == null && (filter.organisation == null || filter.organisation!.isEmpty),
                    selectedColor: AppColors.white,
                    backgroundColor: AppColors.cardBackground,
                    labelStyle: TextStyle(
                      color: filter.category == null && (filter.organisation == null || filter.organisation!.isEmpty)
                          ? AppColors.black
                          : AppColors.secondaryText,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: filter.category == null && (filter.organisation == null || filter.organisation!.isEmpty)
                          ? AppColors.white
                          : AppColors.border,
                    ),
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) {
                        _searchController.clear();
                        ref.read(opportunityFilterProvider.notifier).state =
                            const OpportunityFilter();
                      }
                    },
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  ...[
                    'Scholarships',
                    'UPSC',
                    'SSC',
                    'Banking',
                    'Railways',
                    'State PSC',
                    'Defence',
                  ].map((filterName) {
                    final bool isScholarshipChip = filterName == 'Scholarships';
                    final bool isSelected = isScholarshipChip
                        ? filter.category == ExaminationCategory.scholarship
                        : filter.organisation?.toLowerCase() == filterName.toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: AppDimensions.space8),
                      child: ChoiceChip(
                        label: Text(filterName),
                        selected: isSelected,
                        selectedColor: AppColors.white,
                        backgroundColor: AppColors.cardBackground,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.black : AppColors.secondaryText,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        side: BorderSide(color: isSelected ? AppColors.white : AppColors.border),
                        showCheckmark: false,
                        onSelected: (selected) {
                          if (isScholarshipChip) {
                            ref.read(opportunityFilterProvider.notifier).state = selected
                                ? filter.copyWith(category: ExaminationCategory.scholarship, clearOrganisation: true)
                                : filter.copyWith(clearCategory: true);
                          } else {
                            ref.read(opportunityFilterProvider.notifier).state = selected
                                ? filter.copyWith(organisation: filterName, clearCategory: true)
                                : filter.copyWith(clearOrganisation: true);
                          }
                        },
                      ),
                    );
                  }),
                  ...ExaminationCategory.values
                      .where((c) =>
                          c != ExaminationCategory.scholarship &&
                          c != ExaminationCategory.entranceExam &&
                          c != ExaminationCategory.internshipResearch)
                      .map((cat) {
                    final isSelected = filter.category == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppDimensions.space8),
                      child: ChoiceChip(
                        label: Text(cat.label),
                        selected: isSelected,
                        selectedColor: AppColors.white,
                        backgroundColor: AppColors.cardBackground,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.black : AppColors.secondaryText,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        side: BorderSide(color: isSelected ? AppColors.white : AppColors.border),
                        showCheckmark: false,
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
            const SizedBox(height: AppDimensions.space4),

            // Main Content Area
            Expanded(
              child: RefreshIndicator(
                color: AppColors.white,
                backgroundColor: AppColors.elevatedSurface,
                onRefresh: () async {
                  ref.invalidate(filteredOpportunitiesProvider);
                },
                child: opportunitiesAsync.when(
                  data: (opportunities) {
                    if (_selectedSectionIndex == 0) {
                      // Section A: All Examinations
                      return _buildAllExaminationsList(
                        opportunities: opportunities,
                        candidate: candidate,
                        filter: filter,
                      );
                    } else {
                      // Section B: Eligible for Me
                      return _buildEligibleForMeList(
                        opportunities: opportunities,
                        candidate: candidate,
                        filter: filter,
                      );
                    }
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  ),
                  error: (error, stack) => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 60),
                      EmptyStateView(
                        icon: LucideIcons.wifiOff,
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

  Widget _buildSectionTab({
    required String title,
    required int index,
    required IconData icon,
  }) {
    final isSelected = _selectedSectionIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedSectionIndex = index),
      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.black : AppColors.secondaryText,
            ),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.black : AppColors.secondaryText,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section A: Displays every published examination regardless of candidate eligibility
  Widget _buildAllExaminationsList({
    required List<Opportunity> opportunities,
    required CandidateProfile? candidate,
    required OpportunityFilter filter,
  }) {
    // Post-filter by eligibility status if explicitly requested in filter sheet
    var list = opportunities;
    if (filter.eligibilityStatusFilter != null && candidate != null) {
      final reqStatus = filter.eligibilityStatusFilter!;
      list = list.where((opp) {
        final rep = DeterministicEligibilityRepository.evaluate(
          candidate: candidate,
          examination: opp,
        );
        if (reqStatus == 'eligible') {
          return rep.overallStatus == EligibilityStatus.eligible;
        } else if (reqStatus == 'needs_verification') {
          return rep.overallStatus == EligibilityStatus.missingInformation ||
              rep.overallStatus == EligibilityStatus.needsVerification;
        } else if (reqStatus == 'ineligible') {
          return rep.overallStatus == EligibilityStatus.notEligible;
        }
        return true;
      }).toList();
    }

    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 60),
          EmptyStateView(
            icon: LucideIcons.searchX,
            title: 'No Examinations Found',
            description: filter.hasActiveFilters || filter.searchQuery.isNotEmpty
                ? 'No published examinations match your selected criteria. Try adjusting or resetting filters.'
                : 'No examinations published yet.',
            actionLabel: filter.hasActiveFilters || filter.searchQuery.isNotEmpty ? 'Reset Filters' : null,
            onAction: () {
              _searchController.clear();
              ref.read(opportunityFilterProvider.notifier).state = const OpportunityFilter();
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
      itemCount: list.length,
      itemBuilder: (context, index) {
        final opp = list[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.space12),
          child: OpportunityCard(
            opportunity: opp,
            onTap: () => context.push('/opportunities/${opp.id}'),
          ),
        );
      },
    );
  }

  /// Section B: Displays only examinations where the candidate satisfies all verified mandatory requirements
  Widget _buildEligibleForMeList({
    required List<Opportunity> opportunities,
    required CandidateProfile? candidate,
    required OpportunityFilter filter,
  }) {
    if (candidate == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 60),
          EmptyStateView(
            icon: LucideIcons.userX,
            title: 'Profile Incomplete',
            description: 'Complete your profile details to evaluate eligibility across all examinations.',
            actionLabel: 'Complete Profile',
            onAction: () => context.go('/profile/wizard'),
          ),
        ],
      );
    }

    // Evaluate all opportunities against candidate using shared engine
    final Map<Opportunity, EligibilityReport> confirmedEligible = {};
    final Map<Opportunity, EligibilityReport> requiresVerification = {};

    for (final opp in opportunities) {
      final report = DeterministicEligibilityRepository.evaluate(
        candidate: candidate,
        examination: opp,
      );

      if (report.overallStatus == EligibilityStatus.eligible) {
        confirmedEligible[opp] = report;
      } else if (report.overallStatus == EligibilityStatus.missingInformation ||
          report.overallStatus == EligibilityStatus.needsVerification) {
        requiresVerification[opp] = report;
      }
    }

    final eligibleList = confirmedEligible.keys.toList();
    final verificationList = requiresVerification.keys.toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space8,
      ),
      children: [
        // Sub-section: Needs Verification Toggle Banner
        if (verificationList.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.space12),
            decoration: BoxDecoration(
              color: AppColors.elevatedSurface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _showVerificationExams = !_showVerificationExams),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.space12),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.pending,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${verificationList.length} Examinations Require Verification',
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Requires official university CGPA conversion certificate or specific documents.',
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _showVerificationExams ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                          size: 16,
                          color: AppColors.secondaryText,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showVerificationExams) ...[
                  const Divider(color: AppColors.divider, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.space12),
                    child: Column(
                      children: verificationList.map((opp) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppDimensions.space8),
                          child: OpportunityCard(
                            opportunity: opp,
                            customReport: requiresVerification[opp],
                            showEligibilityDetails: true,
                            onTap: () => context.push('/opportunities/${opp.id}'),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        // Confirmed Eligible Examinations
        if (eligibleList.isEmpty) ...[
          const SizedBox(height: 40),
          EmptyStateView(
            icon: LucideIcons.shieldAlert,
            title: 'No Confirmed Eligible Examinations',
            description:
                'You do not currently meet all mandatory criteria for published exams, or your profile is missing verification documents.',
            actionLabel: 'Explore All Examinations',
            onAction: () => setState(() => _selectedSectionIndex = 0),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.space10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.eligible,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${eligibleList.length} Confirmed Opportunities',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
                const Text(
                  '100% Rules Satisfied',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ...eligibleList.map((opp) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.space12),
              child: OpportunityCard(
                opportunity: opp,
                customReport: confirmedEligible[opp],
                showEligibilityDetails: true,
                onTap: () => context.push('/opportunities/${opp.id}'),
              ),
            );
          }),
        ],
      ],
    );
  }
}
