import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/candidate_profile.dart';
import '../../../models/examination.dart';
import '../../../repositories/profile_repository.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'providers/profile_provider.dart';

/// 6-Step Mandatory Candidate Profile Onboarding Wizard
/// Real Supabase persistence for profiles, candidate_education, and candidate_preferences.
class ProfileWizardScreen extends ConsumerStatefulWidget {
  const ProfileWizardScreen({super.key});

  @override
  ConsumerState<ProfileWizardScreen> createState() => _ProfileWizardScreenState();
}

class _ProfileWizardScreenState extends ConsumerState<ProfileWizardScreen> {
  int _currentStep = 0;
  static const int _totalSteps = 6;
  bool _isSaving = false;
  bool _isLoadingInitial = true;

  // Step 1: Basic Information
  late TextEditingController _nameController;
  DateTime? _selectedDob;
  String _selectedGender = 'Male';
  final String _nationality = 'Indian';
  String _selectedState = 'Delhi (NCT)';
  late TextEditingController _districtController;

  // Step 2: Current Background
  String _currentStatus = 'Pursuing undergraduate degree';

  // Step 3: Educational Qualifications
  late TextEditingController _class10Controller;
  late TextEditingController _class12Controller;
  String _class12Stream = 'Science (PCM - Physics, Chemistry, Maths)';
  String _highestQualification = 'B.Tech / B.E.';
  late TextEditingController _degreeController;
  late TextEditingController _streamController;
  late TextEditingController _institutionController;
  late TextEditingController _universityController;
  late TextEditingController _collegeController;
  late TextEditingController _graduationYearController;
  late TextEditingController _cgpaController;
  late TextEditingController _year1ScoreController;
  late TextEditingController _year2ScoreController;
  late TextEditingController _year3ScoreController;
  late TextEditingController _year4ScoreController;
  int _currentYearOfStudy = 3;
  int _currentSemester = 5;
  int _degreeDurationYears = 4;
  String _academicStatus = 'pursuing';
  String _gradingSystem = 'cgpa';
  double _gradingScaleMax = 10.0;
  bool _showYearWisePerformance = false;
  String _degreeStatus = 'Completed';
  bool _hasActiveBacklogs = false;
  late TextEditingController _gateScoreController;
  final bool _hasNetJrf = false;

  // Step 4: Category & Reservation
  String _socialCategory = 'General';
  bool _isObcNcl = false;
  bool _isPwBD = false;
  late TextEditingController _disabilityController;
  bool _isExServiceman = false;

  // Step 5: Career Preferences
  final Set<String> _selectedCareerStreams = {
    'UPSC',
    'Defence',
    'Engineering recruitment',
    'Research and science',
  };
  bool _willingToRelocate = true;

  static const List<String> _indianStates = [
    'All India',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman & Nicobar Islands',
    'Chandigarh',
    'Dadra & Nagar Haveli and Daman & Diu',
    'Delhi (NCT)',
    'Jammu & Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  static const List<String> _backgroundOptions = [
    'Studying in school',
    'Completed Class 12',
    'Pursuing undergraduate degree',
    'Completed undergraduate degree',
    'Pursuing postgraduate degree',
    'Completed postgraduate degree',
    'Working professional',
    'Preparing for competitive examinations',
    'Other',
  ];

  static const List<String> _class12StreamOptions = [
    'Science (PCM - Physics, Chemistry, Maths)',
    'Science (PCB - Physics, Chemistry, Biology)',
    'Science (PCMB)',
    'Commerce with Maths',
    'Commerce without Maths',
    'Arts / Humanities',
    'Vocational / Technical',
  ];

  static const List<String> _qualOptions = [
    'Class 10',
    'Class 12',
    'Diploma / Polytechnic',
    'B.Tech / B.E.',
    "Bachelor's Degree (B.Sc / B.A / B.Com / BCA)",
    "Master's Degree (M.Tech / M.Sc / MBA / MCA)",
    'Doctorate (Ph.D)',
    'Other Professional Qualification',
  ];

  static const List<String> _allCareerStreams = [
    'UPSC',
    'SSC',
    'Banking',
    'Railways',
    'State PSC',
    'Defence',
    'Engineering recruitment',
    'Research and science',
    'Higher education',
    'Scholarships',
    'Teaching',
    'Other government opportunities',
  ];

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    final user = authState.user;

