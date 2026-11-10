import 'package:rexam/models/candidate_profile.dart';
import 'package:rexam/repositories/profile_repository.dart';

abstract class CandidateRepository {
  Future<CandidateProfile?> getProfile(String candidateId);
  Future<CandidateProfile> updateProfile(CandidateProfile profile);
}

class SupabaseCandidateRepository implements CandidateRepository {
  final ProfileRepository _profileRepo = SupabaseProfileRepository();

  @override
  Future<CandidateProfile?> getProfile(String candidateId) {
    return _profileRepo.getProfile(candidateId);
  }

  @override
  Future<CandidateProfile> updateProfile(CandidateProfile profile) {
    return _profileRepo.updateProfile(profile);
  }
}
