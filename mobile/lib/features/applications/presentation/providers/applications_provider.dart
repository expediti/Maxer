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
    if (candidateId.isEmpty) {
      state = [];
      return;
    }
    try {
      final list = await applicationRepo.getApplications(candidateId);
      state = list;
    } catch (_) {}
  }

  ApplicationTrackerItem? getByOpportunityId(String opportunityId) {
    try {
      return state.firstWhere(
        (item) =>
            item.examinationId == opportunityId ||
            item.examination.id == opportunityId ||
            item.examination.slug == opportunityId,
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

  Future<void> updateStatus({
    required String examinationId,
    required ApplicationStatus status,
    String? applicationNumber,
    String? notes,
    DateTime? examDate,
  }) async {
    final existingIndex = state.indexWhere(
      (item) => item.examinationId == examinationId || item.id == examinationId,
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
      await applicationRepo.createApplication(
        candidateId: candidateId,
        examinationId: examinationId,
        status: status,
        applicationNumber: applicationNumber,
        personalNotes: notes,
      );
      await loadApplications();
    }
  }

  Future<void> remove(String idOrExamId) async {
    final item = state.firstWhere(
      (item) => item.examinationId == idOrExamId || item.id == idOrExamId,
      orElse: () => ApplicationTrackerItem(
        id: idOrExamId,
        examinationId: idOrExamId,
        examination: state.isNotEmpty ? state.first.examination : null as dynamic,
        status: ApplicationStatus.interested,
        appliedDate: DateTime.now(),
        lastUpdated: DateTime.now(),
      ),
    );

    state = state.where((i) => i.examinationId != idOrExamId && i.id != idOrExamId).toList();

    if (item.id.isNotEmpty && !item.id.startsWith('app-tracker-')) {
      await applicationRepo.deleteApplication(item.id);
    }
    if (candidateId.isNotEmpty) {
      await applicationRepo.deleteApplicationByExamId(
        candidateId: candidateId,
        examinationId: item.examinationId.isNotEmpty ? item.examinationId : idOrExamId,
      );
    }
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
