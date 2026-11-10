import 'package:flutter_test/flutter_test.dart';
import 'package:rexam/models/candidate_profile.dart';
import 'package:rexam/models/examination.dart';
import 'package:rexam/models/application_tracker.dart';
import 'package:rexam/models/notification_item.dart';
import 'package:rexam/repositories/examination_repository.dart';
import 'package:rexam/repositories/saved_repository.dart';
import 'package:rexam/repositories/application_repository.dart';
import 'package:rexam/repositories/notification_repository.dart';
import 'package:rexam/repositories/eligibility_repository.dart';
import 'package:rexam/models/eligibility_report.dart';

// Test Fixtures isolated exclusively to automated tests (Never in production code)
class TestExaminationRepository implements ExaminationRepository {
  final List<Examination> _testExams = [
    const Examination(
      id: 'test-exam-1',
      title: 'Civil Services Examination (Preliminary) 2026',
      organisation: 'UPSC',
      category: ExaminationCategory.govtRecruitment,
      minAge: 21,
      maxAge: 32,
      educationalQualifications: ['Bachelor Degree in any discipline'],
    ),
  ];

  @override
  Future<List<Examination>> getExaminations({
    ExaminationCategory? category,
    bool? isCentralGovernment,
    String? searchQuery,
    String? state,
    String? qualification,
    String? applicationStatus,
    String? organisation,
    int page = 1,
    int limit = 30,
  }) async => _testExams;

  @override
  Future<Examination?> getExaminationById(String id) async => _testExams.first;

  @override
  Future<List<Examination>> getClosingSoonExaminations({int limit = 5}) async => _testExams;

  @override
  Future<List<Examination>> getRecommendedExaminations(CandidateProfile candidate) async => _testExams;

  @override
  Future<List<Examination>> searchExaminations(String query) async => _testExams;
}

class TestSavedRepository implements SavedRepository {
  final Set<String> _saved = {};

  @override
  Future<List<String>> getSavedExaminationIds(String candidateId) async => _saved.toList();

  @override
  Future<bool> isSaved(String candidateId, String examinationId) async => _saved.contains(examinationId);

  @override
  Future<void> saveExamination(String candidateId, String examinationId, {String? notes}) async {
    _saved.add(examinationId);
  }

  @override
  Future<void> unsaveExamination(String candidateId, String examinationId) async {
    _saved.remove(examinationId);
  }

  @override
  Future<List<Examination>> getSavedExaminations(String candidateId, ExaminationRepository examRepo) async {
    return [
      const Examination(
        id: 'test-exam-1',
        title: 'Civil Services Examination (Preliminary) 2026',
        organisation: 'UPSC',
        category: ExaminationCategory.govtRecruitment,
      ),
    ];
  }
}

class TestApplicationRepository implements ApplicationRepository {
  final List<ApplicationTrackerItem> _apps = [
    ApplicationTrackerItem(
      id: 'app-1',
      examinationId: 'test-exam-1',
      examination: const Examination(
        id: 'test-exam-1',
        title: 'Civil Services Examination',
        organisation: 'UPSC',
        category: ExaminationCategory.govtRecruitment,
      ),
      status: ApplicationStatus.applied,
      appliedDate: DateTime(2026, 2, 1),
      completedChecklist: const [],
      lastUpdated: DateTime.now(),
    ),
  ];

  @override
  Future<List<ApplicationTrackerItem>> getApplications(String candidateId) async => _apps;

  @override
  Future<void> updateApplicationStatus(String applicationId, ApplicationStatus newStatus) async {
    final idx = _apps.indexWhere((a) => a.id == applicationId);
    if (idx != -1) _apps[idx] = _apps[idx].copyWith(status: newStatus);
  }

  @override
  Future<void> createApplication({
    required String candidateId,
    required String examinationId,
    required ApplicationStatus status,
    String? applicationNumber,
    String? personalNotes,
  }) async {}

  @override
  Future<void> updateApplicationNotes(String applicationId, String notes) async {}

  @override
  Future<void> toggleChecklistItem(String applicationId, String item) async {
    final idx = _apps.indexWhere((a) => a.id == applicationId);
    if (idx != -1) {
      final list = List<String>.from(_apps[idx].completedChecklist);
      if (list.contains(item)) {
        list.remove(item);
      } else {
        list.add(item);
      }
      _apps[idx] = _apps[idx].copyWith(completedChecklist: list);
    }
  }
}

class TestNotificationRepository implements NotificationRepository {
  final List<NotificationItem> _notifs = [
    NotificationItem(
      id: 'notif-1',
      title: 'UPSC Notification',
      message: 'Application window open',
      type: NotificationType.upcomingDeadline,
      examinationId: 'test-exam-1',
      timestamp: DateTime.now(),
      isRead: false,
    ),
  ];

  @override
  Future<List<NotificationItem>> getNotifications(String candidateId) async => _notifs;

