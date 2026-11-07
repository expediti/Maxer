import 'package:rexam/features/profile/domain/candidate_profile.dart';
import 'package:rexam/features/opportunities/domain/opportunity.dart';

abstract class CandidateRepository {
  Future<CandidateProfile> getProfile(String candidateId);
  Future<CandidateProfile> updateProfile(CandidateProfile profile);
}

class MockCandidateRepository implements CandidateRepository {
  CandidateProfile _profile = CandidateProfile(
    id: 'candidate-rexam-001',
    email: 'arjun.sharma@rexam.in',
    fullName: 'Arjun Sharma',
    dateOfBirth: DateTime(1999, 7, 15),
    gender: 'Male',
    nationality: 'Indian',
    state: 'Delhi',
    district: 'New Delhi',
    countryOfResidence: 'India',
    socialCategory: 'OBC-NCL',
    isPwBD: false,
    isExServiceman: false,
    highestQualification: 'B.Tech / B.E.',
    currentQualification: 'B.Tech / B.E. (Graduated)',
    degreeName: 'Bachelor of Technology',
    stream: 'Computer Science & Engineering',
    universityOrCollege: 'Delhi Technological University (DTU)',
    isUniversityRecognized: true,
    graduationYear: 2023,
    cgpaOrPercentage: 78.5,
    hasActiveBacklogs: false,
    gateScore: 682,
    gateYear: 2025,
    hasNetJrf: false,
    certifications: [
      'AWS Certified Solutions Architect',
      'Linux Foundation Certified SysAdmin',
    ],
    workExperienceYears: 1.5,
    researchExperienceMonths: 6,
    preferredCategories: const [
      OpportunityCategory.govtRecruitment,
      OpportunityCategory.psu,
      OpportunityCategory.scholarship,
    ],
    maxApplicationFeeBudget: 1000,
    willingToRelocate: true,
    preferredStates: const ['Delhi', 'Karnataka', 'Maharashtra', 'Telangana'],
    willingToWorkAnywhereInIndia: true,
    careerInterests: const [
      'Computer Science',
      'Engineering',
      'Administration',
      'Research',
    ],
  );

  @override
  Future<CandidateProfile> getProfile(String candidateId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _profile;
  }

  @override
  Future<CandidateProfile> updateProfile(CandidateProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _profile = profile;
    return _profile;
  }
}
