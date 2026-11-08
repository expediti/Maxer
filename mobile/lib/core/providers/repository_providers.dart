import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/examination_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/saved_repository.dart';
import '../../repositories/application_repository.dart';
import '../../repositories/notification_repository.dart';
import '../../repositories/eligibility_repository.dart';
import '../../services/supabase_auth_service.dart';

// Repositories
final examinationRepositoryProvider = Provider<ExaminationRepository>((ref) {
  return SupabaseExaminationRepository();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository();
});

final savedRepositoryProvider = Provider<SavedRepository>((ref) {
  return SupabaseSavedRepository();
});

final applicationRepositoryProvider = Provider<ApplicationRepository>((ref) {
  final examRepo = ref.watch(examinationRepositoryProvider);
  return SupabaseApplicationRepository(examRepo);
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return SupabaseNotificationRepository();
});

final eligibilityRepositoryProvider = Provider<EligibilityRepository>((ref) {
  return DeterministicEligibilityRepository();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return SupabaseAuthService();
});

