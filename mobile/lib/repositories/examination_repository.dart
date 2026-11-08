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
  final List<Examination> _fallbackData = [
    Examination(
      id: 'opp-upsc-cse-2026',
      title: 'Civil Services Examination (Preliminary) 2026',
      organisation: 'Union Public Service Commission (UPSC)',
      issuingAuthority: 'Department of Personnel and Training (DoPT), Government of India',
      category: ExaminationCategory.govtRecruitment,
      overview:
          'The Civil Services Examination is conducted annually by UPSC to recruit officers into premier Indian administrative services, including IAS, IFS, IPS, and Central Group A & B services.',
      vacancies: 1056,
      eligibilityCriteriaSummary:
          'Must hold a degree of any recognized university. Age 21 to 32 years as on 1st August 2026, with statutory relaxation for reserved categories.',
      minAge: 21,
      maxAge: 32,
      categoryAgeRelaxation: {
        'General / EWS': 'No relaxation (32 years maximum, 6 attempts)',
        'OBC-NCL': '3 years relaxation (up to 35 years, 9 attempts)',
        'SC / ST': '5 years relaxation (up to 37 years, unlimited attempts)',
        'PwBD': '10 years relaxation (up to 42 years)',
      },
      educationalQualifications: [
        'Bachelor’s Degree in any discipline from a recognized University.',
        'Candidates appearing in final year degree examination are eligible to apply provisionally.',
      ],
      eligibleStreams: ['All Disciplines (Engineering, Sciences, Arts, Commerce, Medicine, Law)'],
      minPercentage: null,
      nationality: 'Citizen of India',
      genderRequirements: 'All genders eligible.',
      workExperience: 'No prior work experience required.',
      applicationFee: 100,
      feeExemptions: 'Female candidates, SC, ST, and Persons with Benchmark Disability (PwBD) are fully exempted.',
      requiredDocuments: [
        'Government Photo ID Proof',
        'Class 10th Certificate (Date of Birth proof)',
        'Graduation Degree / Final Year Bonafide Certificate',
      ],
      importantDates: {
        'Notification Date': DateTime(2026, 2, 14),
        'Application Deadline': DateTime(2026, 3, 6, 18, 0),
        'Preliminary Examination': DateTime(2026, 5, 25),
      },
      selectionProcedure: 'Three-tier structure: 1. Preliminary Examination; 2. Main Examination; 3. Personality Test.',
      examPattern: 'Prelims Paper 1: General Studies (200 marks). Paper 2: CSAT (qualifying at 33%).',
      salaryOrPayScale: 'Level 10 of 7th CPC (₹56,100 to ₹1,77,500 base pay).',
      location: 'All India Service (Cadre allocated upon appointment).',
      applicationInstructions: 'Apply online exclusively through UPSC OTR portal at upsconline.nic.in.',
      officialNotificationPdfUrl: 'https://upsc.gov.in/sites/default/files/ExamNotice_CSE_2026.pdf',
      officialApplicationUrl: 'https://upsconline.nic.in',
      sourceUrl: 'https://upsc.gov.in',
      lastVerifiedAt: DateTime(2026, 3, 1, 10, 30),
      isOfficialSource: true,
      applicationDeadline: DateTime(2026, 3, 6, 18, 0),
      isCentralGovernment: true,
      state: null,
      isConfirmed: true,
    ),
    Examination(
      id: 'opp-isro-scientist-2026',
      title: 'Recruitment of Scientist/Engineer "SC" (Computer Science / Mechanical / Electronics)',
      organisation: 'Indian Space Research Organisation (ISRO)',
      issuingAuthority: 'Department of Space, Vikram Sarabhai Space Centre & URSC',
      category: ExaminationCategory.psu,
      overview:
          'ISRO Centralised Recruitment Board (ICRB) invites online applications for Scientist/Engineer "SC" positions in Group A Gazetted posts across ISRO centres.',
      vacancies: 320,
      eligibilityCriteriaSummary:
          'First Class B.E. / B.Tech or equivalent in CS, Electronics, or Mechanical with minimum 65% aggregate or 6.84 CGPA. Maximum age 28 years.',
      minAge: 18,
      maxAge: 28,
      categoryAgeRelaxation: {
        'General': '28 years',
        'OBC-NCL': '31 years (3 years relaxation)',
        'SC / ST': '33 years (5 years relaxation)',
        'PwBD': '38 years (10 years relaxation)',
      },
      educationalQualifications: [
        'B.E. / B.Tech in CS / IT / Mechanical / ECE with minimum 65% aggregate or 6.84/10 CGPA.',
      ],
      eligibleStreams: [
        'Computer Science & Engineering',
        'Information Technology',
        'Mechanical Engineering',
        'Electronics and Communication Engineering',
      ],
      minPercentage: 65.0,
      nationality: 'Citizen of India',
      genderRequirements: 'All genders eligible.',
      workExperience: 'Fresh engineering graduates and final semester students eligible.',
      applicationFee: 250,
      feeExemptions: 'All women, SC/ST/PwBD and Ex-Servicemen are exempted.',
      requiredDocuments: [
        'Class 10th and 12th Marksheets & Certificates',
        'B.Tech Consolidated Marksheet',
      ],
      importantDates: {
        'Notification Date': DateTime(2026, 2, 20),
        'Application Deadline': DateTime(2026, 3, 15, 23, 59),
        'Written Examination': DateTime(2026, 5, 10),
      },
      selectionProcedure: 'Written CBT test (Discipline + Aptitude) followed by technical interview in 1:5 ratio.',
      examPattern: 'Part A: 80 Discipline-specific MCQs. Part B: 15 Multiple choice aptitude questions.',
      salaryOrPayScale: 'Pay Level 10 (Gross ~₹92,000/month plus medical and campus housing).',
      location: 'Bengaluru, Thiruvananthapuram, Sriharikota, Hyderabad, Ahmedabad.',
      applicationInstructions: 'Register online via the ICRB portal. Upload CGPA-to-percentage formula certificate.',
      officialNotificationPdfUrl: 'https://www.isro.gov.in/media_isro/pdf/recruitment/ICRB_01_2026.pdf',
      officialApplicationUrl: 'https://apps.isac.gov.in/icrb-2026',
      sourceUrl: 'https://isro.gov.in',
      lastVerifiedAt: DateTime(2026, 3, 2, 14, 0),
      isOfficialSource: true,
      applicationDeadline: DateTime(2026, 3, 15, 23, 59),
      isCentralGovernment: true,
      state: null,
      isConfirmed: true,
    ),
    Examination(
      id: 'opp-drdo-scientist-b-2026',
      title: 'Recruitment of Scientist "B" via Valid GATE Score (RAC Advt 148)',
      organisation: 'Defence Research & Development Organisation (DRDO)',
      issuingAuthority: 'Recruitment and Assessment Centre (RAC), Ministry of Defence',
      category: ExaminationCategory.govtRecruitment,
      overview:
          'DRDO RAC invites online applications from talented engineering graduates for appointment to the post of Scientist "B" across DRDO laboratories.',
      vacancies: 204,
      eligibilityCriteriaSummary:
          'First Class Bachelor’s Degree in Engineering or Technology in relevant discipline and a valid GATE Score in corresponding paper.',
      minAge: 21,
      maxAge: 28,
      categoryAgeRelaxation: {
        'Unreserved / EWS': '28 years',
        'OBC-NCL': '31 years (3 years)',
        'SC / ST': '33 years (5 years)',
        'PwBD': '38 years (10 years)',
      },
      educationalQualifications: [
        'First Class Bachelor’s Degree in Engineering/Technology in CS, Mech, ECE, or EE.',
        'Valid GATE score in corresponding subject paper.',
      ],
      eligibleStreams: [
        'Computer Science & Engineering',
        'Mechanical Engineering',
        'Electrical Engineering',
        'Electronics & Communication Engineering',
      ],
      minPercentage: 60.0,
      nationality: 'Citizen of India',
      genderRequirements: 'All genders eligible.',
      workExperience: 'None required.',
      applicationFee: 100,
      feeExemptions: 'No fee for SC/ST/PwBD and Women candidates.',
      requiredDocuments: [
        'Official GATE Scorecard',
        'Engineering Degree / Final Year Consolidated Marksheet',
        'Class 10 Certificate (DoB proof)',
      ],
      importantDates: {
        'Application Deadline': DateTime(2026, 3, 29, 17, 0),
        'Personal Interview Shortlist': DateTime(2026, 4, 30),
      },
      selectionProcedure: 'Shortlisting based on GATE Score in 1:10 ratio, followed by Technical Interview in Delhi.',
      salaryOrPayScale: 'Level 10 (7th CPC), Basic ₹56,100/- pm (Gross ~₹95,000/month).',
      location: 'Bengaluru, Hyderabad, Pune, Chandigarh, Delhi, Kochi.',
      applicationInstructions: 'Apply online at rac.gov.in. Upload scanned certificates.',
      officialNotificationPdfUrl: 'https://rac.gov.in/download/advt_148_scientist_b.pdf',
      officialApplicationUrl: 'https://rac.gov.in',
      sourceUrl: 'https://rac.gov.in',
      lastVerifiedAt: DateTime(2026, 3, 4, 11, 45),
      isOfficialSource: true,
      applicationDeadline: DateTime(2026, 3, 29, 17, 0),
      isCentralGovernment: true,
      state: null,
      isConfirmed: true,
    ),
  ];

  @override
  Future<List<Examination>> getExaminations({
    ExaminationCategory? category,
    bool? isCentralGovernment,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  }) async {
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        var query = client
            .from('examinations')
            .select('*, examination_dates(*), eligibility_rules(*), organisations(*)')
            .eq('status', 'published');

        if (category != null) {
          query = query.eq('category', category.label);
        }
        if (isCentralGovernment != null) {
          query = query.eq('is_central_government', isCentralGovernment);
        }
        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          query = query.ilike('name', '%${searchQuery.trim()}%');
        }

        final int from = (page - 1) * limit;
        final int to = from + limit - 1;
        final response = await query.range(from, to);

        if (response.isNotEmpty) {
          return response.map<Examination>((item) => Examination.fromSupabase(item)).toList();
        }
      } catch (e) {
        debugPrint('[REXAM] Supabase fetch error: $e. Falling back to local data.');
      }
    }

    // Local / Offline fallback filtering
    await Future.delayed(const Duration(milliseconds: 100));
    var list = _fallbackData;
    if (category != null) {
      list = list.where((e) => e.category == category).toList();
    }
    if (isCentralGovernment != null) {
      list = list.where((e) => e.isCentralGovernment == isCentralGovernment).toList();
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((e) {
        return e.title.toLowerCase().contains(q) ||
            e.organisation.toLowerCase().contains(q) ||
            e.eligibleStreams.any((s) => s.toLowerCase().contains(q));
      }).toList();
    }
    return list;
  }

  @override
  Future<Examination?> getExaminationById(String id) async {
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final res = await client
            .from('examinations')
            .select('*, examination_dates(*), eligibility_rules(*), organisations(*)')
            .eq('id', id)
            .maybeSingle();
        if (res != null) {
          return Examination.fromSupabase(res);
        }
      } catch (e) {
        debugPrint('[REXAM] Fetch examination by id error: $e');
      }
    }

    try {
      return _fallbackData.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Examination>> getRecommendedExaminations(CandidateProfile candidate) async {
    final all = await getExaminations();
    return all.where((opp) {
      if (candidate.preferredCategories.contains(opp.category)) return true;
      if (candidate.stream != null) {
        final stream = candidate.stream!.toLowerCase();
        if (opp.eligibleStreams.any((s) => s.toLowerCase().contains(stream) || s.toLowerCase().contains('all disciplines'))) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  @override
  Future<List<Examination>> getClosingSoonExaminations({int limit = 5}) async {
    final all = await getExaminations();
    final sorted = List<Examination>.from(all)
      ..sort((a, b) {
        if (a.applicationDeadline == null) return 1;
        if (b.applicationDeadline == null) return -1;
        return a.applicationDeadline!.compareTo(b.applicationDeadline!);
      });
    return sorted.take(limit).toList();
  }

  @override
  Future<List<Examination>> searchExaminations(String query) async {
    return getExaminations(searchQuery: query);
  }
}
