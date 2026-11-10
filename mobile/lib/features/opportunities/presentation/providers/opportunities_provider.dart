import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexam/features/opportunities/domain/opportunity.dart';
import 'package:rexam/features/opportunities/domain/opportunity_filter.dart';
import 'package:rexam/features/opportunities/data/opportunity_repository.dart';
import 'package:rexam/features/profile/presentation/providers/profile_provider.dart';

final opportunityRepositoryProvider = Provider<OpportunityRepository>((ref) {
  return SupabaseOpportunityRepository();
});

final opportunityFilterProvider = StateProvider<OpportunityFilter>((ref) {
  return const OpportunityFilter();
});

class PaginatedOpportunitiesState {
  final List<Opportunity> items;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final String? errorMessage;

  const PaginatedOpportunitiesState({
    this.items = const [],
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingInitial = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  PaginatedOpportunitiesState copyWith({
    List<Opportunity>? items,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PaginatedOpportunitiesState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PaginatedOpportunitiesNotifier extends StateNotifier<PaginatedOpportunitiesState> {
  final OpportunityRepository _repository;
  final OpportunityFilter _filter;
  final Set<String> _seenIds = {};
  static const int pageSize = 30;

  PaginatedOpportunitiesNotifier(this._repository, this._filter)
      : super(const PaginatedOpportunitiesState(isLoadingInitial: true)) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoadingInitial: true, clearError: true);
    _seenIds.clear();
    try {
      final items = await _repository.getOpportunities(
        filter: _filter,
        page: 1,
        pageSize: pageSize,
      );
      for (final it in items) {
        _seenIds.add(it.id);
      }
      state = state.copyWith(
        items: items,
        currentPage: 1,
        hasMore: items.length >= pageSize,
        isLoadingInitial: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingInitial: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoadingInitial) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);
    final nextPage = state.currentPage + 1;

    try {
      final newItems = await _repository.getOpportunities(
        filter: _filter,
        page: nextPage,
        pageSize: pageSize,
      );

      final unique = newItems.where((it) => !_seenIds.contains(it.id)).toList();
      for (final it in unique) {
        _seenIds.add(it.id);
      }

      state = state.copyWith(
        items: [...state.items, ...unique],
        currentPage: nextPage,
        hasMore: newItems.length >= pageSize,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }
}

final paginatedOpportunitiesProvider =
    StateNotifierProvider<PaginatedOpportunitiesNotifier, PaginatedOpportunitiesState>((ref) {
  final repo = ref.watch(opportunityRepositoryProvider);
  final filter = ref.watch(opportunityFilterProvider);
  return PaginatedOpportunitiesNotifier(repo, filter);
});

// Backward compatible provider for other views (DiscoverScreen, tests)
final filteredOpportunitiesProvider = FutureProvider<List<Opportunity>>((ref) async {
  final repo = ref.watch(opportunityRepositoryProvider);
  final filter = ref.watch(opportunityFilterProvider);
  return repo.getOpportunities(filter: filter, page: 1, pageSize: 100);
});

final closingSoonOpportunitiesProvider = FutureProvider<List<Opportunity>>((ref) async {
  final repo = ref.watch(opportunityRepositoryProvider);
  return repo.getClosingSoonOpportunities(limit: 6);
});

final recentlyUpdatedOpportunitiesProvider = FutureProvider<List<Opportunity>>((ref) async {
  final repo = ref.watch(opportunityRepositoryProvider);
  final all = await repo.getOpportunities(page: 1, pageSize: 30);
  final list = List<Opportunity>.from(all)
    ..sort((a, b) {
      final aTime = a.lastVerifiedAt ?? DateTime(2026);
      final bTime = b.lastVerifiedAt ?? DateTime(2026);
      return bTime.compareTo(aTime);
    });
  return list.take(5).toList();
});

final recommendedOpportunitiesProvider = FutureProvider<List<Opportunity>>((ref) async {
  final repo = ref.watch(opportunityRepositoryProvider);
  final profileAsync = ref.watch(profileProvider);

  return profileAsync.when(
    data: (profile) => repo.getRecommendedOpportunities(profile),
    loading: () => repo.getOpportunities(page: 1, pageSize: 30),
    error: (err, stack) => repo.getOpportunities(page: 1, pageSize: 30),
  );
});

final opportunityDetailProvider = FutureProvider.family<Opportunity?, String>((ref, id) async {
  final repo = ref.watch(opportunityRepositoryProvider);
  return repo.getOpportunityById(id);
});
