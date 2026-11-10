import 'package:flutter/foundation.dart';
import 'package:rexam/core/services/notification_service.dart';
import 'package:rexam/core/supabase_client.dart';
import 'package:rexam/models/examination.dart';

abstract class ReminderRepository {
  Future<List<String>> getFollowedExaminationIds(String candidateId);
  Future<List<String>> getFollowedOpportunityIds(String candidateId);
  Future<bool> hasReminder(String candidateId, String examinationId);
  Future<void> enableReminder(String candidateId, Examination examination);
  Future<void> disableReminder(String candidateId, Examination examination);
}

class SupabaseReminderRepository implements ReminderRepository {
  final NotificationService _notificationService = NotificationService();

  @override
  Future<List<String>> getFollowedExaminationIds(String candidateId) async {
    final client = SupabaseConfig.client;
    if (client == null || candidateId.trim().isEmpty) return [];

    try {
      final res = await client
          .from('candidate_followed_examinations')
          .select('examination_id')
          .eq('candidate_id', candidateId);

      return (res as List)
          .map((item) => item['examination_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[REXAM Reminders] Fetch followed IDs error: $e');
      return [];
    }
  }

  @override
  Future<List<String>> getFollowedOpportunityIds(String candidateId) =>
      getFollowedExaminationIds(candidateId);

  @override
  Future<bool> hasReminder(String candidateId, String examinationId) async {
    final client = SupabaseConfig.client;
    if (client == null || candidateId.trim().isEmpty) return false;

    try {
      final res = await client
          .from('candidate_followed_examinations')
          .select('id')
          .eq('candidate_id', candidateId)
          .eq('examination_id', examinationId)
          .maybeSingle();

      return res != null;
    } catch (e) {
      debugPrint('[REXAM Reminders] Check hasReminder error: $e');
      return false;
    }
  }

  @override
  Future<void> enableReminder(String candidateId, Examination examination) async {
    final client = SupabaseConfig.client;
    if (client == null || candidateId.trim().isEmpty) return;

    try {
      // 1. Persist subscription in Supabase
      await client.from('candidate_followed_examinations').upsert(
        {
          'candidate_id': candidateId,
          'examination_id': examination.id,
          'receive_push': true,
          'receive_email': true,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'candidate_id, examination_id',
      );

      // 2. Schedule local alarms for verified dates
      await _notificationService.scheduleRemindersForExamination(examination);
      debugPrint('[REXAM Reminders] Enabled reminders for ${examination.title}');
    } catch (e) {
      debugPrint('[REXAM Reminders] Enable reminder error: $e');
    }
  }

  @override
  Future<void> disableReminder(String candidateId, Examination examination) async {
    final client = SupabaseConfig.client;
    if (client == null || candidateId.trim().isEmpty) return;

    try {
      // 1. Remove subscription from Supabase
      await client
          .from('candidate_followed_examinations')
          .delete()
          .eq('candidate_id', candidateId)
          .eq('examination_id', examination.id);

      // 2. Cancel scheduled local alarms
      await _notificationService.cancelRemindersForExamination(examination.id);
      debugPrint('[REXAM Reminders] Disabled reminders for ${examination.title}');
    } catch (e) {
      debugPrint('[REXAM Reminders] Disable reminder error: $e');
    }
  }
}
