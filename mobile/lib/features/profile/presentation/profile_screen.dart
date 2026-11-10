import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Sign Out', style: TextStyle(color: AppColors.primaryText)),
        content: const Text(
          'Are you sure you want to end your current session? You will need to sign in again to access your tracked applications.',
          style: TextStyle(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
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
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        backgroundColor: AppColors.mainBackground,
        elevation: 0,
        title: Text(
          'Candidate Profile',
          style: AppTypography.screenTitle.copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings, color: AppColors.primaryText, size: 20),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            final initials = profile.fullName.trim().isNotEmpty
                ? profile.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                : 'C';
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
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.elevatedSurface,
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.space16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.fullName.isNotEmpty ? profile.fullName : 'Candidate',
                                    style: AppTypography.screenTitle.copyWith(fontSize: 18),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    profile.email,
                                    style: AppTypography.caption.copyWith(color: AppColors.secondaryText),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.elevatedSurface,
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Text(
                                      '${profile.socialCategory} • ${profile.highestQualification ?? "Graduate"}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryText,
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
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.space12),
                          decoration: BoxDecoration(
                            color: AppColors.elevatedSurface,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Profile Completeness',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                  Text(
                                    '$completion%',
                                    style: const TextStyle(
                                      color: AppColors.primaryText,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: completion / 100.0,
                                  backgroundColor: AppColors.border,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
                                  minHeight: 5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space12),

                        // Dedicated Action Buttons: Edit Profile and Qualifications
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => context.push('/profile/edit'),
                                icon: const Icon(LucideIcons.userCheck, size: 15),
                                label: const Text('Edit Profile'),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.border),
                                  foregroundColor: AppColors.primaryText,
                                  backgroundColor: AppColors.elevatedSurface,
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
                                  side: const BorderSide(color: AppColors.border),
                                  foregroundColor: AppColors.primaryText,
                                  backgroundColor: AppColors.elevatedSurface,
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
                    'Personal Demographics',
                    LucideIcons.user,
                    onEdit: () => context.push('/profile/edit'),
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  _buildInfoCard([
                    _buildInfoRow('Full Name', profile.fullName),
                    _buildInfoRow(
                      'Date of Birth',
                      profile.dateOfBirth != null ? DateFormat('d MMMM yyyy').format(profile.dateOfBirth!) : 'Not set',
                    ),
                    _buildInfoRow('Calculated Age', '${profile.calculateAge() ?? "N/A"} Years'),
                    _buildInfoRow('Gender', profile.gender ?? 'Not set'),
                    _buildInfoRow('Nationality', profile.nationality),
                    _buildInfoRow('State of Domicile', profile.state ?? 'All India'),
                    _buildInfoRow('District', profile.district ?? 'Not set'),
                    _buildInfoRow('Current Background', profile.currentStatus ?? 'Undergraduate Candidate'),
                  ]),
                  const SizedBox(height: AppDimensions.space20),

                  // Section 2: Educational Qualifications
                  _buildSectionHeaderWithAction(
                    'Educational Qualifications',
                    LucideIcons.graduationCap,
                    onEdit: () => context.push('/profile/qualifications'),
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  _buildInfoCard([
                    if (profile.class10Year != null)
                      _buildInfoRow('Class 10 Passing Year', '${profile.class10Year}'),
                    if (profile.class12Year != null)
                      _buildInfoRow('Class 12 Passing Year', '${profile.class12Year} (${profile.class12Stream ?? "Science"}${profile.class12Percentage != null ? " • ${profile.class12Percentage}%" : ""})'),
                    _buildInfoRow('Highest Qualification', profile.highestQualification ?? 'Not set'),
                    _buildInfoRow('Degree / Program', profile.degreeName ?? 'Not set'),
                    _buildInfoRow('Discipline / Branch', profile.stream ?? 'Not set'),
                    _buildInfoRow('University / College', profile.institution ?? 'Not set'),
                    _buildInfoRow('Graduation Year', '${profile.graduationYear ?? "Not set"}'),
                    _buildInfoRow('Academic Score', profile.formattedScoreDisplay),
                    _buildInfoRow('Status', profile.degreeStatus ?? 'Completed'),
                    _buildInfoRow('Active Backlogs', profile.hasActiveBacklogs ? 'Yes' : 'None'),
                    if (profile.gateScore != null)
                      _buildInfoRow('GATE Score', '${profile.gateScore} (Year: ${profile.gateYear ?? "N/A"})'),
                    _buildInfoRow('UGC-NET / JRF Qualified', profile.hasNetJrf ? 'Yes (${profile.netSubject ?? "Specialization"})' : 'No'),
                  ]),
                  const SizedBox(height: AppDimensions.space20),

                  // Section 3: Statutory Relaxations
                  _buildSectionHeaderWithAction(
                    'Statutory Relaxations & Quota',
                    LucideIcons.shieldCheck,
                    onEdit: () => context.push('/profile/edit'),
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  _buildInfoCard([
                    _buildInfoRow('Social Category', profile.socialCategory),
                    if (profile.socialCategory == 'OBC')
                      _buildInfoRow('OBC Non-Creamy Layer', profile.isObcNcl ? 'Yes (NCL)' : 'No (Creamy Layer)'),
                    _buildInfoRow('PwBD Status', profile.isPwBD ? 'Yes (${profile.pwbdDisabilityType ?? "Benchmark"})' : 'No'),
                    _buildInfoRow('Ex-Serviceman (ESM)', profile.isExServiceman ? 'Yes' : 'No'),
                  ]),
                  const SizedBox(height: AppDimensions.space20),

                  // Section 4: Opportunity Preferences
                  _buildSectionHeaderWithAction(
                    'Opportunity Preferences',
                    LucideIcons.compass,
                    onEdit: () => context.push('/profile/wizard'),
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  _buildInfoCard([
                    _buildInfoRow('Preferred Categories', profile.preferredCategories.map((c) => c.label).join(', ')),
                    _buildInfoRow('Career Disciplines', profile.careerInterests.isNotEmpty ? profile.careerInterests.join(', ') : 'All'),
                    _buildInfoRow('Pan-India Relocation', profile.willingToRelocate ? 'Yes (Pan-India)' : 'State Only'),
                    _buildInfoRow('Max Application Fee Budget', CurrencyFormatter.format(profile.maxApplicationFeeBudget)),
                  ]),
                  const SizedBox(height: AppDimensions.space24),

                  // Sign Out Button
                  OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context, ref),
                    icon: const Icon(LucideIcons.logOut, size: 16, color: AppColors.error),
                    label: const Text('Sign Out of Rexam', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      backgroundColor: AppColors.cardBackground,
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space32),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.white),
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

  Widget _buildSectionHeaderWithAction(String title, IconData icon, {required VoidCallback onEdit}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.secondaryText),
            const SizedBox(width: AppDimensions.space8),
            Text(
              title,
              style: AppTypography.sectionHeader.copyWith(
                color: AppColors.primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(4),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              'Edit',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: rows),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
              style: AppTypography.caption.copyWith(color: AppColors.secondaryText),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
