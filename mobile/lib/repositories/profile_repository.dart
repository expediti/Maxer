import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/candidate_profile.dart';
import '../models/examination.dart';

abstract class ProfileRepository {
  Future<CandidateProfile?> getProfile(String candidateId);
  Future<CandidateProfile> updateProfile(CandidateProfile profile);
  Future<String?> uploadAvatar({required String candidateId, required Uint8List bytes, String fileExtension = 'png'});
}

class SupabaseProfileRepository implements ProfileRepository {
  @override
  Future<CandidateProfile?> getProfile(String candidateId) async {
    final client = SupabaseConfig.client;
    if (client == null || candidateId.trim().isEmpty) {
      return null;
    }

    try {
      final profileRes = await client
          .from('profiles')
          .select()
          .eq('id', candidateId)
          .maybeSingle();

      if (profileRes == null) {
        return null;
      }

      final eduRes = await client
          .from('candidate_education')
          .select()
          .eq('candidate_id', candidateId)
          .maybeSingle();

      final prefRes = await client
          .from('candidate_preferences')
          .select()
          .eq('candidate_id', candidateId)
          .maybeSingle();

      final dob = profileRes['date_of_birth'] != null
          ? DateTime.tryParse(profileRes['date_of_birth'])
          : null;

      final categories = (prefRes?['preferred_categories'] as List?)
              ?.map((c) => ExaminationCategory.fromString(c.toString()))
              .toList() ??
          [];

      final edu = eduRes;
      final rawCerts = (edu?['certifications'] as List?)?.map((e) => e.toString()).toList() ?? [];
      String? encodedGradingSystem;
      double? encodedScaleMax;
      for (final c in rawCerts) {
        if (c.startsWith('grading_system:')) {
          encodedGradingSystem = c.substring('grading_system:'.length).trim();
        } else if (c.startsWith('grading_scale_max:')) {
          encodedScaleMax = double.tryParse(c.substring('grading_scale_max:'.length).trim());
        }
      }

      final resolvedSystem = edu?['grading_system']?.toString() ??
          encodedGradingSystem ??
          (edu?['cgpa'] != null ? 'cgpa' : (edu?['percentage'] != null ? 'percentage' : 'cgpa'));

      final resolvedScaleMax = edu?['grading_scale_max'] != null
          ? (double.tryParse(edu!['grading_scale_max'].toString()) ??
              (resolvedSystem == 'percentage' ? 100.0 : (resolvedSystem == 'gpa' ? 4.0 : 10.0)))
          : (encodedScaleMax ??
              (resolvedSystem == 'percentage' ? 100.0 : (resolvedSystem == 'gpa' ? 4.0 : 10.0)));

      double? parsedCgpa = edu?['cgpa'] != null ? double.tryParse(edu!['cgpa'].toString()) : null;
      double? parsedPercentage = edu?['percentage'] != null ? double.tryParse(edu!['percentage'].toString()) : null;
      double? parsedGpa = edu?['gpa'] != null ? double.tryParse(edu!['gpa'].toString()) : null;

      final rawScore = edu?['cgpa_or_percentage'] != null ? double.tryParse(edu!['cgpa_or_percentage'].toString()) : null;
      if (rawScore != null) {
        if (resolvedSystem == 'cgpa' && parsedCgpa == null) parsedCgpa = rawScore;
        if (resolvedSystem == 'percentage' && parsedPercentage == null) parsedPercentage = rawScore;
        if (resolvedSystem == 'gpa' && parsedGpa == null) parsedGpa = rawScore;
      }

      final activeScoreValue = parsedCgpa ?? parsedPercentage ?? parsedGpa ?? rawScore;
      AcademicScore? resolvedAcademicScore;
      if (activeScoreValue != null) {
        resolvedAcademicScore = AcademicScore(
          scoreValue: activeScoreValue,
          gradingType: AcademicGradingType.fromString(resolvedSystem),
          gradingScaleMax: resolvedScaleMax,
        );
      }

      return CandidateProfile(
        id: profileRes['id'] ?? candidateId,
        email: profileRes['email'] ?? '',
        fullName: profileRes['full_name'] ?? '',
        dateOfBirth: dob,
        gender: profileRes['gender'],
        nationality: profileRes['nationality'] ?? 'Indian',
        state: profileRes['state'],
        district: profileRes['district'],
        avatarUrl: profileRes['avatar_url']?.toString(),
        countryOfResidence: profileRes['country_of_residence'] ?? 'India',
        socialCategory: profileRes['social_category'] ?? 'General',
        isObcNcl: profileRes['is_obc_ncl'] == true,
        isPwBD: profileRes['is_pwbd'] == true,
        pwbdDisabilityType: profileRes['pwbd_disability_type'],
        isExServiceman: profileRes['is_ex_serviceman'] == true,
        currentStatus: profileRes['current_status'],
        class10Year: profileRes['class_10_year'],
        class10Percentage: profileRes['class_10_percentage'] != null
            ? double.tryParse(profileRes['class_10_percentage'].toString())
            : null,
        class12Year: profileRes['class_12_year'],
        class12Stream: profileRes['class_12_stream'],
        class12Percentage: profileRes['class_12_percentage'] != null
            ? double.tryParse(profileRes['class_12_percentage'].toString())
            : null,
        class12GradingSystem: profileRes['class_12_grading_system']?.toString() ?? 'percentage',
        highestQualification: edu?['highest_qualification'],
        degreeName: edu?['degree_name'],
        stream: edu?['stream'],
        institution: edu?['institution'],
        university: edu?['university'] ?? edu?['institution'],
        collegeName: edu?['college_name'],
        currentYearOfStudy: edu?['current_year_of_study'] != null
            ? int.tryParse(edu!['current_year_of_study'].toString())
            : null,
        currentSemester: edu?['current_semester'] != null
            ? int.tryParse(edu!['current_semester'].toString())
            : null,
        degreeDurationYears: edu?['degree_duration_years'] != null
            ? int.tryParse(edu!['degree_duration_years'].toString()) ?? 4
            : 4,
        academicStatus: edu?['academic_status']?.toString() ??
            (edu?['is_completed'] == false ? 'pursuing' : 'completed'),
        gradingSystem: resolvedSystem,
        gradingScaleMax: resolvedScaleMax,
        cgpa: parsedCgpa,
        percentage: parsedPercentage,
        gpa: parsedGpa,
        academicScore: resolvedAcademicScore,
        yearWisePerformance: edu?['year_wise_performance'] is Map
            ? Map<String, dynamic>.from(edu!['year_wise_performance'])
            : const {},
        semesterWisePerformance: edu?['semester_wise_performance'] is Map
            ? Map<String, dynamic>.from(edu!['semester_wise_performance'])
            : const {},
        conversionFormula: eduRes?['conversion_formula']?.toString(),
        conversionSource: eduRes?['conversion_source']?.toString(),
        graduationYear: eduRes?['graduation_year'],
        cgpaOrPercentage: activeScoreValue,
        degreeStatus: eduRes?['is_completed'] == false ? 'Ongoing' : 'Completed',
        hasActiveBacklogs: eduRes?['has_active_backlogs'] == true,
        gateScore: eduRes?['gate_score'],
        gateYear: eduRes?['gate_year'],
        hasNetJrf: eduRes?['has_net_jrf'] == true,
        workExperienceYears: eduRes?['work_experience_years'] != null
            ? double.tryParse(eduRes!['work_experience_years'].toString()) ?? 0.0
            : 0.0,
        preferredCategories: categories,
        willingToRelocate: prefRes?['willing_to_relocate'] ?? true,
        preferredStates: (prefRes?['preferred_states'] as List?)
                ?.map((s) => s.toString())
                .toList() ??
            [],
        maxApplicationFeeBudget: prefRes?['max_application_fee_budget'],
        careerInterests: (prefRes?['career_interests'] as List?)
                ?.map((c) => c.toString())
                .toList() ??
            [],
      );
    } catch (e) {
      debugPrint('[REXAM] Fetch profile from Supabase error: $e');
      return null;
    }
  }

