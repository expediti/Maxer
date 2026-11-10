import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/candidate_profile.dart';
import 'providers/profile_provider.dart';

class QualificationsScreen extends ConsumerStatefulWidget {
  const QualificationsScreen({super.key});

  @override
  ConsumerState<QualificationsScreen> createState() => _QualificationsScreenState();
}

class _QualificationsScreenState extends ConsumerState<QualificationsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _class10Controller;
  late TextEditingController _class12Controller;
  late TextEditingController _class12StreamController;
  late TextEditingController _degreeController;
  late TextEditingController _streamController;
  late TextEditingController _institutionController;
  late TextEditingController _universityController;
  late TextEditingController _collegeController;
  late TextEditingController _gradYearController;
  late TextEditingController _scoreController;
  late TextEditingController _year1ScoreController;
  late TextEditingController _year2ScoreController;
  late TextEditingController _year3ScoreController;
  late TextEditingController _year4ScoreController;
  late TextEditingController _gateScoreController;
  late TextEditingController _gateYearController;
  late TextEditingController _netSubjectController;

  String _highestQual = "B.Tech / B.E.";
  int _currentYearOfStudy = 3;
  int _currentSemester = 5;
  int _degreeDurationYears = 4;
  String _academicStatus = 'completed';
  String _gradingSystem = 'cgpa';
  double _gradingScaleMax = 10.0;
  bool _showYearWisePerformance = false;
  bool _hasActiveBacklogs = false;
  bool _hasNetJrf = false;

  bool _isInitialized = false;
  bool _isSaving = false;

  static const List<String> _qualLevels = [
    'Class 10',
    'Class 12',
    'Diploma',
    'B.Tech / B.E.',
    "Bachelor's Degree (B.Sc / B.A / B.Com / BCA)",
    "Master's Degree (M.Tech / M.Sc / MBA / MCA)",
    'Doctorate (Ph.D)',
    'Other Professional Qualification',
  ];

  static const List<String> _class12Streams = [
    'Science (PCM - Physics, Chemistry, Maths)',
    'Science (PCB - Physics, Chemistry, Biology)',
    'Science (PCMB)',
    'Commerce with Maths',
    'Commerce without Maths',
    'Arts / Humanities',
    'Vocational / Technical',
  ];

  @override
  void initState() {
    super.initState();
    _class10Controller = TextEditingController();
    _class12Controller = TextEditingController();
    _class12StreamController = TextEditingController();
    _degreeController = TextEditingController();
    _streamController = TextEditingController();
    _institutionController = TextEditingController();
    _universityController = TextEditingController();
    _collegeController = TextEditingController();
    _gradYearController = TextEditingController();
    _scoreController = TextEditingController();
    _year1ScoreController = TextEditingController();
    _year2ScoreController = TextEditingController();
    _year3ScoreController = TextEditingController();
    _year4ScoreController = TextEditingController();
    _gateScoreController = TextEditingController();
    _gateYearController = TextEditingController();
    _netSubjectController = TextEditingController();
  }

  @override
  void dispose() {
    _class10Controller.dispose();
    _class12Controller.dispose();
    _class12StreamController.dispose();
    _degreeController.dispose();
    _streamController.dispose();
    _institutionController.dispose();
    _universityController.dispose();
    _collegeController.dispose();
    _gradYearController.dispose();
    _scoreController.dispose();
    _year1ScoreController.dispose();
    _year2ScoreController.dispose();
    _year3ScoreController.dispose();
    _year4ScoreController.dispose();
    _gateScoreController.dispose();
    _gateYearController.dispose();
    _netSubjectController.dispose();
    super.dispose();
  }

  void _populateFromProfile(CandidateProfile profile) {
    if (_isInitialized) return;
    _class10Controller.text = profile.class10Year != null ? '${profile.class10Year}' : '';
    _class12Controller.text = profile.class12Year != null ? '${profile.class12Year}' : '';
    _class12StreamController.text = profile.class12Stream ?? 'Science (PCM - Physics, Chemistry, Maths)';
    _highestQual = _qualLevels.contains(profile.highestQualification)
        ? profile.highestQualification!
        : 'B.Tech / B.E.';
    _degreeController.text = profile.degreeName ?? '';
    _streamController.text = profile.stream ?? '';
    _institutionController.text = profile.institution ?? '';
    _universityController.text = profile.university ?? profile.institution ?? '';
    _collegeController.text = profile.collegeName ?? '';
    _gradYearController.text = profile.graduationYear != null ? '${profile.graduationYear}' : '';
    if (profile.cgpa != null) {
      _scoreController.text = '${profile.cgpa}';
    } else if (profile.percentage != null) {
      _scoreController.text = '${profile.percentage}';
    } else if (profile.cgpaOrPercentage != null) {
      _scoreController.text = '${profile.cgpaOrPercentage}';
    }
    _currentYearOfStudy = profile.currentYearOfStudy ?? 3;
    _currentSemester = profile.currentSemester ?? 5;
    _degreeDurationYears = profile.degreeDurationYears;
    _academicStatus = profile.academicStatus;
    _gradingSystem = profile.gradingSystem;
    _gradingScaleMax = profile.gradingScaleMax;
    _hasActiveBacklogs = profile.hasActiveBacklogs;
    _gateScoreController.text = profile.gateScore != null ? '${profile.gateScore}' : '';
    _gateYearController.text = profile.gateYear != null ? '${profile.gateYear}' : '';
    _hasNetJrf = profile.hasNetJrf;
    _netSubjectController.text = profile.netSubject ?? '';

    if (profile.yearWisePerformance.isNotEmpty) {
      _year1ScoreController.text = profile.yearWisePerformance['year_1']?.toString() ?? '';
      _year2ScoreController.text = profile.yearWisePerformance['year_2']?.toString() ?? '';
      _year3ScoreController.text = profile.yearWisePerformance['year_3']?.toString() ?? '';
      _year4ScoreController.text = profile.yearWisePerformance['year_4']?.toString() ?? '';
      _showYearWisePerformance = true;
    }

    _isInitialized = true;
  }

  Future<void> _saveChanges(CandidateProfile currentProfile) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final c10 = int.tryParse(_class10Controller.text.trim());
      final c12 = int.tryParse(_class12Controller.text.trim());
      final grad = int.tryParse(_gradYearController.text.trim());
      final score = double.tryParse(_scoreController.text.trim());
      final gateScore = int.tryParse(_gateScoreController.text.trim());
      final gateYear = int.tryParse(_gateYearController.text.trim());

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

      final updated = currentProfile.copyWith(
        class10Year: c10,
        class12Year: c12,
        class12Stream: _class12StreamController.text.trim().isEmpty ? null : _class12StreamController.text.trim(),
        highestQualification: _highestQual,
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
        gateScore: gateScore,
        gateYear: gateYear,
        hasNetJrf: _hasNetJrf,
        netSubject: _hasNetJrf && _netSubjectController.text.trim().isNotEmpty
            ? _netSubjectController.text.trim()
            : null,
      );

      await ref.read(profileProvider.notifier).updateProfile(updated);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Qualifications updated successfully.',
              style: TextStyle(color: AppColors.primaryText),
            ),
            backgroundColor: AppColors.cardBackground,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.border),
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating qualifications: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/profile');
        }
      },
      child: Scaffold(
        backgroundColor: context.themeBackground,
        appBar: AppBar(
          backgroundColor: context.themeBackground,
          elevation: 0,
          leading: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: context.themeTextMain, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
          ),
          title: Text(
            'Academic Qualifications',
            style: AppTypography.screenTitle.copyWith(fontSize: 18, color: context.themeTextMain),
          ),
        ),
        body: profileAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: context.themeTextMain),
          ),
          error: (err, _) => Center(
            child: Text(
              'Failed to load qualifications: $err',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          data: (profile) {
            _populateFromProfile(profile);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space16,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Secondary & Higher Secondary (10th / 12th)
                    Text(
                      'Secondary & Higher Secondary Education',
                      style: AppTypography.sectionHeader.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: AppDimensions.space12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _class10Controller,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.primaryText),
                            decoration: const InputDecoration(
                              labelText: '10th Passing Year',
                              hintText: 'e.g. 2018',
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
                              labelText: '12th Passing Year',
                              hintText: 'e.g. 2020',
                              prefixIcon: Icon(LucideIcons.calendar, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    DropdownButtonFormField<String>(
                      initialValue: _class12Streams.contains(_class12StreamController.text)
                          ? _class12StreamController.text
                          : _class12Streams.first,
                      isExpanded: true,
                      dropdownColor: AppColors.elevatedSurface,
                      style: const TextStyle(color: AppColors.primaryText, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Class 12 Stream',
                        prefixIcon: Icon(LucideIcons.bookOpen, size: 18),
                      ),
                      items: _class12Streams.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _class12StreamController.text = val);
                      },
                    ),
                    const SizedBox(height: AppDimensions.space24),

                    // Section 2: Higher Degree / Undergraduate Qualification
                    Text(
                      'Primary Degree / Specialization',
                      style: AppTypography.sectionHeader.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: AppDimensions.space12),

                    DropdownButtonFormField<String>(
                      initialValue: _highestQual,
                      isExpanded: true,
                      dropdownColor: AppColors.elevatedSurface,
                      style: const TextStyle(color: AppColors.primaryText, fontSize: 13.5),
                      decoration: const InputDecoration(
                        labelText: 'Qualification Level *',
                        prefixIcon: Icon(LucideIcons.graduationCap, size: 18),
                      ),
                      items: _qualLevels.map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _highestQual = val);
                      },
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    TextFormField(
                      controller: _degreeController,
                      style: const TextStyle(color: AppColors.primaryText),
                      decoration: const InputDecoration(
                        labelText: 'Degree / Program Title *',
                        hintText: 'e.g. Bachelor of Technology',
                        prefixIcon: Icon(LucideIcons.award, size: 18),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Degree title is required' : null,
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    TextFormField(
                      controller: _streamController,
                      style: const TextStyle(color: AppColors.primaryText),
                      decoration: const InputDecoration(
                        labelText: 'Discipline / Branch / Major *',
                        hintText: 'e.g. Computer Science and Engineering',
                        prefixIcon: Icon(LucideIcons.layers, size: 18),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Branch / stream is required' : null,
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    TextFormField(
                      controller: _universityController,
                      style: const TextStyle(color: AppColors.primaryText),
                      decoration: const InputDecoration(
                        labelText: 'University *',
                        hintText: 'e.g. Delhi University / VTU / Anna University',
                        prefixIcon: Icon(LucideIcons.landmark, size: 18),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'University is required' : null,
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    TextFormField(
                      controller: _collegeController,
                      style: const TextStyle(color: AppColors.primaryText),
                      decoration: const InputDecoration(
                        labelText: 'College / Institute Name',
                        hintText: 'e.g. DTU / Hansraj / RVCE',
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
                    Text('ACADEMIC STATUS', style: AppTypography.label.copyWith(color: AppColors.secondaryText)),
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

                    // Graduation Year
                    TextFormField(
                      controller: _gradYearController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.primaryText),
                      decoration: InputDecoration(
                        labelText: _academicStatus == 'pursuing' ? 'Expected Graduation Year *' : 'Year of Degree Completion *',
                        hintText: _academicStatus == 'pursuing' ? '2026' : '2024',
                        prefixIcon: const Icon(LucideIcons.calendarCheck, size: 18),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Year is required' : null,
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

                    TextFormField(
                      controller: _scoreController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.primaryText),
                      decoration: InputDecoration(
                        labelText: _gradingSystem == 'cgpa'
                            ? 'Cumulative CGPA (Scale ${_gradingScaleMax.toStringAsFixed(1)}) *'
                            : (_gradingSystem == 'gpa'
                                ? 'Cumulative GPA (Scale ${_gradingScaleMax.toStringAsFixed(1)}) *'
                                : 'Aggregate Percentage (%) *'),
                        hintText: _gradingSystem == 'cgpa' ? 'e.g. 7.5' : (_gradingSystem == 'gpa' ? 'e.g. 3.5' : 'e.g. 68.5'),
                        prefixIcon: const Icon(LucideIcons.percent, size: 18),
                        helperText: 'Verified university conversion rules apply. Never equated directly.',
                        helperStyle: const TextStyle(color: AppColors.mutedText, fontSize: 11),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Score is required' : null,
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
                              'Enter year-wise scores for multi-year eligibility checks.',
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
                      title: const Text('Active Backlogs in Program', style: TextStyle(color: AppColors.primaryText, fontSize: 13.5)),
                      subtitle: const Text('Some exams restrict applicants with uncleared backlogs', style: TextStyle(color: AppColors.mutedText, fontSize: 11.5)),
                      value: _hasActiveBacklogs,
                      activeTrackColor: AppColors.white,
                      activeThumbColor: AppColors.black,
                      onChanged: (val) => setState(() => _hasActiveBacklogs = val),
                    ),
                    const SizedBox(height: AppDimensions.space24),

                    // Section 3: National Competitive Scores (GATE / NET / JRF)
                    Text(
                      'National Standardized Scores (Optional)',
                      style: AppTypography.sectionHeader.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: AppDimensions.space12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _gateScoreController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.primaryText),
                            decoration: const InputDecoration(
                              labelText: 'GATE Score',
                              hintText: 'e.g. 742',
                              prefixIcon: Icon(LucideIcons.hash, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space12),
                        Expanded(
                          child: TextFormField(
                            controller: _gateYearController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.primaryText),
                            decoration: const InputDecoration(
                              labelText: 'GATE Year',
                              hintText: 'e.g. 2025',
                              prefixIcon: Icon(LucideIcons.calendar, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('UGC-NET / CSIR-JRF Qualified', style: TextStyle(color: AppColors.primaryText, fontSize: 13.5)),
                      value: _hasNetJrf,
                      activeTrackColor: AppColors.white,
                      activeThumbColor: AppColors.black,
                      onChanged: (val) => setState(() => _hasNetJrf = val),
                    ),
                    if (_hasNetJrf) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _netSubjectController,
                        style: const TextStyle(color: AppColors.primaryText),
                        decoration: const InputDecoration(
                          labelText: 'NET Subject Specialization',
                          hintText: 'e.g. Computer Science and Applications',
                          prefixIcon: Icon(LucideIcons.fileCheck, size: 18),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppDimensions.space32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : () => _saveChanges(profile),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2),
                            )
                          : const Text('Save Academic Qualifications'),
                    ),
                    const SizedBox(height: AppDimensions.space32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
