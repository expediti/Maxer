import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexam/features/opportunities/domain/opportunity.dart';
import 'package:rexam/features/auth/presentation/providers/auth_provider.dart';
import 'package:rexam/core/providers/repository_providers.dart';
import 'package:rexam/repositories/saved_repository.dart';
import 'package:rexam/repositories/examination_repository.dart';

class SavedNotifier extends StateNotifier<List<Opportunity>> {
  final SavedRepository savedRepo;
  final ExaminationRepository examRepo;
  final String candidateId;

  SavedNotifier({
    required this.savedRepo,
    required this.examRepo,
    required this.candidateId,
  }) : super([]) {
    loadSaved();
  }

  Future<void> loadSaved() async {
    try {
      final list = await savedRepo.getSavedExaminations(candidateId, examRepo);
      state = list;
    } catch (_) {}
  }

  bool isSaved(String opportunityId) {
    return state.any((opp) => opp.id == opportunityId || opp.slug == opportunityId);
  }

  Future<void> toggleSave(Opportunity opportunity) async {
    if (isSaved(opportunity.id)) {
      await remove(opportunity.id);
    } else {
      state = [...state, opportunity];
      await savedRepo.saveExamination(candidateId, opportunity.id);
    }
  }

  Future<void> remove(String opportunityId) async {
    state = state.where((opp) => opp.id != opportunityId && opp.slug != opportunityId).toList();
    await savedRepo.unsaveExamination(candidateId, opportunityId);
  }

  void sortByDeadline() {
    final list = [...state]
      ..sort((a, b) {
        if (a.applicationDeadline == null) return 1;
        if (b.applicationDeadline == null) return -1;
        return a.applicationDeadline!.compareTo(b.applicationDeadline!);
      });
    state = list;
  }

  void sortByLatest() {
    final list = [...state]
      ..sort((a, b) {
        final aTime = a.lastVerifiedAt ?? DateTime(2026);
        final bTime = b.lastVerifiedAt ?? DateTime(2026);
        return bTime.compareTo(aTime);
      });
    state = list;
  }
}

final savedProvider = StateNotifierProvider<SavedNotifier, List<Opportunity>>((ref) {
  final savedRepo = ref.watch(savedRepositoryProvider);
  final examRepo = ref.watch(examinationRepositoryProvider);
  final authState = ref.watch(authProvider);
  final candidateId = authState.user?.id ?? 'candidate-rexam-001';

  return SavedNotifier(
    savedRepo: savedRepo,
    examRepo: examRepo,
    candidateId: candidateId,
  );
});
