import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexam/features/opportunities/domain/opportunity.dart';
import 'package:rexam/features/opportunities/domain/opportunity_filter.dart';
import 'package:rexam/features/opportunities/data/opportunity_repository.dart';
import 'package:rexam/features/profile/presentation/providers/profile_provider.dart';

final opportunityRepositoryProvider = Provider<OpportunityRepository>((ref) {
  return MockOpportunityRepository();
});

final opportunityFilterProvider = StateProvider<OpportunityFilter>((ref) {
  return const OpportunityFilter();
});

final filteredOpportunitiesProvider = FutureProvider<List<Opportunity>>((ref) async {
  final repo = ref.watch(opportunityRepositoryProvider);
  final filter = ref.watch(opportunityFilterProvider);
  return repo.getOpportunities(filter: filter);
});

final closingSoonOpportunitiesProvider = FutureProvider<List<Opportunity>>((ref) async {
  final repo = ref.watch(opportunityRepositoryProvider);
  return repo.getClosingSoonOpportunities(limit: 6);
});

final recommendedOpportunitiesProvider = FutureProvider<List<Opportunity>>((ref) async {
  final repo = ref.watch(opportunityRepositoryProvider);
  final profileAsync = ref.watch(profileProvider);

  return profileAsync.when(
    data: (profile) => repo.getRecommendedOpportunities(profile),
    loading: () => repo.getOpportunities(),
    error: (_, __) => repo.getOpportunities(),
  );
});

final opportunityDetailProvider = FutureProvider.family<Opportunity?, String>((ref, id) async {
  final repo = ref.watch(opportunityRepositoryProvider);
  return repo.getOpportunityById(id);
});
