import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/candidate_profile.dart';
import 'providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _districtController;
  late TextEditingController _disabilityController;

  DateTime? _dateOfBirth;
  String? _gender;
  String? _state;
  String? _currentStatus;
  String _socialCategory = 'General';
  bool _isObcNcl = false;
  bool _isPwBD = false;
  bool _isExServiceman = false;

  bool _isInitialized = false;
  bool _isSaving = false;

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

  static const List<String> _statusOptions = [
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _districtController = TextEditingController();
    _disabilityController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _districtController.dispose();
    _disabilityController.dispose();
    super.dispose();
  }

  void _populateFromProfile(CandidateProfile profile) {
    if (_isInitialized) return;
    _nameController.text = profile.fullName;
    _districtController.text = profile.district ?? '';
    _disabilityController.text = profile.pwbdDisabilityType ?? '';
    _dateOfBirth = profile.dateOfBirth;
    _gender = profile.gender ?? 'Male';
    _state = profile.state ?? 'Delhi (NCT)';
    _currentStatus = profile.currentStatus ?? 'Completed undergraduate degree';
    _socialCategory = profile.socialCategory;
    _isObcNcl = profile.isObcNcl;
    _isPwBD = profile.isPwBD;
    _isExServiceman = profile.isExServiceman;
    _isInitialized = true;
  }

  int? get _calculatedAge {
    if (_dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - _dateOfBirth!.year;
    if (now.month < _dateOfBirth!.month ||
        (now.month == _dateOfBirth!.month && now.day < _dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickDateOfBirth() async {
    final initialDate = _dateOfBirth ?? DateTime(2002, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1960),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 14)),
      helpText: 'SELECT DATE OF BIRTH',
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
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _saveChanges(CandidateProfile currentProfile) async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your Date of Birth.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updated = currentProfile.copyWith(
        fullName: _nameController.text.trim(),
        dateOfBirth: _dateOfBirth,
        gender: _gender,
        state: _state,
        district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
        currentStatus: _currentStatus,
        socialCategory: _socialCategory,
        isObcNcl: _isObcNcl,
        isPwBD: _isPwBD,
        pwbdDisabilityType: _isPwBD && _disabilityController.text.trim().isNotEmpty
            ? _disabilityController.text.trim()
            : null,
        isExServiceman: _isExServiceman,
      );

      await ref.read(profileProvider.notifier).updateProfile(updated);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Profile updated successfully.',
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
            content: Text('Error updating profile: $e'),
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
        backgroundColor: AppColors.mainBackground,
        appBar: AppBar(
          backgroundColor: AppColors.mainBackground,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primaryText, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
          ),
          title: Text(
            'Edit Profile',
            style: AppTypography.screenTitle.copyWith(fontSize: 18),
          ),
        ),
        body: profileAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.white),
          ),
          error: (err, _) => Center(
            child: Text(
              'Failed to load profile: $err',
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
                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.primaryText),
                      decoration: const InputDecoration(
                        labelText: 'Full Legal Name *',
                        prefixIcon: Icon(LucideIcons.user, size: 18),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    // Date of Birth & Live Age Badge
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
                                      _dateOfBirth != null
                                          ? DateFormat('d MMMM yyyy').format(_dateOfBirth!)
                                          : 'Select Date of Birth',
                                      style: TextStyle(
                                        color: _dateOfBirth != null ? AppColors.primaryText : AppColors.mutedText,
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

                    // Gender & State Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _gender,
                            dropdownColor: AppColors.elevatedSurface,
                            style: const TextStyle(color: AppColors.primaryText, fontSize: 13.5),
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: Icon(LucideIcons.users, size: 18),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Male', child: Text('Male')),
                              DropdownMenuItem(value: 'Female', child: Text('Female')),
                              DropdownMenuItem(value: 'Transgender', child: Text('Transgender')),
                              DropdownMenuItem(value: 'Other', child: Text('Other')),
                            ],
                            onChanged: (val) => setState(() => _gender = val),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _state,
                            isExpanded: true,
                            dropdownColor: AppColors.elevatedSurface,
                            style: const TextStyle(color: AppColors.primaryText, fontSize: 13.5),
                            decoration: const InputDecoration(
                              labelText: 'State *',
                              prefixIcon: Icon(LucideIcons.mapPin, size: 18),
                            ),
                            items: _indianStates.map((st) => DropdownMenuItem(value: st, child: Text(st, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) => setState(() => _state = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    // District
                    TextFormField(
                      controller: _districtController,
                      style: const TextStyle(color: AppColors.primaryText),
                      decoration: const InputDecoration(
                        labelText: 'District (Optional)',
                        prefixIcon: Icon(LucideIcons.navigation, size: 18),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    // Current Background
                    DropdownButtonFormField<String>(
                      initialValue: _currentStatus,
                      isExpanded: true,
                      dropdownColor: AppColors.elevatedSurface,
                      style: const TextStyle(color: AppColors.primaryText, fontSize: 13.5),
                      decoration: const InputDecoration(
                        labelText: 'Current Academic / Career Status',
                        prefixIcon: Icon(LucideIcons.briefcase, size: 18),
                      ),
                      items: _statusOptions.map((st) => DropdownMenuItem(value: st, child: Text(st, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) => setState(() => _currentStatus = val),
                    ),
                    const SizedBox(height: AppDimensions.space24),

                    // Section Heading: Category & Quota
                    Text(
                      'Statutory Category & Reservations',
                      style: AppTypography.sectionHeader.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: AppDimensions.space12),

                    // Social Category Chips
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
                            fontSize: 12.5,
                          ),
                          side: BorderSide(color: isSel ? AppColors.white : AppColors.border),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    if (_socialCategory == 'OBC') ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('OBC Non-Creamy Layer (NCL)', style: TextStyle(color: AppColors.primaryText, fontSize: 13.5)),
                        subtitle: const Text('Eligible for central/state reservation quota', style: TextStyle(color: AppColors.mutedText, fontSize: 11.5)),
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
                          labelText: 'Disability Category / Benchmark (e.g. Locomotor, VH, HH)',
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
                          : const Text('Save Profile Changes'),
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
