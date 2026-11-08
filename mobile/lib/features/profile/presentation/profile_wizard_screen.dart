import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/candidate_profile.dart';
import '../../../models/examination.dart';
import 'providers/profile_provider.dart';

class ProfileWizardScreen extends ConsumerStatefulWidget {
  const ProfileWizardScreen({super.key});

  @override
  ConsumerState<ProfileWizardScreen> createState() => _ProfileWizardScreenState();
}

class _ProfileWizardScreenState extends ConsumerState<ProfileWizardScreen> {
  int _currentStep = 0;
  final int _totalSteps = 5;
  bool _isSaving = false;

  // Controllers & Form State
  // Step 1: Personal Information
  late TextEditingController _nameController;
  DateTime? _selectedDob;
  String _selectedGender = 'Male';
  final String _nationality = 'Indian';
  String _selectedState = 'Delhi';
  late TextEditingController _districtController;

  // Step 2: Reservation and Special Categories
  String _socialCategory = 'General';
  bool _isPwBD = false;
  String? _pwbdType;
  bool _isExServiceman = false;

  // Step 3: Education
  String _highestQualification = 'B.Tech / B.E.';
  late TextEditingController _degreeController;
  late TextEditingController _streamController;
  late TextEditingController _institutionController;
  int _graduationYear = 2024;
  late TextEditingController _cgpaController;
  bool _hasActiveBacklogs = false;
  late TextEditingController _gateScoreController;
  bool _hasNetJrf = false;

  // Step 4: Career Preferences
  final List<ExaminationCategory> _selectedCategories = [
    ExaminationCategory.govtRecruitment,
    ExaminationCategory.psu,
  ];
  final List<String> _careerInterests = ['Engineering', 'Computer Science', 'Administration'];
  bool _willingToRelocate = true;
  late TextEditingController _maxFeeController;

  final List<String> _states = [
    'All India', 'Andhra Pradesh', 'Assam', 'Bihar', 'Delhi', 'Gujarat', 'Haryana',
    'Himachal Pradesh', 'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra',
    'Odisha', 'Punjab', 'Rajasthan', 'Tamil Nadu', 'Telangana', 'Uttar Pradesh', 'West Bengal'
  ];

  final List<String> _qualifications = [
    '10th Standard',
    '12th Standard',
    'Diploma',
    'B.Tech / B.E.',
    'Bachelor\'s Degree (Non-Engg)',
    'Master\'s Degree',
    'Ph.D'
  ];

  final List<String> _availableInterests = [
    'Engineering', 'Computer Science', 'Administration', 'Banking',
    'Defence', 'Research', 'Science', 'Railways', 'Teaching', 'Civil Services'
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).valueOrNull ??
        const CandidateProfile(id: 'temp', email: 'candidate@rexam.in');

    _nameController = TextEditingController(text: profile.fullName.isNotEmpty ? profile.fullName : 'Arjun Sharma');
    _selectedDob = profile.dateOfBirth ?? DateTime(2001, 5, 20);
    _selectedGender = profile.gender ?? 'Male';
    _selectedState = profile.state ?? 'Delhi';
    _districtController = TextEditingController(text: profile.district ?? 'New Delhi');

    _socialCategory = profile.socialCategory;
    _isPwBD = profile.isPwBD;
    _pwbdType = profile.pwbdDisabilityType;
    _isExServiceman = profile.isExServiceman;

    _highestQualification = profile.highestQualification ?? 'B.Tech / B.E.';
    _degreeController = TextEditingController(text: profile.degreeName ?? 'Bachelor of Technology');
    _streamController = TextEditingController(text: profile.stream ?? 'Computer Science & Engineering');
    _institutionController = TextEditingController(text: profile.institution ?? 'Delhi Technological University (DTU)');
    _graduationYear = profile.graduationYear ?? 2024;
    _cgpaController = TextEditingController(text: profile.cgpaOrPercentage?.toString() ?? '78.5');
    _hasActiveBacklogs = profile.hasActiveBacklogs;
    _gateScoreController = TextEditingController(text: profile.gateScore?.toString() ?? '680');
    _hasNetJrf = profile.hasNetJrf;

    _willingToRelocate = profile.willingToRelocate;
    _maxFeeController = TextEditingController(text: profile.maxApplicationFeeBudget?.toString() ?? '1000');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _districtController.dispose();
    _degreeController.dispose();
    _streamController.dispose();
    _institutionController.dispose();
    _cgpaController.dispose();
    _gateScoreController.dispose();
    _maxFeeController.dispose();
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

