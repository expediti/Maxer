import 'package:flutter_test/flutter_test.dart';
import 'package:rexam/models/candidate_profile.dart';
import 'package:rexam/models/examination.dart';
import 'package:rexam/repositories/examination_repository.dart';
import 'package:rexam/repositories/saved_repository.dart';
import 'package:rexam/repositories/application_repository.dart';
import 'package:rexam/repositories/notification_repository.dart';
import 'package:rexam/repositories/eligibility_repository.dart';

void main() {
  group('Deterministic Eligibility Evaluation Tests', () {
    final eligibilityRepo = DeterministicEligibilityRepository();

    test('Candidate within age and stream criteria gets eligible status', () async {
      final candidate = CandidateProfile(
        id: 'cand-1',
        email: 'test@example.com',
        fullName: 'Test Candidate',
        dateOfBirth: DateTime(1998, 5, 10), // ~27-28 years old
        socialCategory: 'General',
        highestQualification: 'B.Tech',
        degreeName: 'Bachelor of Technology',
        stream: 'Computer Science',
        cgpaOrPercentage: 75.0,
        hasActiveBacklogs: false,
      );

      const exam = Examination(
        id: 'exam-1',
        title: 'Scientist / Engineer SC (CS)',
        organisation: 'ISRO',
        category: ExaminationCategory.psu,
        minAge: 18,
        maxAge: 28,
        educationalQualifications: ['B.Tech in Computer Science'],
        eligibleStreams: ['Computer Science', 'Information Technology'],
        minPercentage: 65.0,
      );

      final report = await eligibilityRepo.evaluateEligibility(
        candidate: candidate,
        examination: exam,
      );

      expect(report.overallStatus, EligibilityStatus.eligible);
      expect(report.criteriaResults.any((c) => c.criterionName == 'Age Limit'), isTrue);
      expect(report.criteriaResults.any((c) => c.criterionName == 'Educational Qualification & Stream'), isTrue);
      expect(report.criteriaResults.any((c) => c.criterionName == 'Minimum Aggregate Marks'), isTrue);
    });

    test('OBC-NCL candidate gets 3 years age relaxation applied', () async {
      final candidate = CandidateProfile(
        id: 'cand-2',
        email: 'obc@example.com',
        dateOfBirth: DateTime(1996, 2, 1), // ~30 years old
        socialCategory: 'OBC-NCL',
        highestQualification: 'B.Tech',
        stream: 'Computer Science',
        cgpaOrPercentage: 70.0,
      );

      const exam = Examination(
        id: 'exam-2',
        title: 'Scientist / Engineer SC',
        organisation: 'ISRO',
        category: ExaminationCategory.psu,
        minAge: 18,
        maxAge: 28, // Standard max is 28, relaxed max is 31
        eligibleStreams: ['Computer Science'],
      );

      final report = await eligibilityRepo.evaluateEligibility(
        candidate: candidate,
        examination: exam,
      );

      expect(report.overallStatus, EligibilityStatus.eligible);
      expect(report.applicableRelaxations.any((r) => r.contains('OBC-NCL')), isTrue);
    });

    test('Candidate with active backlogs is marked not eligible', () async {
      final candidate = CandidateProfile(
        id: 'cand-3',
        email: 'backlog@example.com',
        dateOfBirth: DateTime(2000, 1, 1),
        socialCategory: 'General',
        highestQualification: 'B.Tech',
        stream: 'Computer Science',
        hasActiveBacklogs: true,
      );

      const exam = Examination(
        id: 'exam-3',
        title: 'Assistant Section Officer',
        organisation: 'SSC',
        category: ExaminationCategory.govtRecruitment,
        minAge: 18,
        maxAge: 30,
      );

      final report = await eligibilityRepo.evaluateEligibility(
        candidate: candidate,
        examination: exam,
      );

      expect(report.overallStatus, EligibilityStatus.notEligible);
      final backlogCheck = report.criteriaResults.firstWhere((c) => c.criterionName == 'Backlog Status');
      expect(backlogCheck.status.label, 'Not Satisfied');
    });
  });

  group('Supabase Repositories Fallback & Operations', () {
    final examRepo = SupabaseExaminationRepository();
    final savedRepo = SupabaseSavedRepository();
    final appRepo = SupabaseApplicationRepository(examRepo);
    final notifRepo = SupabaseNotificationRepository();

    test('ExaminationRepository returns fallback examinations', () async {
      final exams = await examRepo.getExaminations();
      expect(exams.isNotEmpty, isTrue);
      expect(exams.first.title.isNotEmpty, isTrue);
    });

    test('SavedRepository supports saving and checking saved status', () async {
      const candidateId = 'cand-test-123';
      const examId = 'opp-upsc-cse-2026';

      await savedRepo.saveExamination(candidateId, examId);
      final isSaved = await savedRepo.isSaved(candidateId, examId);
      expect(isSaved, isTrue);

      await savedRepo.unsaveExamination(candidateId, examId);
      final isStillSaved = await savedRepo.isSaved(candidateId, examId);
      expect(isStillSaved, isFalse);
    });

    test('ApplicationRepository returns applications and allows status updates', () async {
      final apps = await appRepo.getApplications('candidate-rexam-001');
      expect(apps.isNotEmpty, isTrue);

      final firstAppId = apps.first.id;
      await appRepo.toggleChecklistItem(firstAppId, 'Custom Certificate Check');
      final updatedApps = await appRepo.getApplications('candidate-rexam-001');
      final targetApp = updatedApps.firstWhere((a) => a.id == firstAppId);
      expect(targetApp.completedChecklist.contains('Custom Certificate Check'), isTrue);
    });

    test('NotificationRepository retrieves alerts and calculates unread count', () async {
      final notifs = await notifRepo.getNotifications('candidate-rexam-001');
      expect(notifs.isNotEmpty, isTrue);

      final initialUnread = await notifRepo.getUnreadCount('candidate-rexam-001');
      expect(initialUnread >= 0, isTrue);

      await notifRepo.markAllAsRead('candidate-rexam-001');
      final countAfterMarkAll = await notifRepo.getUnreadCount('candidate-rexam-001');
      expect(countAfterMarkAll, 0);
    });
  });
}

