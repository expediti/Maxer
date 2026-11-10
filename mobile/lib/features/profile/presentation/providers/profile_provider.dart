import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexam/models/candidate_profile.dart';
import 'package:rexam/features/auth/presentation/providers/auth_provider.dart';
import '../../data/candidate_repository.dart';

final candidateRepositoryProvider = Provider<CandidateRepository>((ref) {
  return SupabaseCandidateRepository();
});

class ProfileNotifier extends StateNotifier<AsyncValue<CandidateProfile>> {
  final CandidateRepository _repository;
  final String _candidateId;

  ProfileNotifier(this._repository, this._candidateId) : super(const AsyncValue.loading()) {
    if (_candidateId.isNotEmpty) {
      loadProfile();
    } else {
      state = AsyncValue.error('User is not authenticated.', StackTrace.empty);
    }
  }

  Future<void> loadProfile() async {
    if (_candidateId.isEmpty) return;
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.getProfile(_candidateId);
      if (profile != null) {
        state = AsyncValue.data(profile);
      } else {
        state = AsyncValue.error('Profile not initialized. Please complete onboarding.', StackTrace.empty);
      }
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
  final authState = ref.watch(authProvider);
  final candidateId = authState.user?.id ?? '';
  return ProfileNotifier(repo, candidateId);
});