  @override
  Future<void> markAsRead(String notificationId) async {
    final idx = _notifs.indexWhere((n) => n.id == notificationId);
    if (idx != -1) _notifs[idx] = _notifs[idx].copyWith(isRead: true);
  }

  @override
  Future<void> markAllAsRead(String candidateId) async {
    for (int i = 0; i < _notifs.length; i++) {
      _notifs[i] = _notifs[i].copyWith(isRead: true);
    }
  }

  @override
  Future<int> getUnreadCount(String candidateId) async {
    return _notifs.where((n) => !n.isRead).length;
  }
}

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
        academicStatus: 'completed',
        degreeStatus: 'Completed',
        gradingSystem: 'percentage',
        percentage: 75.0,
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
      expect(report.criteriaResults.any((c) => c.criterionName.contains('Age Limit')), isTrue);
      expect(report.criteriaResults.any((c) => c.criterionName.contains('Educational Qualification')), isTrue);
      expect(report.criteriaResults.any((c) => c.criterionName.contains('Academic Score')), isTrue);
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
    final examRepo = TestExaminationRepository();
    final savedRepo = TestSavedRepository();
    final appRepo = TestApplicationRepository();
    final notifRepo = TestNotificationRepository();

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

    test('ExaminationCategory parses all Indian scholarship variants', () {
      expect(ExaminationCategory.fromString('Scholarships & Fellowships'), ExaminationCategory.scholarship);
      expect(ExaminationCategory.fromString('scholarship'), ExaminationCategory.scholarship);
      expect(ExaminationCategory.fromString('Scholarships'), ExaminationCategory.scholarship);
    });

    test('Scholarship opportunity from Supabase payload maps benefits and rules correctly', () {
      final rawSupabaseData = {
        'id': 'test-scholarship-pmrf',
        'slug': 'prime-ministers-research-fellowship-pmrf-scheme',
        'name': "Prime Minister's Research Fellowship (PMRF) Scheme",
        'category': 'Scholarships & Fellowships',
        'status': 'published',
        'overview': 'National prestigious fellowship for doctoral research.',
        'salary_or_pay_scale': '₹70,000/mo to ₹80,000/mo + ₹2 Lakh contingency',
        'official_application_url': 'https://www.pmrf.in',
        'is_central_government': true,
        'is_confirmed': true,
        'eligibility_rules': [
          {
            'min_age': 21,
            'max_age': 32,
            'educational_qualifications': ['B.Tech / B.E.', 'M.Sc'],
            'eligible_branches': ['Science', 'Engineering'],
          }
        ],
        'examination_dates': [
          {
            'application_closing_date': '2026-05-31T23:59:59Z',
          }
        ]
      };

      final opp = Examination.fromSupabase(rawSupabaseData);
      expect(opp.title, "Prime Minister's Research Fellowship (PMRF) Scheme");
      expect(opp.category, ExaminationCategory.scholarship);
      expect(opp.salaryOrPayScale, contains('₹70,000/mo'));
      expect(opp.officialApplicationUrl, 'https://www.pmrf.in');
      expect(opp.isCentralGovernment, isTrue);
      expect(opp.minAge, 21);
      expect(opp.maxAge, 32);
    });

    test('CandidateProfile preserves onboarding details', () {
      final profile = CandidateProfile(
        id: 'candidate-uuid-1234',
        email: 'aspirant@rexam.in',
        fullName: 'Aarav Sharma',
        dateOfBirth: DateTime(2002, 5, 15),
        gender: 'Male',
        state: 'Delhi (NCT)',
        socialCategory: 'OBC',
        isObcNcl: true,
        currentStatus: 'Completed undergraduate degree',
        highestQualification: 'B.Tech / B.E.',
        degreeName: 'B.Tech Computer Science',
        stream: 'Computer Science',
        graduationYear: 2024,
        cgpaOrPercentage: 8.4,
        preferredCategories: [ExaminationCategory.scholarship, ExaminationCategory.govtRecruitment],
      );

      expect(profile.fullName, 'Aarav Sharma');
      expect(profile.state, 'Delhi (NCT)');
      expect(profile.isObcNcl, isTrue);
      expect(profile.preferredCategories.contains(ExaminationCategory.scholarship), isTrue);
    });

    group('PART 7: Academic Eligibility Engine & Stage Rules Tests', () {
      final baseExam = Examination(
        id: 'exam-stage-001',
        title: 'National Technical Recruitment Examination 2026',
        organisation: 'C-DAC / DRDO',
        category: ExaminationCategory.psu,
        minAge: 20,
        maxAge: 30,
        educationalQualifications: ['B.Tech / B.E.'],
        eligibleStreams: ['Computer Science', 'All Disciplines'],
        minPercentage: 50.0,
      );

      // Test 1: Candidate with 7.5 CGPA evaluated against 50% requirement with verified conversion formula -> Passes.
      test('Test 1: 7.5 CGPA evaluated against 50% requirement with verified AICTE conversion formula passes', () {
        final candidate = CandidateProfile(
          id: 'test-cand-001',
          email: 'test1@rexam.in',
          dateOfBirth: DateTime(2000, 1, 1),
          socialCategory: 'General',
          highestQualification: 'B.Tech / B.E.',
          degreeName: 'B.Tech Computer Science',
          stream: 'Computer Science',
          university: 'AICTE',
          gradingSystem: 'cgpa',
          gradingScaleMax: 10.0,
          cgpa: 7.5,
          cgpaOrPercentage: 7.5,
          academicStatus: 'completed',
          degreeStatus: 'Completed',
        );

        final report = DeterministicEligibilityRepository.evaluate(
          candidate: candidate,
          examination: baseExam,
        );

        final scoreCriterion = report.criteriaResults.firstWhere(
          (c) => c.criterionName == 'Academic Score & Cutoff',
        );

        expect(scoreCriterion.status, RuleCheckStatus.passed);
        expect(scoreCriterion.details, contains('67.5%'));
        expect(report.overallStatus, EligibilityStatus.eligible);
      });

      // Test 2: Candidate with 7.5 CGPA evaluated against 8.0 CGPA requirement -> Fails.
      test('Test 2: 7.5 CGPA evaluated against 8.0 CGPA requirement fails', () {
        final examWithCgpa = baseExam.copyWith(minCgpa: 8.0);
        final candidate = CandidateProfile(
          id: 'test-cand-002',
          email: 'test2@rexam.in',
          dateOfBirth: DateTime(2000, 1, 1),
          socialCategory: 'General',
          highestQualification: 'B.Tech / B.E.',
          degreeName: 'B.Tech Computer Science',
          stream: 'Computer Science',
          university: 'Delhi University',
          gradingSystem: 'cgpa',
          gradingScaleMax: 10.0,
          cgpa: 7.5,
          cgpaOrPercentage: 7.5,
          academicStatus: 'completed',
          degreeStatus: 'Completed',
        );

        final report = DeterministicEligibilityRepository.evaluate(
          candidate: candidate,
          examination: examWithCgpa,
        );

        final scoreCriterion = report.criteriaResults.firstWhere(
          (c) => c.criterionName == 'Academic Score & Cutoff',
        );

        expect(scoreCriterion.status, RuleCheckStatus.failed);
        expect(scoreCriterion.details, contains('below required minimum of 8.00 CGPA'));
        expect(report.overallStatus, EligibilityStatus.notEligible);
      });

      // Test 3: Candidate with 7.5 CGPA evaluated against 50% requirement with no verified conversion formula -> Needs verification.
      test('Test 3: 7.5 CGPA evaluated against 50% requirement with no verified formula requires verification', () {
        final candidate = CandidateProfile(
          id: 'test-cand-003',
          email: 'test3@rexam.in',
          dateOfBirth: DateTime(2000, 1, 1),
          socialCategory: 'General',
          highestQualification: 'B.Tech / B.E.',
          degreeName: 'B.Tech Computer Science',
          stream: 'Computer Science',
          university: 'Unknown Autonomous College XYZ',
          gradingSystem: 'cgpa',
          gradingScaleMax: 10.0,
          cgpa: 7.5,
          cgpaOrPercentage: 7.5,
          academicStatus: 'completed',
          degreeStatus: 'Completed',
        );

        final report = DeterministicEligibilityRepository.evaluate(
          candidate: candidate,
          examination: baseExam,
        );

        final scoreCriterion = report.criteriaResults.firstWhere(
          (c) => c.criterionName == 'Academic Score & Cutoff',
        );

        expect(scoreCriterion.status, RuleCheckStatus.needsConfirmation);
        expect(scoreCriterion.status.label, 'Requires Verification');
        expect(scoreCriterion.candidateValue, '7.50 CGPA (10-point scale)');
        expect(scoreCriterion.candidateValue, isNot(contains('7.5%')));
        expect(scoreCriterion.details, contains('cannot be directly compared with the percentage requirement'));
        expect(report.overallStatus, EligibilityStatus.needsVerification);
      });

      // Test 4: Candidate with 65% evaluated against 50% requirement -> Passes.
      test('Test 4: Candidate with 65% evaluated against 50% requirement passes', () {
        final candidate = CandidateProfile(
          id: 'test-cand-004',
          email: 'test4@rexam.in',
          dateOfBirth: DateTime(2000, 1, 1),
          socialCategory: 'General',
          highestQualification: 'B.Tech / B.E.',
          degreeName: 'B.Tech Computer Science',
          stream: 'Computer Science',
          gradingSystem: 'percentage',
          percentage: 65.0,
          cgpaOrPercentage: 65.0,
          academicStatus: 'completed',
          degreeStatus: 'Completed',
        );

        final report = DeterministicEligibilityRepository.evaluate(
          candidate: candidate,
          examination: baseExam,
        );

        final scoreCriterion = report.criteriaResults.firstWhere(
          (c) => c.criterionName == 'Academic Score & Cutoff',
        );

        expect(scoreCriterion.status, RuleCheckStatus.passed);
        expect(scoreCriterion.details, contains('65.0%'));
        expect(report.overallStatus, EligibilityStatus.eligible);
      });

      // Test 5: 3rd-year student evaluated against exam requiring final-year appearing status -> Evaluates according to stage rules.
      test('Test 5: 3rd-year student evaluated against exam requiring final-year appearing status evaluates according to stage rules', () {
        final finalYearExam = baseExam.copyWith(
          acceptsFinalYearStudents: true,
          acceptsAppearingCandidates: false,
          minAcademicYearRequired: 4,
        );

        final thirdYearCandidate = CandidateProfile(
          id: 'test-cand-005',
          email: 'test5@rexam.in',
          dateOfBirth: DateTime(2004, 3, 10),
          socialCategory: 'General',
          highestQualification: 'B.Tech / B.E.',
          degreeName: 'B.Tech Computer Science',
          stream: 'Computer Science',
          university: 'AICTE',
          degreeDurationYears: 4,
          currentYearOfStudy: 3,
          currentSemester: 5,
          academicStatus: 'pursuing',
          degreeStatus: 'Ongoing',
          gradingSystem: 'cgpa',
          cgpa: 8.5,
          cgpaOrPercentage: 8.5,
        );

        final report = DeterministicEligibilityRepository.evaluate(
          candidate: thirdYearCandidate,
          examination: finalYearExam,
        );

        final stageCriterion = report.criteriaResults.firstWhere(
          (c) => c.criterionName == 'Academic Stage & Completion',
        );

        // 3rd-year candidate does not satisfy 4th-year final year appearing requirement
        expect(stageCriterion.status, RuleCheckStatus.failed);
        expect(stageCriterion.details, contains('Year 3 of 4'));
        expect(report.overallStatus, EligibilityStatus.notEligible);

        // However, against an examination accepting 3rd-year students (such as GATE):
        final gateLikeExam = baseExam.copyWith(
          acceptsFinalYearStudents: true,
          acceptsAppearingCandidates: true,
          minAcademicYearRequired: 3,
        );

        final gateReport = DeterministicEligibilityRepository.evaluate(
          candidate: thirdYearCandidate,
          examination: gateLikeExam,
        );

        final gateStageCriterion = gateReport.criteriaResults.firstWhere(
          (c) => c.criterionName == 'Academic Stage & Completion',
        );

        expect(gateStageCriterion.status, RuleCheckStatus.passed);
        expect(gateReport.overallStatus, EligibilityStatus.eligible);
      });

      // Test 6: 3rd-year student evaluated against exam requiring completed degree -> Ineligible with clear explanation.
      test('Test 6: 3rd-year student evaluated against exam requiring completed degree is ineligible with clear explanation', () {
        final completedOnlyExam = baseExam.copyWith(
          acceptsFinalYearStudents: false,
          acceptsAppearingCandidates: false,
        );

        final thirdYearCandidate = CandidateProfile(
          id: 'test-cand-006',
          email: 'test6@rexam.in',
          dateOfBirth: DateTime(2004, 3, 10),
          socialCategory: 'General',
          highestQualification: 'B.Tech / B.E.',
          degreeName: 'B.Tech Computer Science',
          stream: 'Computer Science',
          university: 'AICTE',
          degreeDurationYears: 4,
          currentYearOfStudy: 3,
          currentSemester: 6,
          academicStatus: 'pursuing',
          degreeStatus: 'Ongoing',
          gradingSystem: 'cgpa',
          cgpa: 8.5,
          cgpaOrPercentage: 8.5,
        );

        final report = DeterministicEligibilityRepository.evaluate(
          candidate: thirdYearCandidate,
          examination: completedOnlyExam,
        );

        final stageCriterion = report.criteriaResults.firstWhere(
          (c) => c.criterionName == 'Academic Stage & Completion',
        );

        expect(stageCriterion.status, RuleCheckStatus.failed);
        expect(stageCriterion.details, contains('strictly requires a completed degree'));
        expect(report.overallStatus, EligibilityStatus.notEligible);
        expect(report.overallSummary, contains('one or more mandatory statutory criteria'));
      });

      // Test 7: Consistency test: verify that the same examination gives identical eligibility results across all views.
      test('Test 7: Consistency test verifies identical eligibility evaluation across all application views', () {
        final candidate = CandidateProfile(
          id: 'test-cand-007',
          email: 'test7@rexam.in',
          dateOfBirth: DateTime(2002, 6, 20),
          socialCategory: 'OBC',
          isObcNcl: true,
          highestQualification: 'B.Tech / B.E.',
          degreeName: 'B.Tech Mechanical Engineering',
          stream: 'Mechanical Engineering',
          university: 'Delhi University',
          degreeDurationYears: 4,
          currentYearOfStudy: 4,
          currentSemester: 8,
          academicStatus: 'pursuing',
          degreeStatus: 'Ongoing',
          gradingSystem: 'cgpa',
          cgpa: 7.8,
          cgpaOrPercentage: 7.8,
        );

        final exam = baseExam.copyWith(
          eligibleStreams: ['Mechanical Engineering'],
          acceptsFinalYearStudents: true,
          minPercentage: 55.0,
        );

        // 1. Home Dashboard simulation
        final dashboardReport = DeterministicEligibilityRepository.evaluate(candidate: candidate, examination: exam);

        // 2. All Examinations tab simulation
        final allExamsReport = DeterministicEligibilityRepository.evaluate(candidate: candidate, examination: exam);

        // 3. Eligible for Me tab simulation
        final eligibleForMeReport = DeterministicEligibilityRepository.evaluate(candidate: candidate, examination: exam);

        // 4. Opportunity Details Screen simulation
        final detailsReport = DeterministicEligibilityRepository.evaluate(candidate: candidate, examination: exam);

        // 5. Full Eligibility Report Screen simulation
        final fullReport = DeterministicEligibilityRepository.evaluate(candidate: candidate, examination: exam);

        expect(dashboardReport.overallStatus, allExamsReport.overallStatus);
        expect(allExamsReport.overallStatus, eligibleForMeReport.overallStatus);
        expect(eligibleForMeReport.overallStatus, detailsReport.overallStatus);
        expect(detailsReport.overallStatus, fullReport.overallStatus);
        expect(dashboardReport.overallStatus, EligibilityStatus.eligible);

        // Ensure criteria counts, relaxations, and scores match 1:1
        expect(dashboardReport.criteriaResults.length, fullReport.criteriaResults.length);
        expect(dashboardReport.applicableRelaxations, fullReport.applicableRelaxations);
      });

      // Test 8: Data persistence: save an undergraduate profile with all new fields, reload it, verify all fields are preserved intact.
      test('Test 8: Data persistence test verifies all undergraduate fields serialize and deserialize intact', () {
        final originalProfile = CandidateProfile(
          id: 'cand-persistence-008',
          email: 'aspirant.persistence@rexam.in',
          fullName: 'Vikramaditya Rathore',
          dateOfBirth: DateTime(2003, 11, 24),
          gender: 'Male',
          nationality: 'Indian',
          state: 'Rajasthan',
          district: 'Jaipur',
          socialCategory: 'OBC',
          isObcNcl: true,
          currentStatus: 'Pursuing undergraduate degree',
          highestQualification: 'B.Tech / B.E.',
          degreeName: 'B.Tech Electronics and Communication',
          stream: 'Electronics and Communication',
          university: 'Visvesvaraya Technological University',
          collegeName: 'BMS College of Engineering',
          degreeDurationYears: 4,
          currentYearOfStudy: 3,
          currentSemester: 6,
          academicStatus: 'pursuing',
          gradingSystem: 'cgpa',
          gradingScaleMax: 10.0,
          cgpa: 8.42,
          percentage: null,
          yearWisePerformance: const {
            'year_1': 8.1,
            'year_2': 8.5,
            'year_3': 8.65,
          },
          conversionFormula: '(CGPA - 0.75) * 10',
          conversionSource: 'VTU Official Notification Exec 2018/19',
          graduationYear: 2026,
          cgpaOrPercentage: 8.42,
          degreeStatus: 'Ongoing',
          hasActiveBacklogs: false,
          gateScore: 710,
          gateYear: 2026,
        );

        // Simulate Supabase serialization and deserialization
        final supabaseRow = {
          'id': originalProfile.id,
          'full_name': originalProfile.fullName,
          'date_of_birth': originalProfile.dateOfBirth?.toIso8601String().split('T').first,
          'gender': originalProfile.gender,
          'nationality': originalProfile.nationality,
          'state': originalProfile.state,
          'district': originalProfile.district,
          'social_category': originalProfile.socialCategory,
          'is_obc_ncl': originalProfile.isObcNcl,
          'is_pwbd': originalProfile.isPwBD,
          'is_ex_serviceman': originalProfile.isExServiceman,
          'current_status': originalProfile.currentStatus,
          'highest_qualification': originalProfile.highestQualification,
          'degree_name': originalProfile.degreeName,
          'stream': originalProfile.stream,
          'institution': originalProfile.collegeName,
          'graduation_year': originalProfile.graduationYear,
          'cgpa_or_percentage': originalProfile.cgpaOrPercentage,
          'degree_status': originalProfile.degreeStatus,
          'has_active_backlogs': originalProfile.hasActiveBacklogs,
          'candidate_education': [
            {
              'university': originalProfile.university,
              'college_name': originalProfile.collegeName,
              'degree_duration_years': originalProfile.degreeDurationYears,
              'current_year_of_study': originalProfile.currentYearOfStudy,
              'current_semester': originalProfile.currentSemester,
              'academic_status': originalProfile.academicStatus,
              'grading_system': originalProfile.gradingSystem,
              'grading_scale_max': originalProfile.gradingScaleMax,
              'cgpa': originalProfile.cgpa,
              'percentage': originalProfile.percentage,
              'year_wise_performance': originalProfile.yearWisePerformance,
              'conversion_formula': originalProfile.conversionFormula,
              'conversion_source': originalProfile.conversionSource,
            }
          ],
          'candidate_preferences': [],
          'candidate_competitive_exams': [
            {
              'exam_name': 'GATE',
              'score': originalProfile.gateScore,
              'year': originalProfile.gateYear,
            }
          ],
        };

        final reloaded = CandidateProfile.fromSupabase(supabaseRow, email: originalProfile.email);

        expect(reloaded.id, originalProfile.id);
        expect(reloaded.fullName, originalProfile.fullName);
        expect(reloaded.university, 'Visvesvaraya Technological University');
        expect(reloaded.collegeName, 'BMS College of Engineering');
        expect(reloaded.degreeDurationYears, 4);
        expect(reloaded.currentYearOfStudy, 3);
        expect(reloaded.currentSemester, 6);
        expect(reloaded.academicStatus, 'pursuing');
        expect(reloaded.gradingSystem, 'cgpa');
        expect(reloaded.gradingScaleMax, 10.0);
        expect(reloaded.cgpa, 8.42);
        expect(reloaded.yearWisePerformance['year_1'], 8.1);
        expect(reloaded.yearWisePerformance['year_2'], 8.5);
        expect(reloaded.yearWisePerformance['year_3'], 8.65);
        expect(reloaded.conversionFormula, '(CGPA - 0.75) * 10');
        expect(reloaded.conversionSource, contains('VTU'));
        expect(reloaded.isFinalYearStudent, isFalse);
        expect(reloaded.isUndergraduatePursuing, isTrue);
      });

      // =======================================================================
      // SPECIFICATION MANDATED TESTS A THROUGH G
      // =======================================================================
      group('MANDATED SPECIFICATION VERIFICATION SUITE: Tests A to G', () {
        // Test A: Candidate: 7.5 CGPA, scale 10. Requirement: 50%. No verified conversion formula. Expected: Requires Verification.
        test('Test A: Candidate 7.5 CGPA vs 50% requirement with no verified formula yields Requires Verification', () {
          final candidate = CandidateProfile(
            id: 'cand-test-a',
            email: 'test_a@rexam.in',
            dateOfBirth: DateTime(2001, 1, 1),
            socialCategory: 'General',
            highestQualification: 'B.Tech / B.E.',
            degreeName: 'B.Tech Computer Science',
            stream: 'Computer Science',
            university: 'Autonomous College Without Formula',
            gradingSystem: 'cgpa',
            gradingScaleMax: 10.0,
            cgpa: 7.5,
            cgpaOrPercentage: 7.5,
            academicStatus: 'completed',
          );

          final exam = baseExam.copyWith(minPercentage: 50.0, minCgpa: null);
          final report = DeterministicEligibilityRepository.evaluate(candidate: candidate, examination: exam);

          final scoreCrit = report.criteriaResults.firstWhere((c) => c.criterionName == 'Academic Score & Cutoff');
          expect(scoreCrit.status, RuleCheckStatus.needsConfirmation);
          expect(scoreCrit.status.label, 'Requires Verification');
          expect(scoreCrit.candidateValue, '7.50 CGPA (10-point scale)');
          expect(scoreCrit.candidateValue, isNot(contains('7.5%')));
          expect(scoreCrit.conversionFormula, 'Awaiting verified university formula');
          expect(scoreCrit.details, contains('cannot be directly compared with the percentage requirement'));
          expect(report.overallStatus, EligibilityStatus.needsVerification);
        });

        // Test B: Candidate: 7.5 CGPA, scale 10. Requirement: 7.0 CGPA, scale 10. Expected: Satisfied.
        test('Test B: Candidate 7.5 CGPA vs 7.0 CGPA requirement yields Satisfied', () {
          final candidate = CandidateProfile(
            id: 'cand-test-b',
            email: 'test_b@rexam.in',
            dateOfBirth: DateTime(2001, 1, 1),
            socialCategory: 'General',
            highestQualification: 'B.Tech / B.E.',
            degreeName: 'B.Tech Computer Science',
            stream: 'Computer Science',
            gradingSystem: 'cgpa',
            gradingScaleMax: 10.0,
            cgpa: 7.5,
            cgpaOrPercentage: 7.5,
            academicStatus: 'completed',
          );

          final exam = baseExam.copyWith(minCgpa: 7.0, minPercentage: null);
          final report = DeterministicEligibilityRepository.evaluate(candidate: candidate, examination: exam);

          final scoreCrit = report.criteriaResults.firstWhere((c) => c.criterionName == 'Academic Score & Cutoff');
          expect(scoreCrit.status, RuleCheckStatus.passed);
          expect(scoreCrit.status.label, 'Satisfied');
          expect(scoreCrit.candidateValue, contains('7.50 CGPA'));
          expect(report.overallStatus, EligibilityStatus.eligible);
        });

        // Test C: Candidate: 7.5 CGPA, scale 10. Requirement: 8.0 CGPA, scale 10. Expected: Not Satisfied.
        test('Test C: Candidate 7.5 CGPA vs 8.0 CGPA requirement yields Not Satisfied', () {
          final candidate = CandidateProfile(
            id: 'cand-test-c',
            email: 'test_c@rexam.in',
            dateOfBirth: DateTime(2001, 1, 1),
            socialCategory: 'General',
            highestQualification: 'B.Tech / B.E.',
            degreeName: 'B.Tech Computer Science',
            stream: 'Computer Science',
            gradingSystem: 'cgpa',
            gradingScaleMax: 10.0,
            cgpa: 7.5,
            cgpaOrPercentage: 7.5,
            academicStatus: 'completed',
          );

          final exam = baseExam.copyWith(minCgpa: 8.0, minPercentage: null);
          final report = DeterministicEligibilityRepository.evaluate(candidate: candidate, examination: exam);

          final scoreCrit = report.criteriaResults.firstWhere((c) => c.criterionName == 'Academic Score & Cutoff');
          expect(scoreCrit.status, RuleCheckStatus.failed);
          expect(scoreCrit.status.label, 'Not Satisfied');
          expect(scoreCrit.candidateValue, contains('7.50 CGPA'));
          expect(report.overallStatus, EligibilityStatus.notEligible);
        });

        // Test D: Candidate: 65%. Requirement: 50%. Expected: Satisfied.
        test('Test D: Candidate 65% vs 50% percentage requirement yields Satisfied', () {
          final candidate = CandidateProfile(
            id: 'cand-test-d',
            email: 'test_d@rexam.in',
            dateOfBirth: DateTime(2001, 1, 1),
            socialCategory: 'General',
            highestQualification: 'B.Tech / B.E.',
            degreeName: 'B.Tech Computer Science',
            stream: 'Computer Science',
            gradingSystem: 'percentage',
            gradingScaleMax: 100.0,
            percentage: 65.0,
            cgpaOrPercentage: 65.0,
            academicStatus: 'completed',
          );

          final exam = baseExam.copyWith(minPercentage: 50.0, minCgpa: null);
          final report = DeterministicEligibilityRepository.evaluate(candidate: candidate, examination: exam);

          final scoreCrit = report.criteriaResults.firstWhere((c) => c.criterionName == 'Academic Score & Cutoff');
          expect(scoreCrit.status, RuleCheckStatus.passed);
          expect(scoreCrit.status.label, 'Satisfied');
          expect(scoreCrit.candidateValue, '65.0%');
          expect(report.overallStatus, EligibilityStatus.eligible);
        });

        // Test E: Candidate: 7.5 CGPA. Verified institutional formula available (AICTE). Requirement: 50%. Expected: Use actual converted percentage.
        test('Test E: Candidate 7.5 CGPA with verified AICTE formula vs 50% requirement uses converted percentage (67.5% >= 50%)', () {
          final candidate = CandidateProfile(
            id: 'cand-test-e',
            email: 'test_e@rexam.in',
            dateOfBirth: DateTime(2001, 1, 1),
            socialCategory: 'General',
            highestQualification: 'B.Tech / B.E.',
            degreeName: 'B.Tech Computer Science',
            stream: 'Computer Science',
            university: 'AICTE Standard Norm',
            gradingSystem: 'cgpa',
            gradingScaleMax: 10.0,
            cgpa: 7.5,
            cgpaOrPercentage: 7.5,
            academicStatus: 'completed',
          );

          final exam = baseExam.copyWith(minPercentage: 50.0, minCgpa: null);
          final report = DeterministicEligibilityRepository.evaluate(candidate: candidate, examination: exam);

          final scoreCrit = report.criteriaResults.firstWhere((c) => c.criterionName == 'Academic Score & Cutoff');
          expect(scoreCrit.status, RuleCheckStatus.passed);
          expect(scoreCrit.status.label, 'Satisfied');
          expect(scoreCrit.convertedPercentage, '67.5%');
          expect(scoreCrit.conversionFormula, 'Percentage = (CGPA - 0.75) × 10');
          expect(scoreCrit.comparison, '67.5% vs required 50.0% aggregate marks');
          expect(scoreCrit.details, contains('67.5%'));
          expect(report.overallStatus, EligibilityStatus.eligible);
        });

        // Test F: Candidate has 7.5 CGPA. Expected display everywhere: 7.5 CGPA, never 7.5%.
        test('Test F: Candidate with 7.5 CGPA formats as 7.50 CGPA (10-point scale), never 7.5%', () {
          final candidate = CandidateProfile(
            id: 'cand-test-f',
            email: 'test_f@rexam.in',
            gradingSystem: 'cgpa',
            gradingScaleMax: 10.0,
            cgpa: 7.5,
            cgpaOrPercentage: 7.5,
          );

          expect(candidate.formattedScoreDisplay, '7.50 CGPA (10-point scale)');
          expect(candidate.shortScoreDisplay, '7.50 CGPA');
          expect(candidate.formattedScoreDisplay.contains('%'), isFalse);
          expect(candidate.shortScoreDisplay.contains('%'), isFalse);

          // And with AcademicScore model
          final scoreModel = AcademicScore(
            scoreValue: 7.5,
            gradingType: AcademicGradingType.cgpa,
            gradingScaleMax: 10.0,
          );
          expect(scoreModel.formattedDisplay, '7.50 CGPA (10-point scale)');
          expect(scoreModel.shortDisplay, '7.50 CGPA');
        });

        // Test G: Open the same examination from Home, All Examinations and Eligible for Me yields identical result.
        test('Test G: Identical eligibility evaluation across Home, All Examinations, and Eligible for Me views', () {
          final candidate = CandidateProfile(
            id: 'cand-test-g',
            email: 'test_g@rexam.in',
            dateOfBirth: DateTime(2001, 1, 1),
            socialCategory: 'General',
            highestQualification: 'B.Tech / B.E.',
            degreeName: 'B.Tech Computer Science',
            stream: 'Computer Science',
            university: 'Unknown College',
            gradingSystem: 'cgpa',
            gradingScaleMax: 10.0,
            cgpa: 7.5,
            cgpaOrPercentage: 7.5,
            academicStatus: 'completed',
          );

          final exam = baseExam.copyWith(minPercentage: 50.0, minCgpa: null);

          // 1. Home evaluation
          final homeReport = DeterministicEligibilityRepository.evaluate(candidate: candidate, examination: exam);

          // 2. All Examinations evaluation
          final allExamsReport = DeterministicEligibilityRepository.evaluate(candidate: candidate, examination: exam);

          // 3. Eligible for Me evaluation
          final eligibleForMeReport = DeterministicEligibilityRepository.evaluate(candidate: candidate, examination: exam);

          expect(homeReport.overallStatus, allExamsReport.overallStatus);
          expect(allExamsReport.overallStatus, eligibleForMeReport.overallStatus);
          expect(homeReport.overallStatus, EligibilityStatus.needsVerification);

          final homeCrit = homeReport.criteriaResults.firstWhere((c) => c.criterionName == 'Academic Score & Cutoff');
          final allCrit = allExamsReport.criteriaResults.firstWhere((c) => c.criterionName == 'Academic Score & Cutoff');
          final eligCrit = eligibleForMeReport.criteriaResults.firstWhere((c) => c.criterionName == 'Academic Score & Cutoff');

          expect(homeCrit.status, allCrit.status);
          expect(allCrit.status, eligCrit.status);
          expect(homeCrit.candidateValue, allCrit.candidateValue);
          expect(allCrit.candidateValue, eligCrit.candidateValue);
          expect(homeCrit.details, allCrit.details);
          expect(allCrit.details, eligCrit.details);
        });

        // Test H: Section 7 Qualification & Stage Audit: Class 12 requirements evaluate Class 12 credentials truthfully.
        test('Test H: Examination requiring Class 12 correctly evaluates Class 12 credentials without substituting B.Tech', () {
          final class12Exam = baseExam.copyWith(
            educationalQualifications: ['Class 12', 'Diploma / Polytechnic'],
            eligibleStreams: ['Science (PCM - Physics, Chemistry, Maths)', 'Science'],
          );

          final candidateWithBoth = CandidateProfile(
            id: 'cand-test-h',
            email: 'test_h@rexam.in',
            dateOfBirth: DateTime(2001, 1, 1),
            socialCategory: 'General',
            class12Year: 2019,
            class12Stream: 'Science (PCM - Physics, Chemistry, Maths)',
            highestQualification: 'B.Tech / B.E.',
            degreeName: 'B.Tech',
            stream: 'Computer Science',
            graduationYear: 2023,
            gradingSystem: 'cgpa',
            cgpa: 7.5,
          );

          final report = DeterministicEligibilityRepository.evaluate(
            candidate: candidateWithBoth,
            examination: class12Exam,
          );

          final eduCrit = report.criteriaResults.firstWhere((c) => c.criterionName == 'Educational Qualification & Discipline');
          expect(eduCrit.candidateValue, contains('Class 12 (Science (PCM - Physics, Chemistry, Maths)) • Passed 2019'));
          expect(eduCrit.status, RuleCheckStatus.passed);

          final stageCrit = report.criteriaResults.firstWhere((c) => c.criterionName == 'Academic Stage & Completion');
          expect(stageCrit.candidateValue, 'Class 12 Completed (2019)');
          expect(stageCrit.status, RuleCheckStatus.passed);
        });
      });
    });
  });
}
