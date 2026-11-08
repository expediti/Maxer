import '../domain/opportunity.dart';
import '../domain/opportunity_filter.dart';
import '../../profile/domain/candidate_profile.dart';
import 'mock_opportunities_data.dart';

abstract class OpportunityRepository {
  Future<List<Opportunity>> getOpportunities({OpportunityFilter? filter});
  Future<Opportunity?> getOpportunityById(String id);
  Future<List<Opportunity>> getRecommendedOpportunities(CandidateProfile candidate);
  Future<List<Opportunity>> getClosingSoonOpportunities({int limit = 5});
  Future<List<Opportunity>> searchOpportunities(String query);
}

class MockOpportunityRepository implements OpportunityRepository {
  final List<Opportunity> _items = List.unmodifiable(mockOpportunities);

  @override
  Future<List<Opportunity>> getOpportunities({OpportunityFilter? filter}) async {
    // Simulate brief asynchronous delay
    await Future.delayed(const Duration(milliseconds: 150));

    if (filter == null) return _items;

    var filtered = _items.where((opp) {
      if (filter.searchQuery.trim().isNotEmpty) {
        final query = filter.searchQuery.toLowerCase();
        final matchesTitle = opp.title.toLowerCase().contains(query);
        final matchesOrg = opp.organisation.toLowerCase().contains(query);
        final matchesAuthority = opp.issuingAuthority.toLowerCase().contains(query);
        final matchesStream = opp.eligibleStreams.any((s) => s.toLowerCase().contains(query));
        final matchesQual = opp.educationalQualifications.any((q) => q.toLowerCase().contains(query));

        if (!matchesTitle && !matchesOrg && !matchesAuthority && !matchesStream && !matchesQual) {
          return false;
        }
      }

      if (filter.category != null && opp.category != filter.category) {
        return false;
      }

      if (filter.isCentralGovernment != null && opp.isCentralGovernment != filter.isCentralGovernment) {
        return false;
      }

      if (filter.state != null && opp.state != null && opp.state != filter.state) {
        return false;
      }

      if (filter.maxAge != null && opp.minAge > filter.maxAge!) {
        return false;
      }

      if (filter.maxFee != null) {
        final fee = opp.applicationFee ?? 0;
        if (fee > filter.maxFee!) return false;
      }

      if (filter.closingSoonOnly) {
        final now = DateTime.now();
        final diff = opp.applicationDeadline.difference(now).inDays;
        if (diff < 0 || diff > 15) return false;
      }

      return true;
    }).toList();

    // Sorting
    switch (filter.sortOption) {
      case OpportunitySortOption.latest:
        filtered.sort((a, b) => b.lastVerifiedAt.compareTo(a.lastVerifiedAt));
        break;
      case OpportunitySortOption.deadline:
        filtered.sort((a, b) => a.applicationDeadline.compareTo(b.applicationDeadline));
        break;
      case OpportunitySortOption.feeLowToHigh:
        filtered.sort((a, b) => (a.applicationFee ?? 0).compareTo(b.applicationFee ?? 0));
        break;
      case OpportunitySortOption.relevance:
        break;
    }

    return filtered;
  }

  @override
  Future<Opportunity?> getOpportunityById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _items.firstWhere((opp) => opp.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Opportunity>> getRecommendedOpportunities(CandidateProfile candidate) async {
    await Future.delayed(const Duration(milliseconds: 150));
    // Prioritize candidate's preferred categories and stream
    return _items.where((opp) {
      if (candidate.preferredCategories.contains(opp.category)) return true;
      if (candidate.stream != null) {
        final stream = candidate.stream!.toLowerCase();
        if (opp.eligibleStreams.any((s) => s.toLowerCase().contains(stream) || s.toLowerCase().contains('all disciplines'))) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  @override
  Future<List<Opportunity>> getClosingSoonOpportunities({int limit = 5}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final sorted = List<Opportunity>.from(_items)
      ..sort((a, b) => a.applicationDeadline.compareTo(b.applicationDeadline));
    return sorted.take(limit).toList();
  }

  @override
  Future<List<Opportunity>> searchOpportunities(String query) async {
    if (query.trim().isEmpty) return _items;
    final q = query.toLowerCase();
    return _items.where((opp) {
      return opp.title.toLowerCase().contains(q) ||
          opp.organisation.toLowerCase().contains(q) ||
          opp.issuingAuthority.toLowerCase().contains(q) ||
          opp.eligibleStreams.any((s) => s.toLowerCase().contains(q));
    }).toList();
  }
}
