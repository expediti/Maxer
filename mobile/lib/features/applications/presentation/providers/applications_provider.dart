import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexam/models/application_tracker.dart';
import 'package:rexam/features/opportunities/domain/opportunity.dart';
import 'package:rexam/features/auth/presentation/providers/auth_provider.dart';
import 'package:rexam/core/providers/repository_providers.dart';
import 'package:rexam/repositories/application_repository.dart';

class ApplicationsNotifier extends StateNotifier<List<ApplicationTrackerItem>> {
  final ApplicationRepository applicationRepo;
  final String candidateId;

  ApplicationsNotifier({
    required this.applicationRepo,
    required this.candidateId,
  }) : super([]) {
    loadApplications();
  }

  Future<void> loadApplications() async {
    try {
      final list = await applicationRepo.getApplications(candidateId);
      state = list;
    } catch (_) {}
  }

  ApplicationTrackerItem? getByOpportunityId(String opportunityId) {
    try {
      return state.firstWhere(
        (item) => item.examinationId == opportunityId || item.examination.id == opportunityId || item.examination.slug == opportunityId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> addOrUpdate({
    required Opportunity opportunity,
    required ApplicationStatus status,
    String? applicationNumber,
    String? notes,
    DateTime? examDate,
  }) async {
    final existingIndex = state.indexWhere(
      (item) => item.examinationId == opportunity.id || item.examination.id == opportunity.id,
    );

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

      await applicationRepo.updateApplicationStatus(existing.id, status);
      if (notes != null) {
        await applicationRepo.updateApplicationNotes(existing.id, notes);
      }
    } else {
      final newItem = ApplicationTrackerItem(
        id: 'app-tracker-${DateTime.now().millisecondsSinceEpoch}',
        examinationId: opportunity.id,
        examination: opportunity,
        status: status,
        applicationNumber: applicationNumber,
        appliedDate: DateTime.now(),
        examDate: examDate,
        personalNotes: notes,
        completedChecklist: const [],
        lastUpdated: DateTime.now(),
      );
      state = [newItem, ...state];

      await applicationRepo.createApplication(
        candidateId: candidateId,
        examinationId: opportunity.id,
        status: status,
        applicationNumber: applicationNumber,
        personalNotes: notes,
      );
    }
  }

  Future<void> updateStatus(String trackerId, ApplicationStatus newStatus) async {
    state = state.map((item) {
      if (item.id == trackerId) {
        return item.copyWith(status: newStatus, lastUpdated: DateTime.now());
      }
      return item;
    }).toList();

    await applicationRepo.updateApplicationStatus(trackerId, newStatus);
  }

  Future<void> remove(String trackerId) async {
    state = state.where((item) => item.id != trackerId).toList();
  }
}

final applicationsProvider = StateNotifierProvider<ApplicationsNotifier, List<ApplicationTrackerItem>>((ref) {
  final appRepo = ref.watch(applicationRepositoryProvider);
  final authState = ref.watch(authProvider);
  final candidateId = authState.user?.id ?? '';

  return ApplicationsNotifier(
    applicationRepo: appRepo,
    candidateId: candidateId,
  );
});
