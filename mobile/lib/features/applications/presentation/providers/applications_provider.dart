import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexam/features/applications/domain/application_tracker.dart';
import 'package:rexam/features/opportunities/domain/opportunity.dart';
import 'package:rexam/features/opportunities/data/mock_opportunities_data.dart';

class ApplicationsNotifier extends StateNotifier<List<ApplicationTrackerItem>> {
  ApplicationsNotifier()
      : super([
          ApplicationTrackerItem(
            id: 'app-tracker-001',
            opportunityId: mockOpportunities[0].id,
            opportunity: mockOpportunities[0],
            status: ApplicationStatus.applied,
            applicationNumber: 'UPSC-2026-948201',
            appliedDate: DateTime(2026, 2, 18),
            examDate: DateTime(2026, 5, 25),
            personalNotes: 'OTR completed. Exam center: Delhi Central (Centre code: 08).',
            completedChecklist: [
              'Government Photo ID Uploaded',
              'Class 10th Certificate Submitted',
              'Application Fee Paid (₹100)',
            ],
            lastUpdated: DateTime(2026, 2, 18, 14, 20),
          ),
          ApplicationTrackerItem(
            id: 'app-tracker-002',
            opportunityId: mockOpportunities[1].id,
            opportunity: mockOpportunities[1],
            status: ApplicationStatus.preparingDocuments,
            applicationNumber: null,
            appliedDate: DateTime(2026, 2, 25),
            examDate: DateTime(2026, 5, 10),
            personalNotes: 'Need to get degree conversion certificate from DTU administration.',
            completedChecklist: [
              'Resume Drafted',
            ],
            lastUpdated: DateTime(2026, 3, 1, 10, 0),
          ),
          ApplicationTrackerItem(
            id: 'app-tracker-003',
            opportunityId: mockOpportunities[3].id,
            opportunity: mockOpportunities[3],
            status: ApplicationStatus.interested,
            applicationNumber: null,
            appliedDate: DateTime(2026, 3, 2),
            examDate: null,
            personalNotes: 'GATE scorecard verified (Score: 682, valid till 2028).',
            completedChecklist: [],
            lastUpdated: DateTime(2026, 3, 2, 16, 45),
          ),
        ]);

  ApplicationTrackerItem? getByOpportunityId(String opportunityId) {
    try {
      return state.firstWhere((item) => item.opportunityId == opportunityId);
    } catch (_) {
      return null;
    }
  }

  void addOrUpdate({
    required Opportunity opportunity,
    required ApplicationStatus status,
    String? applicationNumber,
    String? notes,
    DateTime? examDate,
  }) {
    final existingIndex = state.indexWhere((item) => item.opportunityId == opportunity.id);

    if (existingIndex >= 0) {
      final existing = state[existingIndex];
      final updated = existing.copyWith(
        status: status,
        applicationNumber: applicationNumber ?? existing.applicationNumber,
        personalNotes: notes ?? existing.personalNotes,
        examDate: examDate ?? existing.examDate,
        lastUpdated: DateTime.now(),
      );
      final list = [...state];
      list[existingIndex] = updated;
      state = list;
    } else {
      final newItem = ApplicationTrackerItem(
        id: 'app-tracker-${DateTime.now().millisecondsSinceEpoch}',
        opportunityId: opportunity.id,
        opportunity: opportunity,
        status: status,
        applicationNumber: applicationNumber,
        appliedDate: DateTime.now(),
        examDate: examDate,
        personalNotes: notes,
        completedChecklist: const [],
        lastUpdated: DateTime.now(),
      );
      state = [newItem, ...state];
    }
  }

  void updateStatus(String trackerId, ApplicationStatus newStatus) {
    state = state.map((item) {
      if (item.id == trackerId) {
        return item.copyWith(status: newStatus, lastUpdated: DateTime.now());
      }
      return item;
    }).toList();
  }

  void remove(String trackerId) {
    state = state.where((item) => item.id != trackerId).toList();
  }
}

final applicationsProvider =
    StateNotifierProvider<ApplicationsNotifier, List<ApplicationTrackerItem>>((ref) {
  return ApplicationsNotifier();
});
