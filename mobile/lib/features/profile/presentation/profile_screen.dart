import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:rexam/core/constants/app_colors.dart';
import 'package:rexam/core/constants/app_dimensions.dart';
import 'package:rexam/core/theme/app_typography.dart';
import 'package:rexam/core/utils/currency_formatter.dart';
import 'package:rexam/features/auth/presentation/providers/auth_provider.dart';
import 'package:rexam/features/profile/presentation/providers/profile_provider.dart';
import 'package:rexam/features/profile/presentation/widgets/avatar_picker.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          side: BorderSide(color: context.themeBorder),
        ),
        title: Text('Sign Out', style: TextStyle(color: context.themeTextMain, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to end your current session? You will need to sign in again to access your tracked applications.',
          style: TextStyle(color: context.themeTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: context.themeTextMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/welcome');
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        backgroundColor: context.themeBackground,
        elevation: 0,
        title: Text(
          'Candidate Profile',
          style: AppTypography.screenTitle.copyWith(
            fontSize: 18,
            color: context.themeTextMain,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.settings, color: context.themeTextMain, size: 20),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            final completion = profile.completionPercentage;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Profile Identity Card
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    decoration: BoxDecoration(
                      color: context.themeCard,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const AvatarPickerWidget(radius: 28, editable: true),
                            const SizedBox(width: AppDimensions.space16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.fullName.isNotEmpty ? profile.fullName : 'Candidate',
                                    style: AppTypography.screenTitle.copyWith(
                                      fontSize: 18,
                                      color: context.themeTextMain,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    profile.email,
                                    style: AppTypography.caption.copyWith(color: context.themeTextMuted),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: context.themeSurfaceElevated,
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                      border: Border.all(color: context.themeBorder),
                                    ),
                                    child: Text(
                                      '${profile.socialCategory} • ${profile.highestQualification ?? "Graduate"}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: context.themeTextMain,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.space16),

                        // Profile Completion Progress Bar
                        InkWell(
                          onTap: () => context.push('/profile/completion'),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          child: Container(
                            padding: const EdgeInsets.all(AppDimensions.space12),
                            decoration: BoxDecoration(
                              color: context.themeSurfaceElevated,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                              border: Border.all(color: context.themeBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Profile Completeness',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: context.themeTextMain,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '$completion%',
                                          style: TextStyle(
                                            color: context.themeTextMain,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(LucideIcons.chevronRight, size: 14, color: context.themeTextMuted),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: completion / 100.0,
                                    backgroundColor: context.themeBorder,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      completion == 100 ? AppColors.primaryGreen : AppColors.primaryGreen,
                                    ),
                                    minHeight: 5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  completion == 100
                                      ? 'All statutory eligibility attributes verified'
                                      : 'Tap to view missing details (${100 - completion}% remaining)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: completion == 100 ? AppColors.primaryGreen : context.themeTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space12),

                        // Action Buttons: Edit Profile and Qualifications
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => context.push('/profile/edit'),
                                icon: const Icon(LucideIcons.userCheck, size: 15),
                                label: const Text('Edit Profile'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: context.themeBorder),
                                  foregroundColor: context.themeTextMain,
                                  backgroundColor: context.themeSurfaceElevated,
                                  minimumSize: const Size.fromHeight(38),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.space8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => context.push('/profile/qualifications'),
                                icon: const Icon(LucideIcons.graduationCap, size: 15),
                                label: const Text('Qualifications'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: context.themeBorder),
                                  foregroundColor: context.themeTextMain,
                                  backgroundColor: context.themeSurfaceElevated,
                                  minimumSize: const Size.fromHeight(38),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Section 1: Demographics & Personal Info
                  _buildSectionHeaderWithAction(
                    context,
                    'Personal Demographics',
                    LucideIcons.user,
                    onEdit: () => context.push('/profile/edit'),
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  _buildInfoCard(context, [
                    _buildInfoRow(context, 'Full Name', profile.fullName),
                    _buildInfoRow(
                      context,
                      'Date of Birth',
                      profile.dateOfBirth != null ? DateFormat('d MMMM yyyy').format(profile.dateOfBirth!) : 'Not set',
                    ),
                    _buildInfoRow(context, 'Calculated Age', '${profile.calculateAge() ?? "N/A"} Years'),
                    _buildInfoRow(context, 'Gender', profile.gender ?? 'Not set'),
                    _buildInfoRow(context, 'Nationality', profile.nationality),
                    _buildInfoRow(context, 'State of Domicile', profile.state ?? 'All India'),
                    _buildInfoRow(context, 'District', profile.district ?? 'Not set'),
                    _buildInfoRow(context, 'Current Background', profile.currentStatus ?? 'Undergraduate Candidate'),
                  ]),
                  const SizedBox(height: AppDimensions.space20),

                  // Section 2: Educational Qualifications
                  _buildSectionHeaderWithAction(
                    context,
                    'Educational Qualifications',
                    LucideIcons.graduationCap,
                    onEdit: () => context.push('/profile/qualifications'),
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  _buildInfoCard(context, [
                    if (profile.class10Year != null)
                      _buildInfoRow(context, 'Class 10 Passing Year', '${profile.class10Year}'),
                    if (profile.class12Year != null)
                      _buildInfoRow(context, 'Class 12 Passing Year', '${profile.class12Year} (${profile.class12Stream ?? "Science"}${profile.class12Percentage != null ? " • ${profile.class12Percentage}%" : ""})'),
                    _buildInfoRow(context, 'Highest Qualification', profile.highestQualification ?? 'Not set'),
                    _buildInfoRow(context, 'Degree / Program', profile.degreeName ?? 'Not set'),
                    _buildInfoRow(context, 'Discipline / Branch', profile.stream ?? 'Not set'),
                    _buildInfoRow(context, 'University / College', profile.institution ?? 'Not set'),
                    _buildInfoRow(context, 'Graduation Year', '${profile.graduationYear ?? "Not set"}'),
                    _buildInfoRow(context, 'Academic Score', profile.formattedScoreDisplay),
                    _buildInfoRow(context, 'Status', profile.degreeStatus ?? 'Completed'),
                    _buildInfoRow(context, 'Active Backlogs', profile.hasActiveBacklogs ? 'Yes' : 'None'),
                    if (profile.gateScore != null)
                      _buildInfoRow(context, 'GATE Score', '${profile.gateScore} (Year: ${profile.gateYear ?? "N/A"})'),
                    _buildInfoRow(context, 'UGC-NET / JRF Qualified', profile.hasNetJrf ? 'Yes (${profile.netSubject ?? "Specialization"})' : 'No'),
                  ]),
                  const SizedBox(height: AppDimensions.space20),

                  // Section 3: Statutory Relaxations
                  _buildSectionHeaderWithAction(
                    context,
                    'Statutory Relaxations & Quota',
                    LucideIcons.shieldCheck,
                    onEdit: () => context.push('/profile/edit'),
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  _buildInfoCard(context, [
                    _buildInfoRow(context, 'Social Category', profile.socialCategory),
                    if (profile.socialCategory == 'OBC')
                      _buildInfoRow(context, 'OBC Non-Creamy Layer', profile.isObcNcl ? 'Yes (NCL)' : 'No (Creamy Layer)'),
                    _buildInfoRow(context, 'PwBD Status', profile.isPwBD ? 'Yes (${profile.pwbdDisabilityType ?? "Benchmark"})' : 'No'),
                    _buildInfoRow(context, 'Ex-Serviceman (ESM)', profile.isExServiceman ? 'Yes' : 'No'),
                  ]),
                  const SizedBox(height: AppDimensions.space20),

                  // Section 4: Opportunity Preferences
                  _buildSectionHeaderWithAction(
                    context,
                    'Opportunity Preferences',
                    LucideIcons.compass,
                    onEdit: () => context.push('/profile/wizard'),
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  _buildInfoCard(context, [
                    _buildInfoRow(context, 'Preferred Categories', profile.preferredCategories.map((c) => c.label).join(', ')),
                    _buildInfoRow(context, 'Career Disciplines', profile.careerInterests.isNotEmpty ? profile.careerInterests.join(', ') : 'All'),
                    _buildInfoRow(context, 'Pan-India Relocation', profile.willingToRelocate ? 'Yes (Pan-India)' : 'State Only'),
                    _buildInfoRow(context, 'Max Application Fee Budget', CurrencyFormatter.format(profile.maxApplicationFeeBudget)),
                  ]),
                  const SizedBox(height: AppDimensions.space24),

                  // Sign Out Button
                  OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context, ref),
                    icon: const Icon(LucideIcons.logOut, size: 16, color: AppColors.error),
                    label: const Text('Sign Out of Rexam', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      backgroundColor: context.themeCard,
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space32),
                ],
              ),
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(color: context.themeTextMain),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.space24),
              child: Text(
                'Error loading candidate profile: $err',
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeaderWithAction(BuildContext context, String title, IconData icon, {required VoidCallback onEdit}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: context.themeTextMuted),
            const SizedBox(width: AppDimensions.space8),
            Text(
              title,
              style: AppTypography.sectionHeader.copyWith(
                color: context.themeTextMain,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              'Edit',
              style: TextStyle(
                color: context.themeTextMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(children: rows),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(color: context.themeTextMuted),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: context.themeTextMain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
