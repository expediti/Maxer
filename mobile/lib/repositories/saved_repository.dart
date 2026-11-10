import 'package:flutter/foundation.dart';
import '../core/supabase_client.dart';
import '../models/examination.dart';
import 'examination_repository.dart';

abstract class SavedRepository {
  Future<List<String>> getSavedExaminationIds(String candidateId);
  Future<bool> isSaved(String candidateId, String examinationId);
  Future<void> saveExamination(String candidateId, String examinationId, {String? notes});
  Future<void> unsaveExamination(String candidateId, String examinationId);
  Future<List<Examination>> getSavedExaminations(String candidateId, ExaminationRepository examRepo);
}

class SupabaseSavedRepository implements SavedRepository {
  @override
  Future<List<String>> getSavedExaminationIds(String candidateId) async {
    final client = SupabaseConfig.client;
    if (client == null || candidateId.trim().isEmpty) {
      return [];
    }

    try {
      final res = await client
          .from('saved_examinations')
          .select('examination_id')
          .eq('candidate_id', candidateId);

      return (res as List)
          .map((item) => item['examination_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[REXAM] Fetch saved IDs error: $e');
      return [];
    }
  }

  @override
  Future<bool> isSaved(String candidateId, String examinationId) async {
    final client = SupabaseConfig.client;
    if (client == null || candidateId.trim().isEmpty) return false;

    try {
      final res = await client
          .from('saved_examinations')
          .select('id')
          .eq('candidate_id', candidateId)
          .eq('examination_id', examinationId)
          .maybeSingle();

      return res != null;
    } catch (e) {
      debugPrint('[REXAM] Check isSaved error: $e');
      return false;
    }
  }

  @override
  Future<void> saveExamination(String candidateId, String examinationId, {String? notes}) async {
    final client = SupabaseConfig.client;
    if (client == null || candidateId.trim().isEmpty) return;

    try {
      await client.from('saved_examinations').upsert(
        {
          'candidate_id': candidateId,
          'examination_id': examinationId,
          'notes': notes,
          'saved_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'candidate_id, examination_id',
      );
    } catch (e) {
      debugPrint('[REXAM] Save examination error: $e');
    }
  }

  @override
  Future<void> unsaveExamination(String candidateId, String examinationId) async {
    final client = SupabaseConfig.client;
    if (client == null || candidateId.trim().isEmpty) return;

    try {
      await client
          .from('saved_examinations')
          .delete()
          .eq('candidate_id', candidateId)
          .eq('examination_id', examinationId);
    } catch (e) {
      debugPrint('[REXAM] Unsave examination error: $e');
    }
  }

  @override
  Future<List<Examination>> getSavedExaminations(String candidateId, ExaminationRepository examRepo) async {
    final client = SupabaseConfig.client;
    if (client == null || candidateId.trim().isEmpty) {
      return [];
    }

    try {
      final res = await client
          .from('saved_examinations')
          .select('*, examinations(*, examination_dates(*), eligibility_rules(*), organisations(*))')
          .eq('candidate_id', candidateId)
          .order('saved_at', ascending: false);

      final List<Examination> items = [];
      for (final row in (res as List)) {
        final examData = row['examinations'];
        if (examData != null) {
          items.add(Examination.fromSupabase(examData as Map<String, dynamic>));
        } else if (row['examination_id'] != null) {
          final fetched = await examRepo.getExaminationById(row['examination_id'].toString());
          if (fetched != null) items.add(fetched);
        }
      }
      return items;
    } catch (e) {
      debugPrint('[REXAM] Fetch saved examinations error: $e');
      return [];
    }
  }
}