  @override
  Future<CandidateProfile> updateProfile(CandidateProfile profile) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw Exception('Supabase connection unavailable. Cannot persist profile.');
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();

    try {
      // 1. Upsert into public.profiles
      try {
        await client.from('profiles').upsert(
          {
            'id': profile.id,
            'email': profile.email,
            'full_name': profile.fullName,
            'date_of_birth': profile.dateOfBirth?.toIso8601String().split('T').first,
            'gender': profile.gender,
            'nationality': profile.nationality,
            'state': profile.state,
            'district': profile.district,
            'avatar_url': profile.avatarUrl,
            'country_of_residence': profile.countryOfResidence,
            'current_status': profile.currentStatus,
            'social_category': profile.socialCategory,
            'is_obc_ncl': profile.isObcNcl,
            'is_pwbd': profile.isPwBD,
            'pwbd_disability_type': profile.pwbdDisabilityType,
            'is_ex_serviceman': profile.isExServiceman,
            'class_10_year': profile.class10Year,
            'class_10_percentage': profile.class10Percentage,
            'class_12_year': profile.class12Year,
            'class_12_stream': profile.class12Stream,
            'class_12_percentage': profile.class12Percentage,
            'class_12_grading_system': profile.class12GradingSystem,
            'onboarding_completed_at': nowIso,
            'updated_at': nowIso,
          },
          onConflict: 'id',
        );
      } catch (profileErr) {
        debugPrint('[REXAM] Extended profile upsert note, falling back to core columns: $profileErr');
        await client.from('profiles').upsert(
          {
            'id': profile.id,
            'email': profile.email,
            'full_name': profile.fullName,
            'date_of_birth': profile.dateOfBirth?.toIso8601String().split('T').first,
            'gender': profile.gender,
            'nationality': profile.nationality,
            'state': profile.state,
            'district': profile.district,
            'avatar_url': profile.avatarUrl,
            'country_of_residence': profile.countryOfResidence,
            'social_category': profile.socialCategory,
            'is_pwbd': profile.isPwBD,
            'pwbd_disability_type': profile.pwbdDisabilityType,
            'is_ex_serviceman': profile.isExServiceman,
            'class_10_year': profile.class10Year,
            'class_12_year': profile.class12Year,
            'class_12_stream': profile.class12Stream,
            'updated_at': nowIso,
          },
          onConflict: 'id',
        );
      }

      // 2. Persist candidate_education safely
      try {
        final existingEdu = await client
            .from('candidate_education')
            .select('id')
            .eq('candidate_id', profile.id)
            .maybeSingle();

        final systemMetaTag = 'grading_system:${profile.gradingSystem}';
        final scaleMetaTag = 'grading_scale_max:${profile.gradingScaleMax}';
        final preservedCerts = List<String>.from(profile.certifications)
          ..removeWhere((c) => c.startsWith('grading_system:') || c.startsWith('grading_scale_max:'))
          ..addAll([systemMetaTag, scaleMetaTag]);

        final baseEduData = {
          'candidate_id': profile.id,
          'highest_qualification': profile.highestQualification ?? 'Undergraduate',
          'degree_name': profile.degreeName,
          'stream': profile.stream,
          'institution': profile.institution,
          'graduation_year': profile.graduationYear,
          'cgpa_or_percentage': profile.effectiveScore,
          'has_active_backlogs': profile.hasActiveBacklogs,
          'gate_score': profile.gateScore,
          'gate_year': profile.gateYear,
          'has_net_jrf': profile.hasNetJrf,
          'work_experience_years': profile.workExperienceYears,
          'certifications': preservedCerts,
          'updated_at': nowIso,
        };

        final extendedEduData = {
          ...baseEduData,
          'university': profile.university ?? profile.institution,
          'college_name': profile.collegeName,
          'current_year_of_study': profile.currentYearOfStudy,
          'current_semester': profile.currentSemester,
          'degree_duration_years': profile.degreeDurationYears,
          'academic_status': profile.academicStatus,
          'grading_system': profile.gradingSystem,
          'grading_scale_max': profile.gradingScaleMax,
          'cgpa': profile.cgpa,
          'percentage': profile.percentage,
          'gpa': profile.gpa,
          'year_wise_performance': profile.yearWisePerformance,
          'semester_wise_performance': profile.semesterWisePerformance,
          'conversion_formula': profile.conversionFormula,
          'conversion_source': profile.conversionSource,
          'is_completed': profile.isGraduated,
        };

        try {
          if (existingEdu != null) {
            await client
                .from('candidate_education')
                .update(extendedEduData)
                .eq('candidate_id', profile.id);
          } else {
            await client.from('candidate_education').insert(extendedEduData);
          }
        } catch (extErr) {
          debugPrint('[REXAM] Extended education update notice: $extErr. Falling back to base fields with metadata encoding.');
          if (existingEdu != null) {
            await client
                .from('candidate_education')
                .update(baseEduData)
                .eq('candidate_id', profile.id);
          } else {
            await client.from('candidate_education').insert(baseEduData);
          }
        }
      } catch (eduErr) {
        debugPrint('[REXAM] Candidate education save warning: $eduErr');
      }

      // 3. Persist candidate_preferences safely
      try {
        final existingPref = await client
            .from('candidate_preferences')
            .select('id')
            .eq('candidate_id', profile.id)
            .maybeSingle();

        final prefData = {
          'candidate_id': profile.id,
          'preferred_categories': profile.preferredCategories.map((c) => c.label).toList(),
          'preferred_states': profile.preferredStates,
          'willing_to_relocate': profile.willingToRelocate,
          'willing_to_work_anywhere_in_india': profile.willingToWorkAnywhereInIndia,
          'max_application_fee_budget': profile.maxApplicationFeeBudget,
          'career_interests': profile.careerInterests,
          'updated_at': nowIso,
        };

        if (existingPref != null) {
          await client
              .from('candidate_preferences')
              .update(prefData)
              .eq('candidate_id', profile.id);
        } else {
          await client.from('candidate_preferences').insert(prefData);
        }
      } catch (prefErr) {
        debugPrint('[REXAM] Candidate preferences save warning: $prefErr');
      }

      // 4. Return updated profile
      final verified = await getProfile(profile.id);
      return verified ?? profile;
    } catch (e) {
      debugPrint('[REXAM] Update profile Supabase critical error: $e');
      throw Exception('Failed to persist profile: $e');
    }
  }

  @override
  Future<String?> uploadAvatar({
    required String candidateId,
    required Uint8List bytes,
    String fileExtension = 'png',
  }) async {
    final client = SupabaseConfig.client;
    if (client == null || candidateId.trim().isEmpty) return null;

    try {
      final fileName = '$candidateId/avatar.$fileExtension';
      await client.storage.from('profile-avatars').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/png'),
      );

      final publicUrl = client.storage.from('profile-avatars').getPublicUrl(fileName);

      await client.from('profiles').update({
        'avatar_url': publicUrl,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', candidateId);

      return publicUrl;
    } catch (e) {
      debugPrint('[REXAM] Avatar upload error: $e');
      return null;
    }
  }
}
