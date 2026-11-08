import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import 'providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.roundedDefault,
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Delete Candidate Account', style: AppTypography.screenTitle.copyWith(color: AppColors.error)),
        content: Text(
          'This action is irreversible. All your profile attributes, bookmarked opportunities, and application tracker logs will be permanently deleted.',
          style: AppTypography.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion requested.')),
              );
              context.go('/auth');
            },
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Candidate Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Profile Header Card
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppDimensions.roundedDefault,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile.fullName, style: AppTypography.screenTitle),
                              const SizedBox(height: AppDimensions.space2),
                              Text(profile.email, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space8, vertical: AppDimensions.space4),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryBackground,
                              borderRadius: AppDimensions.roundedSmall,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              profile.socialCategory,
                              style: AppTypography.caption.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      // Completion Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('PROFILE COMPLETION', style: AppTypography.label.copyWith(color: AppColors.textSubtle, fontSize: 10)),
                          Text('${profile.completionPercentage}%', style: AppTypography.caption.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space6),
                      LinearProgressIndicator(
                        value: profile.completionPercentage / 100,
                        backgroundColor: AppColors.secondaryBackground,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                        minHeight: 4,
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Profile Attributes (Setup Wizard)'),
                        onPressed: () => context.go('/profile/wizard'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space20),

                // Section A: Personal & Domicile
                _buildSectionTitle('A. Personal & Domicile Information'),
                _buildInfoCard([
                  _buildDataRow('Date of Birth', profile.dateOfBirth != null ? DateFormatter.formatDate(profile.dateOfBirth) : 'Not specified'),
                  _buildDataRow('Age Today', profile.ageInYears != null ? '${profile.ageInYears} years' : 'N/A'),
                  _buildDataRow('Gender', profile.gender ?? 'Not specified'),
                  _buildDataRow('Nationality', profile.nationality),
                  _buildDataRow('State / Domicile', profile.state ?? 'Not specified'),
                  _buildDataRow('District', profile.district ?? 'Not specified'),
                ]),
                const SizedBox(height: AppDimensions.space16),

                // Section B: Category & Statutory Relaxations
                _buildSectionTitle('B. Category & Reservation Attributes'),
                _buildInfoCard([
                  _buildDataRow('Social Category', profile.socialCategory),
                  _buildDataRow('PwBD Status', profile.isPwBD ? 'Yes (Benchmark Disability)' : 'No'),
                  _buildDataRow('Ex-Serviceman (ESM)', profile.isExServiceman ? 'Yes' : 'No'),
                ]),
                const SizedBox(height: AppDimensions.space16),

                // Section C: Educational Background
                _buildSectionTitle('C. Educational Background'),
                _buildInfoCard([
                  _buildDataRow('Highest Qualification', profile.highestQualification ?? 'Not specified'),
                  _buildDataRow('Degree Name', profile.degreeName ?? 'Not specified'),
                  _buildDataRow('Discipline / Branch', profile.stream ?? 'Not specified'),
                  _buildDataRow('College / University', profile.universityOrCollege ?? 'Not specified'),
                  _buildDataRow('Graduation Year', profile.graduationYear != null ? '${profile.graduationYear}' : 'N/A'),
                  _buildDataRow('Percentage / CGPA', profile.cgpaOrPercentage != null ? '${profile.cgpaOrPercentage}%' : 'N/A'),
                  _buildDataRow('Active Backlogs', profile.hasActiveBacklogs ? 'Yes' : 'Zero (Clean record)'),
                ]),
                const SizedBox(height: AppDimensions.space16),

                // Section D: Competitive Exam Scores & Certifications
                _buildSectionTitle('D. Competitive Examination Scores'),
                _buildInfoCard([
                  _buildDataRow('GATE Score', profile.gateScore != null ? '${profile.gateScore} (Year ${profile.gateYear ?? 2025})' : 'Not appeared / Not entered'),
                  _buildDataRow('NET / JRF', profile.hasNetJrf ? 'Qualified' : 'No'),
                  _buildDataRow('Work Experience', '${profile.workExperienceYears} Years'),
                  if (profile.certifications.isNotEmpty)
                    _buildDataRow('Certifications', profile.certifications.join(', ')),
                ]),
                const SizedBox(height: AppDimensions.space16),

                // Section E: Opportunity & Financial Preferences
                _buildSectionTitle('E. Opportunity & Relocation Preferences'),
                _buildInfoCard([
                  _buildDataRow('Target Opportunities', profile.preferredCategories.map((c) => c.label).join(', ')),
                  _buildDataRow('Max Fee Budget', CurrencyFormatter.formatInr(profile.maxApplicationFeeBudget)),
                  _buildDataRow('Willing to Relocate', profile.willingToRelocate ? 'Yes (All India)' : 'State Only'),
                  _buildDataRow('Preferred States', profile.preferredStates.isNotEmpty ? profile.preferredStates.join(', ') : 'All India'),
                ]),
                const SizedBox(height: AppDimensions.space24),

                // Privacy & Deletion Section
                _buildSectionTitle('Privacy & Account Controls'),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space12),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: AppDimensions.roundedDefault,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.security, size: 20, color: AppColors.textMuted),
                        title: Text('Data Privacy & RLS Protection', style: AppTypography.cardTitle),
                        subtitle: Text('Row Level Security ensures your credentials and profile are inaccessible to other candidates.', style: AppTypography.caption),
                      ),
                      const Divider(color: AppColors.border),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                        title: Text('Delete Account and Profile', style: AppTypography.cardTitle.copyWith(color: AppColors.error)),
                        subtitle: Text('Permanently purge your candidate attributes and tracking data.', style: AppTypography.caption),
                        onTap: () => _showDeleteAccountDialog(context, ref),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space32),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space8),
      child: Text(
        title,
        style: AppTypography.sectionHeader.copyWith(color: AppColors.primaryGreen),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.roundedDefault,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value, style: AppTypography.body.copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
