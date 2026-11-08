import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to end your current session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Candidate Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            final initials = profile.fullName.trim().isNotEmpty
                ? profile.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
                : 'C';
            final completion = profile.completionPercentage;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Profile Identity Card
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: AppDimensions.roundedDefault,
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.primaryBlue,
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
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
                                    style: AppTypography.caption.copyWith(
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
                                      borderRadius: AppDimensions.roundedSmall,
                                      border: Border.all(color: theme.colorScheme.outline),
                                    ),
                                    child: Text(
                                      '${profile.socialCategory} • ${profile.highestQualification ?? "Graduate"}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkTextMain : AppColors.lightTextMain,
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
                            color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
                            borderRadius: AppDimensions.roundedDefault,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Profile Completeness', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  Text(
                                    '$completion%',
                                    style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: completion / 100.0,
                                  backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space12),

                        // Edit Profile Button
                        OutlinedButton.icon(
                          onPressed: () => context.go('/profile/wizard'),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit Profile & Qualifications'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Section 1: Demographics & Personal Info
                  _buildSectionTitle('Personal Demographics'),
                  const SizedBox(height: AppDimensions.space8),
                  _buildInfoCard(
                    theme,
                    [
                      _buildInfoRow('Full Name', profile.fullName),
                      _buildInfoRow('Date of Birth', profile.dateOfBirth != null ? DateFormat('d MMMM yyyy').format(profile.dateOfBirth!) : 'Not set'),
                      _buildInfoRow('Calculated Age', '${profile.calculateAge() ?? "N/A"} Years'),
                      _buildInfoRow('Gender', profile.gender ?? 'Not set'),
                      _buildInfoRow('Nationality', profile.nationality),
                      _buildInfoRow('State of Domicile', profile.state ?? 'All India'),
                      _buildInfoRow('District', profile.district ?? 'Not set'),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Section 2: Educational Qualifications
                  _buildSectionTitle('Educational Qualifications'),
                  const SizedBox(height: AppDimensions.space8),
                  _buildInfoCard(
                    theme,
                    [
                      _buildInfoRow('Highest Qualification', profile.highestQualification ?? 'Not set'),
                      _buildInfoRow('Degree Name', profile.degreeName ?? 'Not set'),
                      _buildInfoRow('Discipline / Branch', profile.stream ?? 'Not set'),
                      _buildInfoRow('University / College', profile.institution ?? 'Not set'),
                      _buildInfoRow('Graduation Year', '${profile.graduationYear ?? "Not set"}'),
                      _buildInfoRow('Score (CGPA / %)', profile.cgpaOrPercentage != null ? '${profile.cgpaOrPercentage}%' : 'Not set'),
                      _buildInfoRow('Active Backlogs', profile.hasActiveBacklogs ? 'Yes (Active Backlogs)' : 'None (Clear record)'),
                      if (profile.gateScore != null)
                        _buildInfoRow('GATE Score', '${profile.gateScore}'),
                      _buildInfoRow('NET / JRF Qualified', profile.hasNetJrf ? 'Yes' : 'No'),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Section 3: Reservation and Relaxations
                  _buildSectionTitle('Statutory Relaxations'),
                  const SizedBox(height: AppDimensions.space8),
                  _buildInfoCard(
                    theme,
                    [
                      _buildInfoRow('Social Category', profile.socialCategory),
                      _buildInfoRow('PwBD Status', profile.isPwBD ? 'Yes (${profile.pwbdDisabilityType ?? "Benchmark"})' : 'No'),
                      _buildInfoRow('Ex-Serviceman (ESM)', profile.isExServiceman ? 'Yes' : 'No'),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Section 4: Opportunity Preferences
                  _buildSectionTitle('Opportunity Preferences'),
                  const SizedBox(height: AppDimensions.space8),
                  _buildInfoCard(
                    theme,
                    [
                      _buildInfoRow('Preferred Categories', profile.preferredCategories.map((c) => c.label).join(', ')),
                      _buildInfoRow('Career Disciplines', profile.careerInterests.join(', ')),
                      _buildInfoRow('Pan-India Relocation', profile.willingToRelocate ? 'Yes (Pan-India)' : 'State Only'),
                      _buildInfoRow('Max Application Fee Budget', CurrencyFormatter.format(profile.maxApplicationFeeBudget)),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space24),

                  // Sign Out Button
                  OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context, ref),
                    icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
                    label: const Text('Sign Out of Rexam', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space32),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
          error: (err, stack) => Center(child: Text('Error loading profile: $err')),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 3, height: 16, color: AppColors.primaryBlue),
        const SizedBox(width: AppDimensions.space8),
        Text(title, style: AppTypography.sectionHeader),
      ],
    );
  }

  Widget _buildInfoCard(ThemeData theme, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppDimensions.roundedDefault,
        border: Border.all(color: theme.colorScheme.outline),
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
          Expanded(flex: 2, child: Text(label, style: AppTypography.caption)),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
