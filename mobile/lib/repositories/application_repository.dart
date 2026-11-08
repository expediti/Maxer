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

  final List<ApplicationTrackerItem> _fallbackApplications = [
    ApplicationTrackerItem(
      id: 'app-upsc-001',
      examinationId: 'opp-upsc-cse-2026',
      examination: const Examination(
        id: 'opp-upsc-cse-2026',
        title: 'Civil Services Examination (Preliminary) 2026',
        organisation: 'Union Public Service Commission (UPSC)',
        issuingAuthority: 'Department of Personnel and Training (DoPT)',
        category: ExaminationCategory.govtRecruitment,
        overview: 'Recruitment to IAS, IFS, IPS, and Central Group A & B services.',
        vacancies: 1056,
        eligibilityCriteriaSummary: 'Degree of any recognized university. Age 21 to 32 years.',
        applicationDeadline: null,
      ),
      status: ApplicationStatus.readyToApply,
      applicationNumber: 'UPSC-2026-883921',
      appliedDate: DateTime(2026, 2, 20),
      examDate: DateTime(2026, 5, 25),
      personalNotes: 'OTR profile already updated. Need to verify exam center choice.',
      completedChecklist: [
        'OTR Registration Completed',
        'Photo & Signature Uploaded',
        'Valid ID Document Linked',
      ],
      lastUpdated: DateTime(2026, 2, 20, 14, 0),
    ),
    ApplicationTrackerItem(
      id: 'app-isro-002',
      examinationId: 'opp-isro-scientist-2026',
      examination: const Examination(
        id: 'opp-isro-scientist-2026',
        title: 'Recruitment of Scientist/Engineer "SC" (Computer Science)',
        organisation: 'Indian Space Research Organisation (ISRO)',
        issuingAuthority: 'Department of Space',
        category: ExaminationCategory.psu,
        overview: 'Scientist/Engineer posts in Group A Gazetted cadre.',
        vacancies: 320,
        eligibilityCriteriaSummary: 'B.E. / B.Tech in CS with min 65% aggregate or 6.84 CGPA.',
        applicationDeadline: null,
      ),
      status: ApplicationStatus.preparingDocuments,
      applicationNumber: null,
      appliedDate: DateTime(2026, 2, 22),
      examDate: DateTime(2026, 6, 14),
      personalNotes: 'Awaiting final consolidated degree certificate from university.',
      completedChecklist: [
        'Degree Certificate Scan',
      ],
      lastUpdated: DateTime(2026, 2, 22, 11, 30),
    ),
  ];

  @override
  Future<List<ApplicationTrackerItem>> getApplications(String candidateId) async {
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final res = await client
            .from('candidate_applications')
            .select()
            .eq('candidate_id', candidateId)
            .order('updated_at', ascending: false);

        final List<ApplicationTrackerItem> items = [];
        for (final row in (res as List)) {
          final examId = row['examination_id']?.toString() ?? '';
          final exam = await _examinationRepository.getExaminationById(examId) ??
              Examination(
                id: examId,
                title: 'Tracked Examination',
                organisation: 'Official Recruiting Body',
                issuingAuthority: 'Government of India',
                category: ExaminationCategory.govtRecruitment,
                overview: '',
                eligibilityCriteriaSummary: '',
              );

          final checklistRaw = row['checklist_completed'];
          List<String> checklist = [];
          if (checklistRaw is List) {
            checklist = checklistRaw.map((e) => e.toString()).toList();
          }

          items.add(ApplicationTrackerItem(
            id: row['id']?.toString() ?? UniqueKey().toString(),
            examinationId: examId,
            examination: exam,
            status: ApplicationStatus.fromString(row['stage']?.toString() ?? 'applied'),
            applicationNumber: row['application_number'],
            appliedDate: row['applied_at'] != null
                ? DateTime.tryParse(row['applied_at']) ?? DateTime.now()
                : DateTime.now(),
            examDate: null,
            personalNotes: row['notes'],
            completedChecklist: checklist,
            lastUpdated: row['updated_at'] != null
                ? DateTime.tryParse(row['updated_at']) ?? DateTime.now()
                : DateTime.now(),
          ));
        }

        if (items.isNotEmpty) return items;
      } catch (e) {
        debugPrint('[REXAM] Fetch applications Supabase error: $e');
      }
    }
    return _fallbackApplications;
  }

  @override
  Future<void> updateApplicationStatus(String applicationId, ApplicationStatus newStatus) async {
    final idx = _fallbackApplications.indexWhere((a) => a.id == applicationId);
    if (idx != -1) {
      _fallbackApplications[idx] = _fallbackApplications[idx].copyWith(
        status: newStatus,
        lastUpdated: DateTime.now(),
      );
    }

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.from('candidate_applications').update({
          'stage': newStatus.name,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', applicationId);
      } catch (e) {
        debugPrint('[REXAM] Update app status error: $e');
      }
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
    final exam = await _examinationRepository.getExaminationById(examinationId);
    if (exam != null) {
      _fallbackApplications.insert(
        0,
        ApplicationTrackerItem(
          id: 'app-${DateTime.now().millisecondsSinceEpoch}',
          examinationId: examinationId,
          examination: exam,
          status: status,
          applicationNumber: applicationNumber,
          appliedDate: DateTime.now(),
          personalNotes: personalNotes,
          completedChecklist: const [],
          lastUpdated: DateTime.now(),
        ),
      );
    }

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.from('candidate_applications').insert({
          'candidate_id': candidateId,
          'examination_id': examinationId,
          'stage': status.name,
          'application_number': applicationNumber,
          'notes': personalNotes,
          'applied_at': DateTime.now().toUtc().toIso8601String(),
          'checklist_completed': [],
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (e) {
        debugPrint('[REXAM] Create application error: $e');
      }
    }
  }

  @override
  Future<void> updateApplicationNotes(String applicationId, String notes) async {
    final idx = _fallbackApplications.indexWhere((a) => a.id == applicationId);
    if (idx != -1) {
      _fallbackApplications[idx] = _fallbackApplications[idx].copyWith(
        personalNotes: notes,
        lastUpdated: DateTime.now(),
      );
    }

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.from('candidate_applications').update({
          'notes': notes,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', applicationId);
      } catch (e) {
        debugPrint('[REXAM] Update notes error: $e');
      }
    }
  }

  @override
  Future<void> toggleChecklistItem(String applicationId, String item) async {
    final idx = _fallbackApplications.indexWhere((a) => a.id == applicationId);
    if (idx != -1) {
      final current = List<String>.from(_fallbackApplications[idx].completedChecklist);
      if (current.contains(item)) {
        current.remove(item);
      } else {
        current.add(item);
      }
      _fallbackApplications[idx] = _fallbackApplications[idx].copyWith(
        completedChecklist: current,
        lastUpdated: DateTime.now(),
      );

      final client = SupabaseConfig.client;
      if (client != null) {
        try {
          await client.from('candidate_applications').update({
            'checklist_completed': current,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }).eq('id', applicationId);
        } catch (e) {
          debugPrint('[REXAM] Toggle checklist error: $e');
        }
      }
    }
  }
}

