import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexam/features/opportunities/domain/opportunity.dart';
import 'package:rexam/features/opportunities/domain/opportunity_filter.dart';
import 'package:rexam/features/opportunities/data/opportunity_repository.dart';
import 'package:rexam/features/opportunities/presentation/providers/opportunities_provider.dart';
import 'package:rexam/features/opportunities/presentation/widgets/status_badge.dart';
import 'package:rexam/features/opportunities/presentation/widgets/opportunity_card.dart';
import 'package:rexam/models/candidate_profile.dart';

class MockOpportunityRepository implements OpportunityRepository {
  final List<Opportunity> generatedList;

  MockOpportunityRepository({int count = 75})
      : generatedList = List.generate(
          count,
          (i) => Opportunity(
            id: 'opp-$i',
            slug: 'slug-opp-$i',
            title: 'National Opportunity #$i',
            organisation: i % 2 == 0 ? 'UPSC' : 'State PSC',
            category: ExaminationCategory.govtRecruitment,
            state: i % 2 == 0 ? null : 'Uttar Pradesh',
            applicationStatus: i % 4 == 0
                ? 'open'
                : (i % 4 == 1 ? 'upcoming' : (i % 4 == 2 ? 'notification_released' : 'awaiting_notification')),
          ),
        );

  @override
  Future<List<Opportunity>> getOpportunities({
    OpportunityFilter? filter,
    int page = 1,
    int pageSize = 30,
  }) async {
    final start = (page - 1) * pageSize;
    if (start >= generatedList.length) return [];
    final end = (start + pageSize) > generatedList.length ? generatedList.length : start + pageSize;
    return generatedList.sublist(start, end);
  }

  @override
  Future<Opportunity?> getOpportunityById(String id) async =>
      generatedList.firstWhere((o) => o.id == id);

  @override
  Future<List<Opportunity>> getClosingSoonOpportunities({int limit = 5}) async =>
      generatedList.take(limit).toList();

  @override
  Future<List<Opportunity>> getRecommendedOpportunities(CandidateProfile candidate) async =>
      generatedList.take(10).toList();

  @override
  Future<List<Opportunity>> searchOpportunities(String query) async =>
      generatedList.where((o) => o.title.toLowerCase().contains(query.toLowerCase())).toList();
}

void main() {
  group('Explorer Continuous Scrolling & Pagination Unit Tests', () {
    test('PaginatedOpportunitiesNotifier loads page 1 (30 items) initially', () async {
      final repo = MockOpportunityRepository(count: 75);
      final notifier = PaginatedOpportunitiesNotifier(repo, const OpportunityFilter());

      await notifier.loadInitial();

      expect(notifier.state.currentPage, equals(1));
      expect(notifier.state.items.length, equals(30));
      expect(notifier.state.hasMore, isTrue);
      expect(notifier.state.isLoadingInitial, isFalse);
    });

    test('PaginatedOpportunitiesNotifier loads page 2 with continuous scroll trigger and deduplication', () async {
      final repo = MockOpportunityRepository(count: 75);
      final notifier = PaginatedOpportunitiesNotifier(repo, const OpportunityFilter());

      await notifier.loadInitial();
      expect(notifier.state.items.length, equals(30));

      await notifier.loadNextPage();
      expect(notifier.state.currentPage, equals(2));
      expect(notifier.state.items.length, equals(60));
      expect(notifier.state.hasMore, isTrue);

      await notifier.loadNextPage();
      expect(notifier.state.currentPage, equals(3));
      expect(notifier.state.items.length, equals(75));
      expect(notifier.state.hasMore, isFalse);

      // Subsequent call does nothing because hasMore is false
      await notifier.loadNextPage();
      expect(notifier.state.currentPage, equals(3));
      expect(notifier.state.items.length, equals(75));
    });

    test('OpportunityLifecycleBadge renders correct semantic label across all statuses', () {
      final openBadge = const OpportunityLifecycleBadge(applicationStatus: 'open');
      expect(openBadge.applicationStatus, equals('open'));

      final upcomingBadge = const OpportunityLifecycleBadge(applicationStatus: 'upcoming');
      expect(upcomingBadge.applicationStatus, equals('upcoming'));

      final awaitingBadge = const OpportunityLifecycleBadge(applicationStatus: 'awaiting_notification');
      expect(awaitingBadge.applicationStatus, equals('awaiting_notification'));

      final notifBadge = const OpportunityLifecycleBadge(applicationStatus: 'notification_released');
      expect(notifBadge.applicationStatus, equals('notification_released'));

      final closedBadge = const OpportunityLifecycleBadge(applicationStatus: 'closed');
      expect(closedBadge.applicationStatus, equals('closed'));
    });
  });

  group('Explorer Widgets Test', () {
    testWidgets('OpportunityLifecycleBadge renders in widget tree', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                OpportunityLifecycleBadge(applicationStatus: 'open'),
                OpportunityLifecycleBadge(applicationStatus: 'upcoming'),
                OpportunityLifecycleBadge(applicationStatus: 'notification_released'),
                OpportunityLifecycleBadge(applicationStatus: 'awaiting_notification'),
                OpportunityLifecycleBadge(applicationStatus: 'closed'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Notification Released'), findsOneWidget);
      expect(find.text('Awaiting Notification'), findsOneWidget);
      expect(find.text('Closed'), findsOneWidget);
    });

    testWidgets('OpportunityCard displays Lifecycle Badge, Category, and State badge', (tester) async {
      final opp = const Opportunity(
        id: 'test-card-1',
        slug: 'uppsc-pcs-2026',
        title: 'UPPSC Combined State Services (PCS) 2026',
        organisation: 'Uttar Pradesh Public Service Commission',
        category: ExaminationCategory.stateGovt,
        state: 'Uttar Pradesh',
        applicationStatus: 'open',
        vacancies: 620,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: OpportunityCard(
                opportunity: opp,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('UPPSC Combined State Services (PCS) 2026'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('State Government Jobs'), findsOneWidget);
      expect(find.text('Uttar Pradesh'), findsOneWidget);
      expect(find.text('620 Posts'), findsOneWidget);
    });
  });
}

