import 'package:flutter/foundation.dart';
import '../core/supabase_client.dart';
import '../models/examination.dart';
import '../models/candidate_profile.dart';

abstract class ExaminationRepository {
  Future<List<Examination>> getExaminations({
    ExaminationCategory? category,
    bool? isCentralGovernment,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  });
  Future<Examination?> getExaminationById(String id);
  Future<List<Examination>> getRecommendedExaminations(CandidateProfile candidate);
  Future<List<Examination>> getClosingSoonExaminations({int limit = 5});
  Future<List<Examination>> searchExaminations(String query);
}

class SupabaseExaminationRepository implements ExaminationRepository {
  @override
  Future<List<Examination>> getExaminations({
    ExaminationCategory? category,
    bool? isCentralGovernment,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      debugPrint('[REXAM] Supabase client unavailable. Returning empty examination list.');
      return [];
    }

    try {
      var query = client
          .from('examinations')
          .select('*, examination_dates(*), eligibility_rules(*), organisations(*)')
          .eq('status', 'published');

      if (category != null) {
        switch (category) {
          case ExaminationCategory.scholarship:
            query = query.inFilter('category', [
              'Scholarships & Fellowships', 'Scholarships & Funding', 'scholarship', 'Scholarships', 'Scholarship'
            ]);
            break;
          case ExaminationCategory.govtRecruitment:
            query = query.inFilter('category', [
              'Government Recruitment', 'Government Examinations', 'govt_recruitment'
            ]);
            break;
          case ExaminationCategory.psu:
            query = query.inFilter('category', ['PSU Recruitment', 'psu']);
            break;
          case ExaminationCategory.stateGovt:
            query = query.inFilter('category', ['State Government Jobs', 'state_govt', 'State Government']);
            break;
          case ExaminationCategory.railway:
            query = query.inFilter('category', ['Railways', 'Railway']);
            break;
          case ExaminationCategory.banking:
            query = query.inFilter('category', ['Banking & Finance', 'Banking']);
            break;
          case ExaminationCategory.defence:
            query = query.inFilter('category', ['Defence & Police', 'defence']);
            break;
          case ExaminationCategory.research:
          case ExaminationCategory.internshipResearch:
            query = query.inFilter('category', ['Research & Science', 'Research & Internships', 'scientific']);
            break;
          case ExaminationCategory.teaching:
            query = query.inFilter('category', ['Teaching & Academia', 'teaching']);
            break;
          case ExaminationCategory.healthcare:
            query = query.inFilter('category', ['Healthcare & Medical', 'healthcare']);
            break;
          case ExaminationCategory.lawJudicial:
            query = query.inFilter('category', ['Law & Courts', 'judicial']);
            break;
          case ExaminationCategory.aviationTransport:
            query = query.inFilter('category', ['Aviation & Transport', 'aviation_maritime']);
            break;
          case ExaminationCategory.agricultureEnv:
            query = query.inFilter('category', ['Agriculture & Environment', 'agriculture']);
            break;
          case ExaminationCategory.apprenticeship:
            query = query.inFilter('category', ['Apprenticeships', 'apprenticeship']);
            break;
          case ExaminationCategory.internship:
            query = query.inFilter('category', ['Internships', 'internship', 'Research & Internships']);
            break;
          case ExaminationCategory.fellowship:
            query = query.inFilter('category', ['Fellowships', 'fellowship', 'Scholarships & Fellowships']);
            break;
          case ExaminationCategory.privateJob:
            query = query.inFilter('category', ['Private Jobs', 'Private Jobs & Graduate Programmes', 'private_sector']);
            break;
          case ExaminationCategory.admissions:
          case ExaminationCategory.entranceExam:
            query = query.inFilter('category', [
              'Entrance Examinations', 'University Admissions', 'Admissions & Entrance'
            ]);
            break;
          case ExaminationCategory.certification:
            query = query.inFilter('category', [
              'Professional Certifications', 'Professional Qualifications'
            ]);
            break;
        }
      }
      if (isCentralGovernment != null) {
        query = query.eq('is_central_government', isCentralGovernment);
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final term = searchQuery.trim();
        query = query.or('name.ilike.%$term%,title.ilike.%$term%');
      }

      final int from = (page - 1) * limit;
      final int to = from + limit - 1;
      final response = await query
          .order('last_verified_at', ascending: false)
          .range(from, to);

      return (response as List)
          .map<Examination>((item) => Examination.fromSupabase(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[REXAM] Supabase fetch error: $e');
      return [];
    }
  }

  @override
  Future<Examination?> getExaminationById(String id) async {
    final client = SupabaseConfig.client;
    if (client == null) return null;

    try {
      final res = await client
          .from('examinations')
          .select('*, examination_dates(*), eligibility_rules(*), organisations(*)')
          .or('id.eq.$id,slug.eq.$id')
          .maybeSingle();

      if (res != null) {
        return Examination.fromSupabase(res);
      }
    } catch (e) {
      debugPrint('[REXAM] Fetch examination by ID error: $e');
    }
    return null;
  }

  @override
  Future<List<Examination>> getRecommendedExaminations(CandidateProfile candidate) async {
    final all = await getExaminations(limit: 50);
    if (all.isEmpty) return [];

    return all.where((opp) {
      // 1. Preferred Category match
      if (candidate.preferredCategories.contains(opp.category)) return true;

      // 2. Stream / Branch match
      if (candidate.stream != null && candidate.stream!.isNotEmpty) {
        final streamLower = candidate.stream!.toLowerCase();
        if (opp.eligibleStreams.any((s) =>
            s.toLowerCase().contains(streamLower) ||
            s.toLowerCase().contains('all disciplines') ||
            s.toLowerCase().contains('any discipline'))) {
          return true;
        }
      }

      // 3. Highest Qualification match
      if (candidate.highestQualification != null && candidate.highestQualification!.isNotEmpty) {
        final qualLower = candidate.highestQualification!.toLowerCase();
        if (opp.educationalQualifications.any((q) => q.toLowerCase().contains(qualLower))) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  @override
  Future<List<Examination>> getClosingSoonExaminations({int limit = 5}) async {
    final all = await getExaminations(limit: 50);
    if (all.isEmpty) return [];

    final now = DateTime.now();
    final validFutureDeadlines = all.where((e) {
      if (e.applicationDeadline == null) return false;
      return e.applicationDeadline!.isAfter(now);
    }).toList()
      ..sort((a, b) => a.applicationDeadline!.compareTo(b.applicationDeadline!));

    return validFutureDeadlines.take(limit).toList();
  }

  @override
  Future<List<Examination>> searchExaminations(String query) async {
    return getExaminations(searchQuery: query);
  }
}
