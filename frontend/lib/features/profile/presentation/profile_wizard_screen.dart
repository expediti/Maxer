import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../opportunities/domain/opportunity.dart';
import '../domain/candidate_profile.dart';
import 'providers/profile_provider.dart';

class ProfileWizardScreen extends ConsumerStatefulWidget {
  const ProfileWizardScreen({super.key});

  @override
  ConsumerState<ProfileWizardScreen> createState() => _ProfileWizardScreenState();
}

class _ProfileWizardScreenState extends ConsumerState<ProfileWizardScreen> {
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Controllers & Form State
  // Step 1: Personal
  late TextEditingController _nameController;
  DateTime? _selectedDob;
  String _selectedGender = 'Male';
  String _nationality = 'Indian';
  String _selectedState = 'Delhi';
  String _district = 'New Delhi';

  // Step 2: Category
  String _socialCategory = 'General';
  bool _isPwBD = false;
  String? _pwbdType;
  bool _isExServiceman = false;

  // Step 3: Education
  String _highestQualification = 'B.Tech / B.E.';
  late TextEditingController _degreeController;
  late TextEditingController _streamController;
  late TextEditingController _universityController;
  int _graduationYear = 2024;
  late TextEditingController _cgpaController;
  bool _hasActiveBacklogs = false;

  // Step 4: Additional Qualifications
  late TextEditingController _gateScoreController;
  bool _hasNetJrf = false;
  late TextEditingController _workExpController;

  // Step 5: Preferences
  List<OpportunityCategory> _selectedCategories = [
    OpportunityCategory.govtRecruitment,
    OpportunityCategory.psu,
  ];
  late TextEditingController _maxFeeBudgetController;
  bool _willingToRelocate = true;
  List<String> _careerInterests = ['Engineering', 'Computer Science', 'Administration'];

  final List<String> _availableStates = [
    'Andhra Pradesh', 'Assam', 'Bihar', 'Delhi', 'Gujarat', 'Haryana',
    'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Odisha',
    'Punjab', 'Rajasthan', 'Tamil Nadu', 'Telangana', 'Uttar Pradesh', 'West Bengal'
  ];

  final List<String> _availableInterests = [
    'Engineering', 'Computer Science', 'Administration', 'Banking',
    'Defence', 'Research', 'Science', 'Management', 'Teaching'
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
    _district = profile.district ?? 'New Delhi';
    _socialCategory = profile.socialCategory;
    _isPwBD = profile.isPwBD;
    _isExServiceman = profile.isExServiceman;

    _highestQualification = profile.highestQualification ?? 'B.Tech / B.E.';
    _degreeController = TextEditingController(text: profile.degreeName ?? 'Bachelor of Technology');
    _streamController = TextEditingController(text: profile.stream ?? 'Computer Science & Engineering');
    _universityController = TextEditingController(text: profile.universityOrCollege ?? 'Delhi Technological University');
    _cgpaController = TextEditingController(text: profile.cgpaOrPercentage?.toString() ?? '78.5');

    _gateScoreController = TextEditingController(text: profile.gateScore?.toString() ?? '680');
    _hasNetJrf = profile.hasNetJrf;
    _workExpController = TextEditingController(text: profile.workExperienceYears.toString());

    _maxFeeBudgetController = TextEditingController(text: profile.maxApplicationFeeBudget?.toString() ?? '1000');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _degreeController.dispose();
    _streamController.dispose();
    _universityController.dispose();
    _cgpaController.dispose();
    _gateScoreController.dispose();
    _workExpController.dispose();
    _maxFeeBudgetController.dispose();
    super.dispose();
  }

