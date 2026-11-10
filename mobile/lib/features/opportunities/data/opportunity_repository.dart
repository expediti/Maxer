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
      limit: 100,
    );

    var filtered = list;

    if (filter != null) {
      // Organisation Filter
      if (filter.organisation != null && filter.organisation!.isNotEmpty) {
        final orgQuery = filter.organisation!.toLowerCase();
        filtered = filtered.where((o) => o.organisation.toLowerCase().contains(orgQuery)).toList();
      }

      // State Filter
      if (filter.state != null && filter.state!.isNotEmpty) {
        filtered = filtered.where((o) => o.state == null || o.state == filter.state).toList();
      }

      // Qualification / Education Level Filter
      if (filter.qualification != null && filter.qualification!.isNotEmpty) {
        final qQuery = filter.qualification!.toLowerCase();
        filtered = filtered.where((o) => o.educationalQualifications.any(
          (q) => q.toLowerCase().contains(qQuery) || qQuery.contains(q.toLowerCase()),
        )).toList();
      }

      if (filter.educationLevel != null && filter.educationLevel!.isNotEmpty) {
        final lvlQuery = filter.educationLevel!.toLowerCase();
        filtered = filtered.where((o) => o.educationalQualifications.any(
          (q) => q.toLowerCase().contains(lvlQuery),
        )).toList();
      }

      // Stream Filter
      if (filter.stream != null && filter.stream!.isNotEmpty) {
        final sQuery = filter.stream!.toLowerCase();
        filtered = filtered.where((o) => o.eligibleStreams.any(
          (s) => s.toLowerCase().contains(sQuery) || s.toLowerCase().contains('all') || s.toLowerCase().contains('any'),
        )).toList();
      }

      // Age Filter
      if (filter.maxAge != null) {
        filtered = filtered.where((o) => (o.minAge ?? 18) <= filter.maxAge!).toList();
      }

      // Fee Filter
      if (filter.maxFee != null) {
        filtered = filtered.where((o) => (o.applicationFee ?? 0) <= filter.maxFee!).toList();
      }

      // Application Status Filter
      if (filter.applicationStatus != null && filter.applicationStatus != 'all') {
        final now = DateTime.now();
        switch (filter.applicationStatus) {
          case 'open':
            filtered = filtered.where((o) =>
                o.applicationDeadline == null || o.applicationDeadline!.isAfter(now)).toList();
            break;
          case 'closing_soon':
            filtered = filtered.where((o) {
              if (o.applicationDeadline == null) return false;
              final diff = o.applicationDeadline!.difference(now).inDays;
              return diff >= 0 && diff <= 15;
            }).toList();
            break;
          case 'upcoming':
            filtered = filtered.where((o) =>
                o.applicationStartDate != null && o.applicationStartDate!.isAfter(now)).toList();
            break;
          case 'closed':
            filtered = filtered.where((o) =>
                o.applicationDeadline != null && o.applicationDeadline!.isBefore(now)).toList();
            break;
        }
      }

      // Closing Soon Quick Filter
      if (filter.closingSoonOnly) {
        final now = DateTime.now();
        filtered = filtered.where((o) {
          if (o.applicationDeadline == null) return false;
          final diff = o.applicationDeadline!.difference(now).inDays;
          return diff >= 0 && diff <= 15;
        }).toList();
      }

      // Sorting
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