    _nameController = TextEditingController(text: user?.displayName ?? '');
    _districtController = TextEditingController();
    _class10Controller = TextEditingController(text: '2018');
    _class12Controller = TextEditingController(text: '2020');
    _degreeController = TextEditingController(text: 'B.Tech');
    _streamController = TextEditingController(text: 'Computer Science');
    _institutionController = TextEditingController();
    _universityController = TextEditingController();
    _collegeController = TextEditingController();
    _graduationYearController = TextEditingController(text: '2024');
    _cgpaController = TextEditingController(text: '8.2');
    _year1ScoreController = TextEditingController();
    _year2ScoreController = TextEditingController();
    _year3ScoreController = TextEditingController();
    _year4ScoreController = TextEditingController();
    _gateScoreController = TextEditingController();
    _disabilityController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
    });
  }

  Future<void> _loadExistingData() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null) {
      if (mounted) setState(() => _isLoadingInitial = false);
      return;
    }

    try {
      final repo = SupabaseProfileRepository();
      final existing = await repo.getProfile(user.id);
      if (existing != null && mounted) {
        setState(() {
          if (existing.fullName.trim().isNotEmpty) {
            _nameController.text = existing.fullName;
          }
          if (existing.dateOfBirth != null) {
            _selectedDob = existing.dateOfBirth;
          }
          if (existing.gender != null && existing.gender!.isNotEmpty) {
            _selectedGender = existing.gender!;
          }
          if (existing.state != null && existing.state!.isNotEmpty) {
            _selectedState = existing.state!;
          }
          if (existing.district != null && existing.district!.isNotEmpty) {
            _districtController.text = existing.district!;
          }
          if (existing.currentStatus != null && existing.currentStatus!.isNotEmpty) {
            _currentStatus = existing.currentStatus!;
          }
          if (existing.class10Year != null) {
            _class10Controller.text = existing.class10Year.toString();
          }
          if (existing.class12Year != null) {
            _class12Controller.text = existing.class12Year.toString();
          }
          if (existing.class12Stream != null && existing.class12Stream!.isNotEmpty) {
            _class12Stream = existing.class12Stream!;
          }
          if (existing.highestQualification != null && existing.highestQualification!.isNotEmpty) {
            _highestQualification = existing.highestQualification!;
          }
          if (existing.degreeName != null && existing.degreeName!.isNotEmpty) {
            _degreeController.text = existing.degreeName!;
          }
          if (existing.stream != null && existing.stream!.isNotEmpty) {
            _streamController.text = existing.stream!;
          }
          if (existing.institution != null && existing.institution!.isNotEmpty) {
            _institutionController.text = existing.institution!;
          }
          if (existing.university != null && existing.university!.isNotEmpty) {
            _universityController.text = existing.university!;
          }
          if (existing.collegeName != null && existing.collegeName!.isNotEmpty) {
            _collegeController.text = existing.collegeName!;
          }
          if (existing.currentYearOfStudy != null) {
            _currentYearOfStudy = existing.currentYearOfStudy!;
          }
          if (existing.currentSemester != null) {
            _currentSemester = existing.currentSemester!;
          }
          _degreeDurationYears = existing.degreeDurationYears;
          _academicStatus = existing.academicStatus;
          _gradingSystem = existing.gradingSystem;
          _gradingScaleMax = existing.gradingScaleMax;
          if (existing.cgpa != null) {
            _cgpaController.text = existing.cgpa.toString();
          } else if (existing.percentage != null) {
            _cgpaController.text = existing.percentage.toString();
          }
          if (existing.yearWisePerformance.isNotEmpty) {
            _year1ScoreController.text = existing.yearWisePerformance['year_1']?.toString() ?? '';
            _year2ScoreController.text = existing.yearWisePerformance['year_2']?.toString() ?? '';
            _year3ScoreController.text = existing.yearWisePerformance['year_3']?.toString() ?? '';
            _year4ScoreController.text = existing.yearWisePerformance['year_4']?.toString() ?? '';
            _showYearWisePerformance = true;
          }
          if (existing.graduationYear != null) {
            _graduationYearController.text = existing.graduationYear.toString();
          }
          if (existing.cgpaOrPercentage != null) {
            _cgpaController.text = existing.cgpaOrPercentage.toString();
          }
          _degreeStatus = existing.degreeStatus ?? 'Completed';
          _hasActiveBacklogs = existing.hasActiveBacklogs;
          if (existing.gateScore != null) {
            _gateScoreController.text = existing.gateScore.toString();
          }
          if (existing.socialCategory.isNotEmpty) {
            _socialCategory = existing.socialCategory;
          }
          _isObcNcl = existing.isObcNcl;
          _isPwBD = existing.isPwBD;
          if (existing.pwbdDisabilityType != null && existing.pwbdDisabilityType!.isNotEmpty) {
            _disabilityController.text = existing.pwbdDisabilityType!;
          }
          _isExServiceman = existing.isExServiceman;
          if (existing.careerInterests.isNotEmpty) {
            _selectedCareerStreams.clear();
            _selectedCareerStreams.addAll(existing.careerInterests);
          }
          _willingToRelocate = existing.willingToRelocate;

          // Resume from the first incomplete step
          final bool hasValidStep0 = _nameController.text.trim().isNotEmpty && _selectedDob != null;
          final bool hasValidStep2 = _degreeController.text.trim().isNotEmpty && _streamController.text.trim().isNotEmpty;

          if (!hasValidStep0) {
            _currentStep = 0;
          } else if (_currentStatus.isEmpty) {
            _currentStep = 1;
          } else if (!hasValidStep2) {
            _currentStep = 2;
          } else {
            // Already has demographic and qualification details: start at review
            _currentStep = 5;
          }
        });
      }
    } catch (e) {
      debugPrint('[REXAM] Wizard data load error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _districtController.dispose();
    _class10Controller.dispose();
    _class12Controller.dispose();
    _degreeController.dispose();
    _streamController.dispose();
    _institutionController.dispose();
    _universityController.dispose();
    _collegeController.dispose();
    _graduationYearController.dispose();
    _cgpaController.dispose();
    _year1ScoreController.dispose();
    _year2ScoreController.dispose();
    _year3ScoreController.dispose();
    _year4ScoreController.dispose();
    _gateScoreController.dispose();
    _disabilityController.dispose();
    super.dispose();
  }

  int? get _calculatedAge {
    if (_selectedDob == null) return null;
    final now = DateTime.now();
    int age = now.year - _selectedDob!.year;
    if (now.month < _selectedDob!.month ||
        (now.month == _selectedDob!.month && now.day < _selectedDob!.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2002, 1, 1),
      firstDate: DateTime(1960),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 14)),
      helpText: 'SELECT CANDIDATE DATE OF BIRTH',
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.white,
              onPrimary: AppColors.black,
              surface: AppColors.cardBackground,
              onSurface: AppColors.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        _showWarning('Please enter your full legal name.');
        return;
      }
      if (_selectedDob == null) {
        _showWarning('Date of birth is mandatory for statutory eligibility calculation.');
        return;
      }
    }

    if (_currentStep == 2) {
      if (_degreeController.text.trim().isEmpty) {
        _showWarning('Please specify your current or highest degree title.');
        return;
      }
      if (_streamController.text.trim().isEmpty) {
        _showWarning('Please specify your degree discipline/branch.');
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: AppColors.primaryText)),
        backgroundColor: AppColors.cardBackground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  Future<void> _completeProfile() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null) {
      _showWarning('Authentication session expired. Please sign in again.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final c10 = int.tryParse(_class10Controller.text.trim());
      final c12 = int.tryParse(_class12Controller.text.trim());
      final grad = int.tryParse(_graduationYearController.text.trim()) ?? 2024;
      final score = double.tryParse(_cgpaController.text.trim());
      final gate = int.tryParse(_gateScoreController.text.trim());

      final List<ExaminationCategory> preferredCategories = [];
      if (_selectedCareerStreams.contains('UPSC') ||
          _selectedCareerStreams.contains('SSC') ||
          _selectedCareerStreams.contains('State PSC') ||
          _selectedCareerStreams.contains('Other government opportunities')) {
        preferredCategories.add(ExaminationCategory.govtRecruitment);
      }
      if (_selectedCareerStreams.contains('Banking') ||
          _selectedCareerStreams.contains('Railways') ||
          _selectedCareerStreams.contains('Engineering recruitment')) {
        preferredCategories.add(ExaminationCategory.psu);
      }
      if (_selectedCareerStreams.contains('Research and science') ||
          _selectedCareerStreams.contains('Higher education') ||
          _selectedCareerStreams.contains('Scholarships')) {
        preferredCategories.add(ExaminationCategory.entranceExam);
      }
      if (preferredCategories.isEmpty) {
        preferredCategories.add(ExaminationCategory.govtRecruitment);
      }

      final Map<String, dynamic> yearMap = {};
      final y1 = double.tryParse(_year1ScoreController.text.trim());
      final y2 = double.tryParse(_year2ScoreController.text.trim());
      final y3 = double.tryParse(_year3ScoreController.text.trim());
      final y4 = double.tryParse(_year4ScoreController.text.trim());
      if (y1 != null) yearMap['year_1'] = y1;
      if (y2 != null) yearMap['year_2'] = y2;
      if (y3 != null) yearMap['year_3'] = y3;
      if (y4 != null) yearMap['year_4'] = y4;

      final resolvedUniversity = _universityController.text.trim().isNotEmpty
          ? _universityController.text.trim()
          : (_institutionController.text.trim().isNotEmpty ? _institutionController.text.trim() : null);
      final resolvedCollege = _collegeController.text.trim().isNotEmpty
          ? _collegeController.text.trim()
          : null;

      final profile = CandidateProfile(
        id: user.id,
        email: user.email,
        fullName: _nameController.text.trim(),
        dateOfBirth: _selectedDob,
        gender: _selectedGender,
        nationality: _nationality,
        state: _selectedState,
        district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
        currentStatus: _currentStatus,
        socialCategory: _socialCategory,
        isObcNcl: _socialCategory == 'OBC' && _isObcNcl,
        isPwBD: _isPwBD,
        pwbdDisabilityType: _isPwBD && _disabilityController.text.trim().isNotEmpty
            ? _disabilityController.text.trim()
            : null,
        isExServiceman: _isExServiceman,
        class10Year: c10,
        class12Year: c12,
        class12Stream: _class12Stream,
        highestQualification: _highestQualification,
        degreeName: _degreeController.text.trim().isEmpty ? null : _degreeController.text.trim(),
        stream: _streamController.text.trim().isEmpty ? null : _streamController.text.trim(),
        institution: resolvedCollege ?? resolvedUniversity,
        university: resolvedUniversity,
        collegeName: resolvedCollege,
        currentYearOfStudy: _academicStatus == 'pursuing' ? _currentYearOfStudy : null,
        currentSemester: _academicStatus == 'pursuing' ? _currentSemester : null,
        degreeDurationYears: _degreeDurationYears,
        academicStatus: _academicStatus,
        gradingSystem: _gradingSystem,
        gradingScaleMax: _gradingScaleMax,
        cgpa: _gradingSystem == 'cgpa' ? score : null,
        percentage: _gradingSystem == 'percentage' ? score : null,
        gpa: _gradingSystem == 'gpa' ? score : null,
        academicScore: score != null
            ? AcademicScore(
                scoreValue: score,
                gradingType: AcademicGradingType.fromString(_gradingSystem),
                gradingScaleMax: _gradingScaleMax,
              )
            : null,
        yearWisePerformance: yearMap,
        graduationYear: grad,
        cgpaOrPercentage: score,
        degreeStatus: _academicStatus == 'completed' ? 'Completed' : 'Ongoing',
        hasActiveBacklogs: _hasActiveBacklogs,
        gateScore: gate,
        hasNetJrf: _hasNetJrf,
        preferredCategories: preferredCategories,
        careerInterests: _selectedCareerStreams.toList(),
        willingToRelocate: _willingToRelocate,
      );

      // Persist to Supabase
      await ref.read(profileProvider.notifier).updateProfile(profile);

      // Update auth state so onboarding flag is true
      await ref.read(authProvider.notifier).completeOnboarding();

      if (mounted) {
        setState(() => _isSaving = false);
        context.go('/discover');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentStep > 0) {
          _prevStep();
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: context.themeCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                side: BorderSide(color: context.themeBorder),
              ),
              title: Text('Exit Setup?', style: TextStyle(color: context.themeTextMain)),
              content: Text(
                'Candidate profile setup is required to compute statutory examination eligibility.',
                style: TextStyle(color: context.themeTextMuted),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Continue Setup'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go('/welcome');
                  },
                  child: const Text('Exit', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: context.themeBackground,
        appBar: AppBar(
          backgroundColor: context.themeBackground,
          elevation: 0,
          leading: _currentStep > 0
              ? IconButton(
                  icon: Icon(LucideIcons.arrowLeft, color: context.themeTextMain, size: 20),
                  onPressed: _prevStep,
                )
              : null,
          title: Text(
            'Candidate Onboarding',
            style: AppTypography.screenTitle.copyWith(fontSize: 16, color: context.themeTextMain),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.themeSurfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.themeBorder),
                  ),
                  child: Text(
                    'Step ${_currentStep + 1} of $_totalSteps',
                    style: TextStyle(
                      color: context.themeTextMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: _isLoadingInitial
            ? Center(
                child: CircularProgressIndicator(
                  color: context.themeTextMain,
                  strokeWidth: 2,
                ),
              )
            : Column(
                children: [
                  // Linear Progress Bar
            LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: AppColors.elevatedSurface,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
              minHeight: 2,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space20,
                  vertical: AppDimensions.space20,
                ),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Navigation Bottom Bar
            Container(
              padding: const EdgeInsets.all(AppDimensions.space16),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (_currentStep > 0) ...[
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: _prevStep,
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                    ],
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : (_currentStep == _totalSteps - 1 ? _completeProfile : _nextStep),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2),
                              )
                            : Text(_currentStep == _totalSteps - 1 ? 'Complete Profile' : 'Continue'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1BasicInfo();
      case 1:
        return _buildStep2Background();
      case 2:
        return _buildStep3Education();
      case 3:
        return _buildStep4Category();
      case 4:
        return _buildStep5Preferences();
      case 5:
        return _buildStep6Review();
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 1: Basic Information
  // ---------------------------------------------------------------------------
  Widget _buildStep1BasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Basic Information', style: AppTypography.headlineLarge.copyWith(fontSize: 22)),
        const SizedBox(height: 6),
        const Text(
          'Your legal identity, age, and state are required to calculate age relaxations and domicile quotas.',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 13.5, height: 1.4),
        ),
        const SizedBox(height: AppDimensions.space24),

        TextFormField(
          controller: _nameController,
          style: const TextStyle(color: AppColors.primaryText),
          decoration: const InputDecoration(
            labelText: 'Full Legal Name (as per matriculation) *',
            prefixIcon: Icon(LucideIcons.user, size: 18),
          ),
        ),
        const SizedBox(height: AppDimensions.space16),

        InkWell(
          onTap: _pickDateOfBirth,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.elevatedSurface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 18, color: AppColors.mutedText),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date of Birth *', style: TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          _selectedDob != null
                              ? DateFormat('d MMMM yyyy').format(_selectedDob!)
                              : 'Select Date of Birth',
                          style: TextStyle(
                            color: _selectedDob != null ? AppColors.primaryText : AppColors.mutedText,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_calculatedAge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '$_calculatedAge yrs',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.space16),

        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                dropdownColor: AppColors.elevatedSurface,
                style: const TextStyle(color: AppColors.primaryText, fontSize: 13.5),
                decoration: const InputDecoration(
                  labelText: 'Gender *',
                  prefixIcon: Icon(LucideIcons.users, size: 18),
                ),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Transgender', child: Text('Transgender')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedGender = val);
                },
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedState,
                isExpanded: true,
                dropdownColor: AppColors.elevatedSurface,
                style: const TextStyle(color: AppColors.primaryText, fontSize: 13.5),
                decoration: const InputDecoration(
                  labelText: 'Domicile State *',
                  prefixIcon: Icon(LucideIcons.mapPin, size: 18),
                ),
                items: _indianStates.map((st) => DropdownMenuItem(value: st, child: Text(st, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedState = val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space16),

        TextFormField(
          controller: _districtController,
          style: const TextStyle(color: AppColors.primaryText),
          decoration: const InputDecoration(
            labelText: 'District (Optional)',
            hintText: 'e.g. Pune, North East Delhi, Varanasi',
            prefixIcon: Icon(LucideIcons.navigation, size: 18),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: Current Background
  // ---------------------------------------------------------------------------
  Widget _buildStep2Background() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Current Background', style: AppTypography.headlineLarge.copyWith(fontSize: 22)),
        const SizedBox(height: 6),
        const Text(
          'Tell us what you are currently doing so we prioritize relevant opportunities.',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 13.5, height: 1.4),
        ),
        const SizedBox(height: AppDimensions.space20),

        ..._backgroundOptions.map((opt) {
          final isSel = _currentStatus == opt;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: InkWell(
              onTap: () => setState(() => _currentStatus = opt),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.elevatedSurface : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(color: isSel ? AppColors.white : AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: isSel ? AppColors.white : AppColors.mutedText, width: 2),
                      ),
                      child: isSel
                          ? Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        opt,
                        style: TextStyle(
                          color: isSel ? AppColors.primaryText : AppColors.secondaryText,
                          fontSize: 14,
                          fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: Educational Qualifications
  // ---------------------------------------------------------------------------
  Widget _buildStep3Education() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Educational Qualifications', style: AppTypography.headlineLarge.copyWith(fontSize: 22)),
        const SizedBox(height: 6),
        const Text(
          'Qualifications match statutory eligibility criteria across government examinations.',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 13.5, height: 1.4),
        ),
        const SizedBox(height: AppDimensions.space20),

        // 10th and 12th passing year
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _class10Controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.primaryText),
                decoration: const InputDecoration(
                  labelText: '10th Year',
                  hintText: '2018',
                  prefixIcon: Icon(LucideIcons.calendar, size: 18),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: TextFormField(
                controller: _class12Controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.primaryText),
                decoration: const InputDecoration(
                  labelText: '12th Year',
                  hintText: '2020',
                  prefixIcon: Icon(LucideIcons.calendar, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space16),

        DropdownButtonFormField<String>(
          initialValue: _class12Stream,
          isExpanded: true,
          dropdownColor: AppColors.elevatedSurface,
          style: const TextStyle(color: AppColors.primaryText, fontSize: 13),
          decoration: const InputDecoration(
            labelText: 'Class 12 Stream',
            prefixIcon: Icon(LucideIcons.bookOpen, size: 18),
          ),
          items: _class12StreamOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _class12Stream = val);
          },
        ),
        const SizedBox(height: AppDimensions.space20),

        const Divider(color: AppColors.divider),
        const SizedBox(height: AppDimensions.space16),

        DropdownButtonFormField<String>(
          initialValue: _highestQualification,
          isExpanded: true,
          dropdownColor: AppColors.elevatedSurface,
          style: const TextStyle(color: AppColors.primaryText, fontSize: 13.5),
          decoration: const InputDecoration(
            labelText: 'Current / Highest Degree Level *',
            prefixIcon: Icon(LucideIcons.graduationCap, size: 18),
          ),
          items: _qualOptions.map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _highestQualification = val);
          },
        ),
        const SizedBox(height: AppDimensions.space16),

        TextFormField(
          controller: _degreeController,
          style: const TextStyle(color: AppColors.primaryText),
          decoration: const InputDecoration(
            labelText: 'Degree Title (e.g. B.Tech / B.Sc / B.Com / B.A / MBBS) *',
            prefixIcon: Icon(LucideIcons.award, size: 18),
          ),
        ),
        const SizedBox(height: AppDimensions.space16),

        TextFormField(
          controller: _streamController,
          style: const TextStyle(color: AppColors.primaryText),
          decoration: const InputDecoration(
            labelText: 'Branch / Discipline (e.g. Computer Science, Mechanical) *',
            prefixIcon: Icon(LucideIcons.layers, size: 18),
          ),
        ),
        const SizedBox(height: AppDimensions.space16),

        TextFormField(
          controller: _universityController,
          style: const TextStyle(color: AppColors.primaryText),
          decoration: const InputDecoration(
            labelText: 'University (e.g. Delhi University, VTU, Anna University, AICTE) *',
            prefixIcon: Icon(LucideIcons.landmark, size: 18),
          ),
        ),
        const SizedBox(height: AppDimensions.space16),

        TextFormField(
          controller: _collegeController,
          style: const TextStyle(color: AppColors.primaryText),
          decoration: const InputDecoration(
            labelText: 'College Name (e.g. DTU, Hansraj, RVCE)',
            prefixIcon: Icon(LucideIcons.school, size: 18),
          ),
        ),
        const SizedBox(height: AppDimensions.space16),

        // Degree Duration
        Text('DEGREE DURATION', style: AppTypography.label.copyWith(color: AppColors.secondaryText)),
        const SizedBox(height: 6),
        Row(
          children: [3, 4, 5].map((dur) {
            final isSel = _degreeDurationYears == dur;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text('$dur Years'),
                selected: isSel,
                selectedColor: AppColors.white,
                backgroundColor: AppColors.elevatedSurface,
                labelStyle: TextStyle(
                  color: isSel ? AppColors.black : AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                side: BorderSide(color: isSel ? AppColors.white : AppColors.border),
                showCheckmark: false,
                onSelected: (selected) {
                  if (selected) setState(() => _degreeDurationYears = dur);
                },
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppDimensions.space16),

        // Academic Status
        Text('ACADEMIC COMPLETION STATUS', style: AppTypography.label.copyWith(color: AppColors.secondaryText)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Pursuing / Ongoing'),
                selected: _academicStatus == 'pursuing',
                selectedColor: AppColors.white,
                backgroundColor: AppColors.elevatedSurface,
                labelStyle: TextStyle(
                  color: _academicStatus == 'pursuing' ? AppColors.black : AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                side: BorderSide(color: _academicStatus == 'pursuing' ? AppColors.white : AppColors.border),
                showCheckmark: false,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _academicStatus = 'pursuing';
                      _degreeStatus = 'Ongoing';
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Text('Completed / Graduated'),
                selected: _academicStatus == 'completed',
                selectedColor: AppColors.white,
                backgroundColor: AppColors.elevatedSurface,
                labelStyle: TextStyle(
                  color: _academicStatus == 'completed' ? AppColors.black : AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                side: BorderSide(color: _academicStatus == 'completed' ? AppColors.white : AppColors.border),
                showCheckmark: false,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _academicStatus = 'completed';
                      _degreeStatus = 'Completed';
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space16),

        // If Pursuing: Year & Semester
        if (_academicStatus == 'pursuing') ...[
          Text('CURRENT YEAR OF STUDY', style: AppTypography.label.copyWith(color: AppColors.secondaryText)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_degreeDurationYears, (i) => i + 1).map((yr) {
                final isSel = _currentYearOfStudy == yr;
                final isFinal = yr == _degreeDurationYears;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(isFinal ? 'Year $yr (Final)' : 'Year $yr'),
                    selected: isSel,
                    selectedColor: AppColors.white,
                    backgroundColor: AppColors.elevatedSurface,
                    labelStyle: TextStyle(
                      color: isSel ? AppColors.black : AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    side: BorderSide(color: isSel ? AppColors.white : AppColors.border),
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) setState(() => _currentYearOfStudy = yr);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppDimensions.space16),

          Text('CURRENT SEMESTER', style: AppTypography.label.copyWith(color: AppColors.secondaryText)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_degreeDurationYears * 2, (i) => i + 1).map((sem) {
                final isSel = _currentSemester == sem;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text('Sem $sem'),
                    selected: isSel,
                    selectedColor: AppColors.white,
                    backgroundColor: AppColors.elevatedSurface,
                    labelStyle: TextStyle(
                      color: isSel ? AppColors.black : AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                    side: BorderSide(color: isSel ? AppColors.white : AppColors.border),
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) setState(() => _currentSemester = sem);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppDimensions.space16),
        ],

        // Expected or Actual Graduation Year
        TextFormField(
          controller: _graduationYearController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.primaryText),
          decoration: InputDecoration(
            labelText: _academicStatus == 'pursuing' ? 'Expected Graduation Year *' : 'Year of Degree Completion *',
            hintText: _academicStatus == 'pursuing' ? '2026' : '2024',
            prefixIcon: const Icon(LucideIcons.calendarCheck, size: 18),
          ),
        ),
        const SizedBox(height: AppDimensions.space16),

        // Grading System
        Text('GRADING SYSTEM', style: AppTypography.label.copyWith(color: AppColors.secondaryText)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('CGPA (10.0 Scale)'),
                selected: _gradingSystem == 'cgpa',
                selectedColor: AppColors.white,
                backgroundColor: AppColors.elevatedSurface,
                labelStyle: TextStyle(
                  color: _gradingSystem == 'cgpa' ? AppColors.black : AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                ),
                side: BorderSide(color: _gradingSystem == 'cgpa' ? AppColors.white : AppColors.border),
                showCheckmark: false,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _gradingSystem = 'cgpa';
                      _gradingScaleMax = 10.0;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Text('Percentage (%)'),
                selected: _gradingSystem == 'percentage',
                selectedColor: AppColors.white,
                backgroundColor: AppColors.elevatedSurface,
                labelStyle: TextStyle(
                  color: _gradingSystem == 'percentage' ? AppColors.black : AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                ),
                side: BorderSide(color: _gradingSystem == 'percentage' ? AppColors.white : AppColors.border),
                showCheckmark: false,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _gradingSystem = 'percentage';
                      _gradingScaleMax = 100.0;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Text('GPA (4.0 Scale)'),
                selected: _gradingSystem == 'gpa',
                selectedColor: AppColors.white,
                backgroundColor: AppColors.elevatedSurface,
                labelStyle: TextStyle(
                  color: _gradingSystem == 'gpa' ? AppColors.black : AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                ),
                side: BorderSide(color: _gradingSystem == 'gpa' ? AppColors.white : AppColors.border),
                showCheckmark: false,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _gradingSystem = 'gpa';
                      _gradingScaleMax = 4.0;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space12),

        // Cumulative Score
        TextFormField(
          controller: _cgpaController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppColors.primaryText),
          decoration: InputDecoration(
            labelText: _gradingSystem == 'cgpa'
                ? 'Cumulative CGPA (Scale ${_gradingScaleMax.toStringAsFixed(1)}) *'
                : (_gradingSystem == 'gpa'
                    ? 'Cumulative GPA (Scale ${_gradingScaleMax.toStringAsFixed(1)}) *'
                    : 'Aggregate Percentage (%) *'),
            hintText: _gradingSystem == 'cgpa' ? '7.5' : (_gradingSystem == 'gpa' ? '3.5' : '65.0'),
            prefixIcon: const Icon(LucideIcons.percent, size: 18),
            helperText: 'Never directly equated without statutory university formula.',
            helperStyle: const TextStyle(color: AppColors.mutedText, fontSize: 11),
          ),
        ),
        const SizedBox(height: AppDimensions.space16),

        // Optional: Year-wise performance
        Container(
          decoration: BoxDecoration(
            color: AppColors.elevatedSurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              CheckboxListTile(
                value: _showYearWisePerformance,
                onChanged: (val) => setState(() => _showYearWisePerformance = val ?? false),
                title: const Text(
                  'Academic performance by year (Optional)',
                  style: TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Enter year-wise CGPA or % to satisfy stage-specific requirements.',
                  style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
                ),
                activeColor: AppColors.white,
                checkColor: AppColors.black,
              ),
              if (_showYearWisePerformance) ...[
                const Divider(color: AppColors.divider, height: 1),
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.space12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _year1ScoreController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: AppColors.primaryText),
                          decoration: const InputDecoration(labelText: 'Year 1', hintText: '7.8'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _year2ScoreController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: AppColors.primaryText),
                          decoration: const InputDecoration(labelText: 'Year 2', hintText: '8.1'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _year3ScoreController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: AppColors.primaryText),
                          decoration: const InputDecoration(labelText: 'Year 3', hintText: '7.5'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _year4ScoreController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: AppColors.primaryText),
                          decoration: const InputDecoration(labelText: 'Year 4', hintText: '8.3'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.space16),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Active backlogs in program', style: TextStyle(color: AppColors.primaryText, fontSize: 13.5)),
          value: _hasActiveBacklogs,
          activeTrackColor: AppColors.white,
          activeThumbColor: AppColors.black,
          onChanged: (val) => setState(() => _hasActiveBacklogs = val),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 4: Category & Reservation
  // ---------------------------------------------------------------------------
  Widget _buildStep4Category() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category & Reservations', style: AppTypography.headlineLarge.copyWith(fontSize: 22)),
        const SizedBox(height: 6),
        const Text(
          'Reservation quotas, age relaxations, and application fee exemptions are calculated strictly based on these criteria.',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 13.5, height: 1.4),
        ),
        const SizedBox(height: AppDimensions.space24),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['General', 'EWS', 'OBC', 'SC', 'ST'].map((cat) {
            final isSel = _socialCategory == cat;
            return ChoiceChip(
              label: Text(cat),
              selected: isSel,
              onSelected: (selected) {
                if (selected) setState(() => _socialCategory = cat);
              },
              backgroundColor: AppColors.elevatedSurface,
              selectedColor: AppColors.white,
              labelStyle: TextStyle(
                color: isSel ? AppColors.black : AppColors.secondaryText,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
              side: BorderSide(color: isSel ? AppColors.white : AppColors.border),
              showCheckmark: false,
            );
          }).toList(),
        ),
        const SizedBox(height: AppDimensions.space20),

        if (_socialCategory == 'OBC') ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('OBC Non-Creamy Layer (NCL)', style: TextStyle(color: AppColors.primaryText, fontSize: 13.5)),
            subtitle: const Text('Annual family income under 8 LPA', style: TextStyle(color: AppColors.mutedText, fontSize: 11.5)),
            value: _isObcNcl,
            activeTrackColor: AppColors.white,
            activeThumbColor: AppColors.black,
            onChanged: (val) => setState(() => _isObcNcl = val),
          ),
          const SizedBox(height: AppDimensions.space12),
        ],

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Person with Benchmark Disability (PwBD)', style: TextStyle(color: AppColors.primaryText, fontSize: 13.5)),
          value: _isPwBD,
          activeTrackColor: AppColors.white,
          activeThumbColor: AppColors.black,
          onChanged: (val) => setState(() => _isPwBD = val),
        ),
        if (_isPwBD) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _disabilityController,
            style: const TextStyle(color: AppColors.primaryText),
            decoration: const InputDecoration(
              labelText: 'Disability Category (e.g. Locomotor, Visually Impaired)',
              prefixIcon: Icon(LucideIcons.activity, size: 18),
            ),
          ),
        ],

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Ex-Serviceman (ESM) Quota', style: TextStyle(color: AppColors.primaryText, fontSize: 13.5)),
          value: _isExServiceman,
          activeTrackColor: AppColors.white,
          activeThumbColor: AppColors.black,
          onChanged: (val) => setState(() => _isExServiceman = val),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 5: Career Preferences
  // ---------------------------------------------------------------------------
  Widget _buildStep5Preferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Career Preferences', style: AppTypography.headlineLarge.copyWith(fontSize: 22)),
        const SizedBox(height: 6),
        const Text(
          'Select target streams to tailor examination discovery to your ambitions.',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 13.5, height: 1.4),
        ),
        const SizedBox(height: AppDimensions.space20),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allCareerStreams.map((stream) {
            final isSel = _selectedCareerStreams.contains(stream);
            return FilterChip(
              label: Text(stream),
              selected: isSel,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCareerStreams.add(stream);
                  } else {
                    _selectedCareerStreams.remove(stream);
                  }
                });
              },
              backgroundColor: AppColors.elevatedSurface,
              selectedColor: AppColors.white,
              labelStyle: TextStyle(
                color: isSel ? AppColors.black : AppColors.secondaryText,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12.5,
              ),
              side: BorderSide(color: isSel ? AppColors.white : AppColors.border),
              showCheckmark: false,
            );
          }).toList(),
        ),
        const SizedBox(height: AppDimensions.space24),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Willing to relocate Pan-India', style: TextStyle(color: AppColors.primaryText, fontSize: 13.5)),
          value: _willingToRelocate,
          activeTrackColor: AppColors.white,
          activeThumbColor: AppColors.black,
          onChanged: (val) => setState(() => _willingToRelocate = val),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 6: Review and Completion
  // ---------------------------------------------------------------------------
  Widget _buildStep6Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review & Complete', style: AppTypography.headlineLarge.copyWith(fontSize: 22)),
        const SizedBox(height: 6),
        const Text(
          'Please verify your profile details before saving to Supabase.',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 13.5, height: 1.4),
        ),
        const SizedBox(height: AppDimensions.space20),

        _buildReviewSection('Basic Demographics', 0, [
          _buildReviewRow('Name', _nameController.text.trim()),
          _buildReviewRow(
            'Date of Birth',
            _selectedDob != null ? DateFormat('d MMMM yyyy').format(_selectedDob!) : 'Not set',
          ),
          _buildReviewRow('Calculated Age', '$_calculatedAge Years'),
          _buildReviewRow('Gender', _selectedGender),
          _buildReviewRow('State', _selectedState),
          _buildReviewRow('District', _districtController.text.trim().isEmpty ? 'All India' : _districtController.text.trim()),
        ]),
        const SizedBox(height: AppDimensions.space16),

        _buildReviewSection('Current Background', 1, [
          _buildReviewRow('Status', _currentStatus),
        ]),
        const SizedBox(height: AppDimensions.space16),

        _buildReviewSection('Qualifications', 2, [
          _buildReviewRow('10th / 12th', '${_class10Controller.text.trim()} / ${_class12Controller.text.trim()} ($_class12Stream)'),
          _buildReviewRow('Highest Level', _highestQualification),
          _buildReviewRow('Degree & Discipline', '${_degreeController.text.trim()} • ${_streamController.text.trim()}'),
          _buildReviewRow(
            'Graduation & Score',
            '${_graduationYearController.text.trim()} • ${_cgpaController.text.trim()} ${_gradingSystem == "cgpa" ? "CGPA (10-point scale)" : (_gradingSystem == "gpa" ? "GPA (4-point scale)" : "%")}',
          ),
          _buildReviewRow('Degree Status', _degreeStatus),
        ]),
        const SizedBox(height: AppDimensions.space16),

        _buildReviewSection('Category & Quotas', 3, [
          _buildReviewRow('Social Category', _socialCategory),
          if (_socialCategory == 'OBC')
            _buildReviewRow('OBC Non-Creamy Layer', _isObcNcl ? 'Yes (NCL)' : 'No (Creamy Layer)'),
          _buildReviewRow('PwBD Status', _isPwBD ? 'Yes (${_disabilityController.text.trim()})' : 'No'),
          _buildReviewRow('Ex-Serviceman', _isExServiceman ? 'Yes' : 'No'),
        ]),
        const SizedBox(height: AppDimensions.space16),

        _buildReviewSection('Career Ambitions', 4, [
          _buildReviewRow('Target Streams', _selectedCareerStreams.join(', ')),
          _buildReviewRow('Pan-India Relocation', _willingToRelocate ? 'Yes' : 'State Only'),
        ]),
        const SizedBox(height: AppDimensions.space24),
      ],
    );
  }

  Widget _buildReviewSection(String title, int stepIndex, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              InkWell(
                onTap: () => setState(() => _currentStep = stepIndex),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space10),
          const Divider(color: AppColors.divider),
          const SizedBox(height: AppDimensions.space8),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
