import '../domain/opportunity.dart';
import '../domain/opportunity_filter.dart';
import '../../profile/domain/candidate_profile.dart';
import '../../../repositories/examination_repository.dart';

abstract class OpportunityRepository {
  Future<List<Opportunity>> getOpportunities({OpportunityFilter? filter});
  Future<Opportunity?> getOpportunityById(String id);
  Future<List<Opportunity>> getRecommendedOpportunities(CandidateProfile candidate);
  Future<List<Opportunity>> getClosingSoonOpportunities({int limit = 5});
  Future<List<Opportunity>> searchOpportunities(String query);
}

class SupabaseOpportunityRepository implements OpportunityRepository {
  final ExaminationRepository _examRepo = SupabaseExaminationRepository();

  @override
  Future<List<Opportunity>> getOpportunities({OpportunityFilter? filter}) async {
    final list = await _examRepo.getExaminations(
      category: filter?.category,
      isCentralGovernment: filter?.isCentralGovernment,
      searchQuery: filter?.searchQuery,
      limit: 50,
    );

    var filtered = list;

    if (filter != null) {
      if (filter.state != null && filter.state!.isNotEmpty) {
        filtered = filtered.where((o) => o.state == null || o.state == filter.state).toList();
      }

      if (filter.maxAge != null) {
        filtered = filtered.where((o) => (o.minAge ?? 18) <= filter.maxAge!).toList();
      }

      if (filter.maxFee != null) {
        filtered = filtered.where((o) => (o.applicationFee ?? 0) <= filter.maxFee!).toList();
      }

      if (filter.closingSoonOnly) {
        final now = DateTime.now();
        filtered = filtered.where((o) {
          if (o.applicationDeadline == null) return false;
          final diff = o.applicationDeadline!.difference(now).inDays;
          return diff >= 0 && diff <= 15;
        }).toList();
      }

      // Sort
      switch (filter.sortOption) {
        case OpportunitySortOption.latest:
          filtered.sort((a, b) {
            final aTime = a.lastVerifiedAt ?? DateTime(2026);
            final bTime = b.lastVerifiedAt ?? DateTime(2026);
            return bTime.compareTo(aTime);
          });
          break;
        case OpportunitySortOption.deadline:
          filtered.sort((a, b) {
            if (a.applicationDeadline == null) return 1;
            if (b.applicationDeadline == null) return -1;
            return a.applicationDeadline!.compareTo(b.applicationDeadline!);
          });
          break;
        case OpportunitySortOption.recentlyUpdated:
          filtered.sort((a, b) {
            final aTime = a.lastVerifiedAt ?? DateTime(2026);
            final bTime = b.lastVerifiedAt ?? DateTime(2026);
            return bTime.compareTo(aTime);
          });
          break;
        case OpportunitySortOption.alphabetical:
          filtered.sort((a, b) => a.title.compareTo(b.title));
          break;
        case OpportunitySortOption.feeLowToHigh:
          filtered.sort((a, b) => (a.applicationFee ?? 0).compareTo(b.applicationFee ?? 0));
          break;
        case OpportunitySortOption.relevance:
          break;
      }
    }

    return filtered;
  }

  @override
  Future<Opportunity?> getOpportunityById(String id) {
    return _examRepo.getExaminationById(id);
  }

  @override
  Future<List<Opportunity>> getRecommendedOpportunities(CandidateProfile candidate) {
    return _examRepo.getRecommendedExaminations(candidate);
  }

  @override
  Future<List<Opportunity>> getClosingSoonOpportunities({int limit = 5}) {
    return _examRepo.getClosingSoonExaminations(limit: limit);
  }

  @override
  Future<List<Opportunity>> searchOpportunities(String query) {
    return _examRepo.searchExaminations(query);
  }
}

class MockOpportunityRepository extends SupabaseOpportunityRepository {}