  Future<void> _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2002, 1, 1),
      firstDate: DateTime(1970, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  Future<void> _saveAndComplete() async {
    setState(() => _isSaving = true);

    final current = ref.read(profileProvider).valueOrNull ??
        const CandidateProfile(id: 'temp', email: 'candidate@rexam.in');

    final updated = current.copyWith(
      fullName: _nameController.text.trim(),
      dateOfBirth: _selectedDob,
      gender: _selectedGender,
      nationality: _nationality,
      state: _selectedState,
      district: _districtController.text.trim(),
      socialCategory: _socialCategory,
      isPwBD: _isPwBD,
      pwbdDisabilityType: _isPwBD ? _pwbdType : null,
      isExServiceman: _isExServiceman,
      highestQualification: _highestQualification,
      degreeName: _degreeController.text.trim(),
      stream: _streamController.text.trim(),
      institution: _institutionController.text.trim(),
      graduationYear: _graduationYear,
      cgpaOrPercentage: double.tryParse(_cgpaController.text.trim()),
      hasActiveBacklogs: _hasActiveBacklogs,
      gateScore: int.tryParse(_gateScoreController.text.trim()),
      hasNetJrf: _hasNetJrf,
      preferredCategories: _selectedCategories,
      careerInterests: _careerInterests,
      willingToRelocate: _willingToRelocate,
      maxApplicationFeeBudget: num.tryParse(_maxFeeController.text.trim()),
    );

    await ref.read(profileProvider.notifier).updateProfile(updated);

    if (!mounted) return;
    setState(() => _isSaving = false);
    context.go('/discover');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('Profile Setup (${_currentStep + 1} of $_totalSteps)'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentStep--),
              )
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.go('/discover'),
              ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Linear Progress Indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              minHeight: 4,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.space20),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Bottom Navigation Controls
            Container(
              padding: const EdgeInsets.all(AppDimensions.space16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSurface,
                border: Border(top: BorderSide(color: theme.colorScheme.outline)),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0 && _currentStep < 4) ...[
                    OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(100, AppDimensions.buttonHeight),
                      ),
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              if (_currentStep < _totalSteps - 1) {
                                setState(() => _currentStep++);
                              } else {
                                _saveAndComplete();
                              }
                            },
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                            )
                          : Text(_currentStep == _totalSteps - 1 ? 'Explore Opportunities' : 'Continue'),
                    ),
                  ),
                ],
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
        return _buildStep1Personal();
      case 1:
        return _buildStep2Category();
      case 2:
        return _buildStep3Education();
      case 3:
        return _buildStep4Preferences();
      case 4:
        return _buildStep5Completion();
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 1: Personal Information
  // ---------------------------------------------------------------------------
  Widget _buildStep1Personal() {
    final age = _calculatedAge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 1: Personal Information', style: AppTypography.screenTitle),
        const SizedBox(height: AppDimensions.space4),
        Text('Accurate demographics ensure exact age cutoff & eligibility checks.', style: AppTypography.bodyMuted),
        const SizedBox(height: AppDimensions.space24),

        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Legal Name',
            hintText: 'As on Matriculation Certificate',
          ),
        ),
        const SizedBox(height: AppDimensions.space16),

        // Date of Birth & Calculated Age
        InkWell(
          onTap: _selectDateOfBirth,
          borderRadius: AppDimensions.roundedDefault,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date of Birth (DOB)',
              suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDob != null ? DateFormat('dd MMMM yyyy').format(_selectedDob!) : 'Select Date of Birth',
                  style: TextStyle(fontSize: 14, color: _selectedDob != null ? null : AppColors.lightTextSubtle),
                ),
                if (age != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlueLight,
                      borderRadius: AppDimensions.roundedSmall,
                    ),
                    child: Text(
                      '$age Years Old',
                      style: const TextStyle(color: AppColors.primaryBlueDark, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.space16),

        // Gender (for exam fee exemptions and gender-specific reservations)
        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          decoration: const InputDecoration(labelText: 'Gender (For fee exemption & eligibility)'),
          items: const [
            DropdownMenuItem(value: 'Male', child: Text('Male')),
            DropdownMenuItem(value: 'Female', child: Text('Female (Eligible for statutory fee waivers)')),
            DropdownMenuItem(value: 'Transgender / Other', child: Text('Transgender / Other')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedGender = val);
          },
        ),
        const SizedBox(height: AppDimensions.space16),

        // State & District
        DropdownButtonFormField<String>(
          initialValue: _selectedState,
          decoration: const InputDecoration(labelText: 'State of Domicile'),
          items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedState = val);
          },
        ),
        const SizedBox(height: AppDimensions.space16),

        TextField(
          controller: _districtController,
          decoration: const InputDecoration(labelText: 'District of Residence'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: Reservation & Special Categories
  // ---------------------------------------------------------------------------
  Widget _buildStep2Category() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 2: Reservation & Relaxations', style: AppTypography.screenTitle),
        const SizedBox(height: AppDimensions.space4),
        Text('Statutory relaxations in upper age limits and application fee waivers are evaluated based on these.', style: AppTypography.bodyMuted),
        const SizedBox(height: AppDimensions.space24),

        DropdownButtonFormField<String>(
          initialValue: _socialCategory,
          decoration: const InputDecoration(labelText: 'Social Category'),
          items: const [
            DropdownMenuItem(value: 'General', child: Text('General / Unreserved')),
            DropdownMenuItem(value: 'OBC-NCL', child: Text('OBC-NCL (Other Backward Classes - Non-Creamy) (+3 yrs)')),
            DropdownMenuItem(value: 'SC', child: Text('SC (Scheduled Caste) (+5 yrs, fee exempt)')),
            DropdownMenuItem(value: 'ST', child: Text('ST (Scheduled Tribe) (+5 yrs, fee exempt)')),
            DropdownMenuItem(value: 'EWS', child: Text('EWS (Economically Weaker Section)')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _socialCategory = val);
          },
        ),
        const SizedBox(height: AppDimensions.space20),

        // PwBD Toggle
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Person with Benchmark Disability (PwBD)', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Eligible for up to 10 years upper age relaxation & scribe assistance.', style: TextStyle(fontSize: 12)),
          value: _isPwBD,
          activeTrackColor: AppColors.primaryBlue,
          activeThumbColor: Colors.white,
          onChanged: (val) => setState(() => _isPwBD = val),
        ),

        if (_isPwBD) ...[
          const SizedBox(height: AppDimensions.space8),
          DropdownButtonFormField<String>(
            initialValue: _pwbdType ?? 'Locomotor Disability',
            decoration: const InputDecoration(labelText: 'Disability Category / Type'),
            items: const [
              DropdownMenuItem(value: 'Locomotor Disability', child: Text('Locomotor Disability (OA/OL/OAL)')),
              DropdownMenuItem(value: 'Visual Impairment', child: Text('Visual Impairment (Blindness/Low Vision)')),
              DropdownMenuItem(value: 'Hearing Impairment', child: Text('Hearing Impairment (Deaf/Hard of Hearing)')),
              DropdownMenuItem(value: 'Multiple Disabilities', child: Text('Multiple Disabilities')),
            ],
            onChanged: (val) => setState(() => _pwbdType = val),
          ),
          const SizedBox(height: AppDimensions.space16),
        ],

        const Divider(),
        const SizedBox(height: AppDimensions.space12),

        // Ex-Serviceman Toggle
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Ex-Serviceman (ESM)', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Military service personnel eligible for defence & central recruitment relaxations.', style: TextStyle(fontSize: 12)),
          value: _isExServiceman,
          activeTrackColor: AppColors.primaryBlue,
          activeThumbColor: Colors.white,
          onChanged: (val) => setState(() => _isExServiceman = val),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: Education
  // ---------------------------------------------------------------------------
  Widget _buildStep3Education() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 3: Educational Qualifications', style: AppTypography.screenTitle),
        const SizedBox(height: AppDimensions.space4),
        Text('Recruitment drives mandate specific degrees, branches, and minimum percentages.', style: AppTypography.bodyMuted),
        const SizedBox(height: AppDimensions.space24),

        DropdownButtonFormField<String>(
          initialValue: _highestQualification,
          decoration: const InputDecoration(labelText: 'Highest Qualification Attained / Pursuing'),
          items: _qualifications.map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _highestQualification = val);
          },
        ),
        const SizedBox(height: AppDimensions.space16),

        TextField(
          controller: _degreeController,
          decoration: const InputDecoration(
            labelText: 'Degree Name',
            hintText: 'e.g. Bachelor of Technology / B.Sc / M.A.',
          ),
        ),
        const SizedBox(height: AppDimensions.space16),

        TextField(
          controller: _streamController,
          decoration: const InputDecoration(
            labelText: 'Discipline / Branch / Stream',
            hintText: 'e.g. Computer Science & Engineering / Mechanical',
          ),
        ),
        const SizedBox(height: AppDimensions.space16),

        TextField(
          controller: _institutionController,
          decoration: const InputDecoration(labelText: 'University or College Name'),
        ),
        const SizedBox(height: AppDimensions.space16),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cgpaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'CGPA or %',
                  hintText: 'e.g. 78.5 or 7.85',
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.space16),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _graduationYear,
                decoration: const InputDecoration(labelText: 'Graduation Year'),
                items: List.generate(12, (i) => 2018 + i)
                    .map((yr) => DropdownMenuItem(value: yr, child: Text('$yr')))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _graduationYear = val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space16),

        // Active Backlogs
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Do you have active backlogs / supplementary exams?', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Many central PSUs mandate zero active backlogs at time of application.', style: TextStyle(fontSize: 12)),
          value: _hasActiveBacklogs,
          activeTrackColor: AppColors.error,
          activeThumbColor: Colors.white,
          onChanged: (val) => setState(() => _hasActiveBacklogs = val),
        ),
        const SizedBox(height: AppDimensions.space12),

        // Optional GATE Score
        TextField(
          controller: _gateScoreController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Valid GATE Score (Optional)',
            hintText: 'e.g. 680 (For DRDO / IOCL / BARC entries)',
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 4: Career Preferences
  // ---------------------------------------------------------------------------
  Widget _buildStep4Preferences() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 4: Career Preferences', style: AppTypography.screenTitle),
        const SizedBox(height: AppDimensions.space4),
        Text('Choose the opportunity categories and disciplines you wish to prioritize.', style: AppTypography.bodyMuted),
        const SizedBox(height: AppDimensions.space24),

        Text('Preferred Opportunity Types', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppDimensions.space12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ExaminationCategory.values.map((cat) {
            final isSelected = _selectedCategories.contains(cat);
            return FilterChip(
              label: Text(cat.label),
              selected: isSelected,
              selectedColor: AppColors.primaryBlueLight,
              checkmarkColor: AppColors.primaryBlueDark,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(cat);
                  } else {
                    _selectedCategories.remove(cat);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppDimensions.space24),

        Text('Career & Academic Disciplines', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppDimensions.space12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableInterests.map((interest) {
            final isSelected = _careerInterests.contains(interest);
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              selectedColor: AppColors.primaryBlueLight,
              checkmarkColor: AppColors.primaryBlueDark,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _careerInterests.add(interest);
                  } else {
                    _careerInterests.remove(interest);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppDimensions.space24),

        // Relocation Toggle
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Willing to work anywhere in India', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Central government & PSU services allocate pan-India postings.', style: TextStyle(fontSize: 12)),
          value: _willingToRelocate,
          activeTrackColor: AppColors.primaryBlue,
          activeThumbColor: Colors.white,
          onChanged: (val) => setState(() => _willingToRelocate = val),
        ),
        const SizedBox(height: AppDimensions.space12),

        TextField(
          controller: _maxFeeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Maximum Application Fee Budget (₹)',
            hintText: 'e.g. 1000',
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 5: Completion
  // ---------------------------------------------------------------------------
  Widget _buildStep5Completion() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppDimensions.space24),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.check_circle_outline, size: 44, color: AppColors.success),
          ),
          const SizedBox(height: AppDimensions.space24),

          Text(
            'Your Rexam profile is ready.',
            textAlign: TextAlign.center,
            style: AppTypography.screenTitle.copyWith(fontSize: 24),
          ),
          const SizedBox(height: AppDimensions.space12),

          Text(
            'We have recorded your educational profile, reservation relaxations, and career preferences.\n\nOpportunities will now automatically compute deterministic eligibility verdicts tailored to you.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMuted.copyWith(height: 1.5),
          ),
          const SizedBox(height: AppDimensions.space24),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(AppDimensions.space16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: AppDimensions.roundedDefault,
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Candidate Name', _nameController.text.trim()),
                _buildSummaryRow('Qualification', '$_highestQualification ($_graduationYear)'),
                _buildSummaryRow('Stream / Branch', _streamController.text.trim()),
                _buildSummaryRow('Social Category', _socialCategory),
                _buildSummaryRow('Calculated Age', '${_calculatedAge ?? "N/A"} Years'),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space24),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
