import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexam/features/auth/presentation/providers/auth_provider.dart';
import 'package:rexam/models/examination.dart';
import 'package:rexam/features/reminders/data/reminder_repository.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return SupabaseReminderRepository();
});

class RemindersNotifier extends StateNotifier<Set<String>> {
  final ReminderRepository _repository;
  final String? _candidateId;

  RemindersNotifier({
    required ReminderRepository repository,
    required String? candidateId,
  })  : _repository = repository,
        _candidateId = candidateId,
        super(<String>{}) {
    loadReminders();
  }

  Future<void> loadReminders() async {
    if (_candidateId == null || _candidateId.isEmpty) {
      state = <String>{};
      return;
    }

    try {
      final ids = await _repository.getFollowedExaminationIds(_candidateId);
      state = ids.toSet();
    } catch (_) {}
  }

  Future<void> toggleReminder(Examination examination) async {
    if (_candidateId == null || _candidateId.isEmpty) return;

    final isCurrentlySubscribed = state.contains(examination.id);

    if (isCurrentlySubscribed) {
      state = {...state}..remove(examination.id);
      await _repository.disableReminder(_candidateId, examination);
    } else {
      state = {...state, examination.id};
      await _repository.enableReminder(_candidateId, examination);
    }
  }

  bool isReminded(String examinationId) {
    return state.contains(examinationId);
  }
}

final remindersProvider = StateNotifierProvider<RemindersNotifier, Set<String>>((ref) {
  final authState = ref.watch(authProvider);
  final repo = ref.watch(reminderRepositoryProvider);
  return RemindersNotifier(repository: repo, candidateId: authState.user?.id);
});
