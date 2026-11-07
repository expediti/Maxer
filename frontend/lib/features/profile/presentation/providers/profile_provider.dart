import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexam/features/profile/domain/candidate_profile.dart';
import 'package:rexam/features/profile/data/candidate_repository.dart';

final candidateRepositoryProvider = Provider<CandidateRepository>((ref) {
  return MockCandidateRepository();
});

class ProfileNotifier extends StateNotifier<AsyncValue<CandidateProfile>> {
  final CandidateRepository _repository;

  ProfileNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.getProfile('candidate-rexam-001');
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile(CandidateProfile updated) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.updateProfile(updated);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void updateLocal(CandidateProfile updated) {
    state = AsyncValue.data(updated);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<CandidateProfile>>((ref) {
  final repo = ref.watch(candidateRepositoryProvider);
  return ProfileNotifier(repo);
});
