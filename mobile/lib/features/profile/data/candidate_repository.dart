import 'dart:typed_data';
import 'package:rexam/models/candidate_profile.dart';
import 'package:rexam/repositories/profile_repository.dart';

abstract class CandidateRepository {
  Future<CandidateProfile?> getProfile(String candidateId);
  Future<CandidateProfile> updateProfile(CandidateProfile profile);
  Future<String?> uploadAvatar({required String candidateId, required Uint8List bytes, String fileExtension = 'png'});
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

  @override
  Future<String?> uploadAvatar({required String candidateId, required Uint8List bytes, String fileExtension = 'png'}) {
    return _profileRepo.uploadAvatar(candidateId: candidateId, bytes: bytes, fileExtension: fileExtension);
  }
}
