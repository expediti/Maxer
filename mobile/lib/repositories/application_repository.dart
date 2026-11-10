import 'package:flutter/foundation.dart';
import '../core/supabase_client.dart';
import '../models/application_tracker.dart';
import '../models/examination.dart';
import 'examination_repository.dart';

abstract class ApplicationRepository {
  Future<List<ApplicationTrackerItem>> getApplications(String candidateId);
  Future<void> updateApplicationStatus(String applicationId, ApplicationStatus newStatus);
  Future<void> createApplication({
    required String candidateId,
    required String examinationId,
    required ApplicationStatus status,
    String? applicationNumber,
    String? personalNotes,
  });
  Future<void> updateApplicationNotes(String applicationId, String notes);
  Future<void> toggleChecklistItem(String applicationId, String item);
}

class SupabaseApplicationRepository implements ApplicationRepository {
  final ExaminationRepository _examinationRepository;

  SupabaseApplicationRepository(this._examinationRepository);

  @override
  Future<List<ApplicationTrackerItem>> getApplications(String candidateId) async {
    final client = SupabaseConfig.client;
    if (client == null || candidateId.trim().isEmpty) {
      return [];
    }

    try {
      final res = await client
          .from('candidate_applications')
          .select('*, examinations(*, examination_dates(*), eligibility_rules(*), organisations(*))')
          .eq('candidate_id', candidateId)
          .order('updated_at', ascending: false);

      final List<ApplicationTrackerItem> items = [];
      for (final row in (res as List)) {
        final examData = row['examinations'];
        final exam = examData != null
            ? Examination.fromSupabase(examData as Map<String, dynamic>)
            : await _examinationRepository.getExaminationById(row['examination_id']?.toString() ?? '');

        if (exam == null) continue;

        final checklistRaw = row['checklist_completed'] ?? row['completed_checklist'];
        final List<String> checklist = [];
        if (checklistRaw is List) {
          checklist.addAll(checklistRaw.map((e) => e.toString()));
        }

        items.add(ApplicationTrackerItem(
          id: row['id']?.toString() ?? '',
          examinationId: row['examination_id']?.toString() ?? exam.id,
          examination: exam,
          status: ApplicationStatus.fromString(row['stage']?.toString() ?? row['status']?.toString() ?? 'applied'),
          applicationNumber: row['application_number'],
          appliedDate: row['applied_at'] != null || row['applied_date'] != null
              ? DateTime.tryParse(row['applied_at'] ?? row['applied_date']) ?? DateTime.now()
              : DateTime.now(),
          examDate: row['scheduled_exam_date'] != null
              ? DateTime.tryParse(row['scheduled_exam_date'])
              : null,
          personalNotes: row['personal_notes'] ?? row['notes'],
          completedChecklist: checklist,
          lastUpdated: row['updated_at'] != null
              ? DateTime.tryParse(row['updated_at']) ?? DateTime.now()
              : DateTime.now(),
        ));
      }

      return items;
    } catch (e) {
      debugPrint('[REXAM] Fetch applications Supabase error: $e');
      return [];
    }
  }

  @override
  Future<void> updateApplicationStatus(String applicationId, ApplicationStatus newStatus) async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      await client.from('candidate_applications').update({
        'stage': newStatus.name,
        'status': newStatus.displayName,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', applicationId);
    } catch (e) {
      debugPrint('[REXAM] Update app status error: $e');
    }
  }

  @override
  Future<void> createApplication({
    required String candidateId,
    required String examinationId,
    required ApplicationStatus status,
    String? applicationNumber,
    String? personalNotes,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null || candidateId.trim().isEmpty) return;

    try {
      await client.from('candidate_applications').upsert(
        {
          'candidate_id': candidateId,
          'examination_id': examinationId,
          'stage': status.name,
          'status': status.displayName,
          'application_number': applicationNumber,
          'personal_notes': personalNotes,
          'applied_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'candidate_id, examination_id',
      );
    } catch (e) {
      debugPrint('[REXAM] Create application error: $e');
    }
  }

  @override
  Future<void> updateApplicationNotes(String applicationId, String notes) async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      await client.from('candidate_applications').update({
        'personal_notes': notes,
        'notes': notes,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', applicationId);
    } catch (e) {
      debugPrint('[REXAM] Update app notes error: $e');
    }
  }

  @override
  Future<void> toggleChecklistItem(String applicationId, String item) async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      final res = await client
          .from('candidate_applications')
          .select('completed_checklist')
          .eq('id', applicationId)
          .maybeSingle();

      final current = List<String>.from((res?['completed_checklist'] as List?) ?? []);
      if (current.contains(item)) {
        current.remove(item);
      } else {
        current.add(item);
      }

      await client.from('candidate_applications').update({
        'completed_checklist': current,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', applicationId);
    } catch (e) {
      debugPrint('[REXAM] Toggle checklist error: $e');
    }
  }
}
