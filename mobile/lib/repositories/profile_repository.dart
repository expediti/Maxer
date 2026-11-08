import 'package:flutter/foundation.dart';
import '../core/supabase_client.dart';
import '../models/candidate_profile.dart';
import '../models/examination.dart';

abstract class ProfileRepository {
  Future<CandidateProfile> getProfile(String candidateId);
  Future<CandidateProfile> updateProfile(CandidateProfile profile);
}

class SupabaseProfileRepository implements ProfileRepository {
  CandidateProfile _localProfile = const CandidateProfile(
    id: 'candidate-rexam-001',
    email: 'arjun.sharma@rexam.in',
    fullName: 'Arjun Sharma',
    gender: 'Male',
    nationality: 'Indian',
    state: 'Delhi',
    district: 'New Delhi',
    countryOfResidence: 'India',
    socialCategory: 'OBC-NCL',
    isPwBD: false,
    isExServiceman: false,
    highestQualification: 'B.Tech / B.E.',
    degreeName: 'Bachelor of Technology',
    stream: 'Computer Science & Engineering',
    institution: 'Delhi Technological University (DTU)',
    isInstitutionRecognized: true,
    graduationYear: 2024,
    cgpaOrPercentage: 78.5,
    hasActiveBacklogs: false,
    gateScore: 682,
    gateYear: 2025,
    hasNetJrf: false,
    workExperienceYears: 1.5,
    preferredCategories: [
      ExaminationCategory.govtRecruitment,
      ExaminationCategory.psu,
      ExaminationCategory.scholarship,
    ],
    maxApplicationFeeBudget: 1000,
    willingToRelocate: true,
    preferredStates: ['Delhi', 'Karnataka', 'Maharashtra'],
    willingToWorkAnywhereInIndia: true,
    careerInterests: ['Computer Science', 'Engineering', 'Administration', 'Research'],
  );

  @override
  Future<CandidateProfile> getProfile(String candidateId) async {
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final profileRes = await client.from('profiles').select().eq('id', candidateId).maybeSingle();
        final eduRes = await client.from('candidate_education').select().eq('candidate_id', candidateId).maybeSingle();
        final prefRes = await client.from('candidate_preferences').select().eq('candidate_id', candidateId).maybeSingle();

        if (profileRes != null) {
          final dob = profileRes['date_of_birth'] != null ? DateTime.tryParse(profileRes['date_of_birth']) : null;
          final categories = (prefRes?['preferred_categories'] as List?)?.map((c) => ExaminationCategory.fromString(c.toString())).toList() ?? [];

          return CandidateProfile(
            id: profileRes['id'] ?? candidateId,
            email: profileRes['email'] ?? 'candidate@rexam.in',
            fullName: profileRes['full_name'] ?? '',
            dateOfBirth: dob,
            gender: profileRes['gender'],
            nationality: profileRes['nationality'] ?? 'Indian',
            state: profileRes['state'],
            district: profileRes['district'],
            countryOfResidence: profileRes['country_of_residence'] ?? 'India',
            socialCategory: profileRes['social_category'] ?? 'General',
            isPwBD: profileRes['is_pwbd'] == true,
            pwbdDisabilityType: profileRes['pwbd_disability_type'],
            isExServiceman: profileRes['is_ex_serviceman'] == true,
            highestQualification: eduRes?['highest_qualification'],
            degreeName: eduRes?['degree_name'],
            stream: eduRes?['stream'],
            institution: eduRes?['institution'],
            graduationYear: eduRes?['graduation_year'],
            cgpaOrPercentage: eduRes?['cgpa_or_percentage'] != null ? double.tryParse(eduRes!['cgpa_or_percentage'].toString()) : null,
            hasActiveBacklogs: eduRes?['has_active_backlogs'] == true,
            gateScore: eduRes?['gate_score'],
            gateYear: eduRes?['gate_year'],
            hasNetJrf: eduRes?['has_net_jrf'] == true,
            workExperienceYears: eduRes?['work_experience_years'] != null ? double.tryParse(eduRes!['work_experience_years'].toString()) ?? 0.0 : 0.0,
            preferredCategories: categories.isNotEmpty ? categories : [ExaminationCategory.govtRecruitment, ExaminationCategory.psu],
            willingToRelocate: prefRes?['willing_to_relocate'] ?? true,
            preferredStates: (prefRes?['preferred_states'] as List?)?.map((s) => s.toString()).toList() ?? [],
            maxApplicationFeeBudget: prefRes?['max_application_fee_budget'],
            careerInterests: (prefRes?['career_interests'] as List?)?.map((c) => c.toString()).toList() ?? ['Engineering', 'Computer Science'],
          );
        }
      } catch (e) {
        debugPrint('[REXAM] Fetch profile from Supabase error: $e');
      }
    }

    return _localProfile;
  }

  @override
  Future<CandidateProfile> updateProfile(CandidateProfile profile) async {
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.from('profiles').upsert({
          'id': profile.id,
          'email': profile.email,
          'full_name': profile.fullName,
          'date_of_birth': profile.dateOfBirth?.toIso8601String().split('T').first,
          'gender': profile.gender,
          'nationality': profile.nationality,
          'state': profile.state,
          'district': profile.district,
          'social_category': profile.socialCategory,
          'is_pwbd': profile.isPwBD,
          'is_ex_serviceman': profile.isExServiceman,
          'updated_at': DateTime.now().toIso8601String(),
        });

        if (profile.highestQualification != null) {
          await client.from('candidate_education').upsert({
            'candidate_id': profile.id,
            'highest_qualification': profile.highestQualification,
            'degree_name': profile.degreeName,
            'stream': profile.stream,
            'institution': profile.institution,
            'graduation_year': profile.graduationYear,
            'cgpa_or_percentage': profile.cgpaOrPercentage,
            'has_active_backlogs': profile.hasActiveBacklogs,
            'gate_score': profile.gateScore,
            'gate_year': profile.gateYear,
            'has_net_jrf': profile.hasNetJrf,
            'work_experience_years': profile.workExperienceYears,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'candidate_id');
        }

        await client.from('candidate_preferences').upsert({
          'candidate_id': profile.id,
          'preferred_categories': profile.preferredCategories.map((c) => c.label).toList(),
          'preferred_states': profile.preferredStates,
          'willing_to_relocate': profile.willingToRelocate,
          'max_application_fee_budget': profile.maxApplicationFeeBudget,
          'career_interests': profile.careerInterests,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'candidate_id');
      } catch (e) {
        debugPrint('[REXAM] Update profile to Supabase error: $e');
      }
    }

    _localProfile = profile;
    return _localProfile;
  }
}

