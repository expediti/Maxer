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
  final Set<String> _localSaved = {
    'opp-upsc-cse-2026',
    'opp-isro-scientist-2026',
  };

  @override
  Future<List<String>> getSavedExaminationIds(String candidateId) async {
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final res = await client
            .from('saved_examinations')
            .select('examination_id')
            .eq('candidate_id', candidateId);
        final list = (res as List)
            .map((item) => item['examination_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
        return list;
      } catch (e) {
        debugPrint('[REXAM] Fetch saved IDs error: $e');
      }
    }
    return _localSaved.toList();
  }

  @override
  Future<bool> isSaved(String candidateId, String examinationId) async {
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final res = await client
            .from('saved_examinations')
            .select('id')
            .eq('candidate_id', candidateId)
            .eq('examination_id', examinationId)
            .maybeSingle();
        return res != null;
      } catch (e) {
        debugPrint('[REXAM] isSaved check error: $e');
      }
    }
    return _localSaved.contains(examinationId);
  }

  @override
  Future<void> saveExamination(
    String candidateId,
    String examinationId, {
    String? notes,
  }) async {
    _localSaved.add(examinationId);
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.from('saved_examinations').upsert({
          'candidate_id': candidateId,
          'examination_id': examinationId,
          'notes': notes,
          'saved_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (e) {
        debugPrint('[REXAM] Save examination Supabase error: $e');
      }
    }
  }

  @override
  Future<void> unsaveExamination(String candidateId, String examinationId) async {
    _localSaved.remove(examinationId);
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client
            .from('saved_examinations')
            .delete()
            .eq('candidate_id', candidateId)
            .eq('examination_id', examinationId);
      } catch (e) {
        debugPrint('[REXAM] Unsave examination Supabase error: $e');
      }
    }
  }

  @override
  Future<List<Examination>> getSavedExaminations(
    String candidateId,
    ExaminationRepository examRepo,
  ) async {
    final ids = await getSavedExaminationIds(candidateId);
    final List<Examination> results = [];
    for (final id in ids) {
      final exam = await examRepo.getExaminationById(id);
      if (exam != null) {
        results.add(exam);
      }
    }
    return results;
  }
}