  void _saveAndNext() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _finishWizard();
    }
  }

  void _finishWizard() {
    final currentProfile = ref.read(profileProvider).valueOrNull ??
        const CandidateProfile(id: 'temp', email: 'candidate@rexam.in');

    final updated = currentProfile.copyWith(
      fullName: _nameController.text.trim(),
      dateOfBirth: _selectedDob,
      gender: _selectedGender,
      nationality: _nationality,
      state: _selectedState,
      district: _district,
      socialCategory: _socialCategory,
      isPwBD: _isPwBD,
      pwbdDisabilityType: _pwbdType,
      isExServiceman: _isExServiceman,
      highestQualification: _highestQualification,
      degreeName: _degreeController.text.trim(),
      stream: _streamController.text.trim(),
      universityOrCollege: _universityController.text.trim(),
      graduationYear: _graduationYear,
      cgpaOrPercentage: double.tryParse(_cgpaController.text.trim()),
      hasActiveBacklogs: _hasActiveBacklogs,
      gateScore: int.tryParse(_gateScoreController.text.trim()),
      hasNetJrf: _hasNetJrf,
      workExperienceYears: double.tryParse(_workExpController.text.trim()) ?? 0.0,
      preferredCategories: _selectedCategories,
      maxApplicationFeeBudget: num.tryParse(_maxFeeBudgetController.text.trim()),
      willingToRelocate: _willingToRelocate,
      careerInterests: _careerInterests,
    );

    ref.read(profileProvider.notifier).updateProfile(updated);
    context.go('/discover');
  }

  @override
  Widget build(BuildContext context) {
    final progress = ((_currentStep + 1) / _totalSteps * 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Profile Setup (${_currentStep + 1}/$_totalSteps)'),
        actions: [
          TextButton(
            onPressed: _finishWizard,
            child: const Text('Skip for Now'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: AppColors.surface,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              minHeight: 3,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: AppDimensions.space8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getStepTitle(_currentStep),
                    style: AppTypography.label.copyWith(color: AppColors.primaryGreen),
                  ),
                  Text(
                    '$progress% Complete',
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.space20),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Bottom Buttons
            Container(
              padding: const EdgeInsets.all(AppDimensions.space16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saveAndNext,
                      child: Text(_currentStep == _totalSteps - 1 ? 'Complete Setup' : 'Save & Continue'),
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

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Personal Information';
      case 1:
        return 'Category & Statutory Relaxation';
      case 2:
        return 'Educational Background';
      case 3:
        return 'Competitive Scores & Certifications';
      case 4:
        return 'Career & Location Preferences';
      default:
        return '';
    }
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
        return _buildStep4Qualifications();
      case 4:
        return _buildStep5Preferences();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1Personal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Candidate Identity', style: AppTypography.screenTitle),
        const SizedBox(height: AppDimensions.space4),
        Text('Used exclusively for accurate age cutoff and domicile verification.', style: AppTypography.bodyMuted),
        const SizedBox(height: AppDimensions.space20),

        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Full Name (as per 10th / Matriculation Certificate)'),
        ),
        const SizedBox(height: AppDimensions.space16),

        // Date of Birth
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDob ?? DateTime(2000, 1, 1),
              firstDate: DateTime(1975),
              lastDate: DateTime.now(),
              builder: (context, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.primaryGreen,
                    surface: AppColors.surface,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _selectedDob = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: AppDimensions.space12),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: AppDimensions.roundedDefault,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date of Birth', style: AppTypography.caption.copyWith(color: AppColors.textSubtle)),
                    const SizedBox(height: 2),
                    Text(
                      _selectedDob != null ? DateFormat('dd MMMM yyyy').format(_selectedDob!) : 'Select Date of Birth',
                      style: AppTypography.body,
                    ),
                  ],
                ),
                const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.space16),

        // Gender
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: const InputDecoration(labelText: 'Gender'),
          items: const [
            DropdownMenuItem(value: 'Male', child: Text('Male')),
            DropdownMenuItem(value: 'Female', child: Text('Female')),
            DropdownMenuItem(value: 'Transgender / Other', child: Text('Transgender / Other')),
          ],
          onChanged: (val) => setState(() => _selectedGender = val!),
        ),
        const SizedBox(height: AppDimensions.space16),

        // State / Domicile
        DropdownButtonFormField<String>(
          value: _selectedState,
          decoration: const InputDecoration(labelText: 'Home State / Domicile'),
          items: _availableStates.map((st) => DropdownMenuItem(value: st, child: Text(st))).toList(),
          onChanged: (val) => setState(() => _selectedState = val!),
        ),
      ],
    );
  }

  Widget _buildStep2Category() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category & Reservation Conditions', style: AppTypography.screenTitle),
        const SizedBox(height: AppDimensions.space4),
        Text('Statutory relaxations are verified against central or state notification norms.', style: AppTypography.bodyMuted),
        const SizedBox(height: AppDimensions.space20),

        // Category Selection
        DropdownButtonFormField<String>(
          value: _socialCategory,
          decoration: const InputDecoration(labelText: 'Reservation Category'),
          items: const [
            DropdownMenuItem(value: 'General', child: Text('General (Unreserved)')),
            DropdownMenuItem(value: 'OBC-NCL', child: Text('OBC-NCL (Other Backward Class Non-Creamy Layer)')),
            DropdownMenuItem(value: 'SC', child: Text('SC (Scheduled Caste)')),
            DropdownMenuItem(value: 'ST', child: Text('ST (Scheduled Tribe)')),
            DropdownMenuItem(value: 'EWS', child: Text('EWS (Economically Weaker Section)')),
          ],
          onChanged: (val) => setState(() => _socialCategory = val!),
        ),
        const SizedBox(height: AppDimensions.space16),

        // PwBD
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Person with Benchmark Disability (PwBD)', style: AppTypography.body),
          subtitle: Text('Eligible for age relaxation (+10 yrs) and fee exemptions in public exams.', style: AppTypography.caption),
          value: _isPwBD,
          activeThumbColor: AppColors.primaryGreen,
          onChanged: (val) => setState(() => _isPwBD = val),
        ),
        const Divider(color: AppColors.border),

        // Ex-Serviceman
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Ex-Serviceman (ESM)', style: AppTypography.body),
          subtitle: Text('Applicable for defence & security personnel quota and relaxations.', style: AppTypography.caption),
          value: _isExServiceman,
          activeThumbColor: AppColors.primaryGreen,
          onChanged: (val) => setState(() => _isExServiceman = val),
        ),
      ],
    );
  }

  Widget _buildStep3Education() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Educational Qualifications', style: AppTypography.screenTitle),
        const SizedBox(height: AppDimensions.space4),
        Text('Accurate degree details prevent disqualification at document verification.', style: AppTypography.bodyMuted),
        const SizedBox(height: AppDimensions.space20),

        DropdownButtonFormField<String>(
          value: _highestQualification,
          decoration: const InputDecoration(labelText: 'Highest Qualification Level'),
          items: const [
            DropdownMenuItem(value: '10th / Matriculation', child: Text('10th / Matriculation')),
            DropdownMenuItem(value: '12th / Intermediate', child: Text('12th / Intermediate')),
            DropdownMenuItem(value: 'Diploma', child: Text('Diploma (Polytechnic)')),
            DropdownMenuItem(value: 'B.Tech / B.E.', child: Text('B.Tech / B.E. (Engineering)')),
            DropdownMenuItem(value: 'B.Sc / B.Com / B.A.', child: Text('Bachelor’s Degree (Arts/Science/Commerce)')),
            DropdownMenuItem(value: 'M.Tech / M.E.', child: Text('Master’s in Engineering')),
            DropdownMenuItem(value: 'M.Sc / M.Com / M.A.', child: Text('Master’s Degree')),
            DropdownMenuItem(value: 'Ph.D', child: Text('Doctorate (Ph.D)')),
          ],
          onChanged: (val) => setState(() => _highestQualification = val!),
        ),
        const SizedBox(height: AppDimensions.space16),

        TextField(
          controller: _degreeController,
          decoration: const InputDecoration(labelText: 'Degree Name (e.g. B.Tech Computer Science)'),
        ),
        const SizedBox(height: AppDimensions.space16),

        TextField(
          controller: _streamController,
          decoration: const InputDecoration(labelText: 'Specialisation / Branch (e.g. Computer Science & Engg)'),
        ),
        const SizedBox(height: AppDimensions.space16),

        TextField(
          controller: _universityController,
          decoration: const InputDecoration(labelText: 'College / University Name'),
        ),
        const SizedBox(height: AppDimensions.space16),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cgpaController,
                decoration: const InputDecoration(labelText: 'CGPA or %'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _graduationYear,
                decoration: const InputDecoration(labelText: 'Graduation Year'),
                items: [2021, 2022, 2023, 2024, 2025, 2026, 2027]
                    .map((yr) => DropdownMenuItem(value: yr, child: Text('$yr')))
                    .toList(),
                onChanged: (val) => setState(() => _graduationYear = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space16),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Active Backlogs', style: AppTypography.body),
          subtitle: Text('Certain PSUs and corporate drives require zero backlogs at joining.', style: AppTypography.caption),
          value: _hasActiveBacklogs,
          activeThumbColor: AppColors.primaryGreen,
          onChanged: (val) => setState(() => _hasActiveBacklogs = val),
        ),
      ],
    );
  }

  Widget _buildStep4Qualifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Competitive Scores & Certifications', style: AppTypography.screenTitle),
        const SizedBox(height: AppDimensions.space4),
        Text('Unlocks direct PSU entry, premier fellowships and executive appointments.', style: AppTypography.bodyMuted),
        const SizedBox(height: AppDimensions.space20),

        TextField(
          controller: _gateScoreController,
          decoration: const InputDecoration(labelText: 'GATE Score (out of 1000, optional)'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppDimensions.space16),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('UGC / CSIR NET / JRF Qualified', style: AppTypography.body),
          subtitle: Text('Required for Assistant Professor, Junior Research Fellowships and PMRF.', style: AppTypography.caption),
          value: _hasNetJrf,
          activeThumbColor: AppColors.primaryGreen,
          onChanged: (val) => setState(() => _hasNetJrf = val),
        ),
        const SizedBox(height: AppDimensions.space16),

        TextField(
          controller: _workExpController,
          decoration: const InputDecoration(labelText: 'Total Relevant Work Experience (in Years)'),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildStep5Preferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Target Opportunities & Interests', style: AppTypography.screenTitle),
        const SizedBox(height: AppDimensions.space4),
        Text('Calibrates your personal recommendation feed and instant alerts.', style: AppTypography.bodyMuted),
        const SizedBox(height: AppDimensions.space20),

        Text('OPPORTUNITY TYPES', style: AppTypography.label.copyWith(color: AppColors.textSubtle)),
        const SizedBox(height: AppDimensions.space8),
        Wrap(
          spacing: AppDimensions.space8,
          runSpacing: AppDimensions.space8,
          children: OpportunityCategory.values.map((cat) {
            final isSelected = _selectedCategories.contains(cat);
            return FilterChip(
              label: Text(cat.label),
              selected: isSelected,
              selectedColor: AppColors.secondaryGreen,
              backgroundColor: AppColors.secondaryBackground,
              labelStyle: AppTypography.caption.copyWith(
                color: isSelected ? AppColors.textMain : AppColors.textMuted,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppDimensions.roundedSmall,
                side: BorderSide(color: isSelected ? AppColors.primaryGreen : AppColors.border),
              ),
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
        const SizedBox(height: AppDimensions.space20),

        Text('CAREER DOMAINS', style: AppTypography.label.copyWith(color: AppColors.textSubtle)),
        const SizedBox(height: AppDimensions.space8),
        Wrap(
          spacing: AppDimensions.space8,
          runSpacing: AppDimensions.space8,
          children: _availableInterests.map((interest) {
            final isSelected = _careerInterests.contains(interest);
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              selectedColor: AppColors.secondaryGreen,
              backgroundColor: AppColors.secondaryBackground,
              labelStyle: AppTypography.caption.copyWith(
                color: isSelected ? AppColors.textMain : AppColors.textMuted,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppDimensions.roundedSmall,
                side: BorderSide(color: isSelected ? AppColors.primaryGreen : AppColors.border),
              ),
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
        const SizedBox(height: AppDimensions.space20),

        TextField(
          controller: _maxFeeBudgetController,
          decoration: const InputDecoration(labelText: 'Maximum Application Fee Budget (₹ INR, optional)'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppDimensions.space16),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Willing to Relocate Anywhere in India', style: AppTypography.body),
          subtitle: Text('Expands matching to central cadres and nationwide PSU postings.', style: AppTypography.caption),
          value: _willingToRelocate,
          activeThumbColor: AppColors.primaryGreen,
          onChanged: (val) => setState(() => _willingToRelocate = val),
        ),
      ],
    );
  }
}
