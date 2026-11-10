import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:rexam/core/constants/app_colors.dart';
import 'package:rexam/core/constants/app_dimensions.dart';
import 'package:rexam/core/theme/app_typography.dart';
import 'package:rexam/features/profile/domain/profile_completion.dart';
import 'package:rexam/features/profile/presentation/providers/profile_provider.dart';
import 'package:rexam/features/profile/presentation/widgets/avatar_picker.dart';

class ProfileCompletionScreen extends ConsumerWidget {
  const ProfileCompletionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: theme.colorScheme.onSurface, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: Text(
          'Profile Completeness',
          style: AppTypography.screenTitle.copyWith(fontSize: 18, color: theme.colorScheme.onSurface),
        ),
      ),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            final report = ProfileCompletionReport.evaluate(profile);

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space12,
              ),
              children: [
                // Top Completeness Score Card
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      // Circular progress
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 72,
                            height: 72,
                            child: CircularProgressIndicator(
                              value: report.percentage / 100,
                              strokeWidth: 6,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                report.percentage == 100 ? AppColors.primaryGreen : AppColors.primaryGreen,
                              ),
                            ),
                          ),
                          Text(
                            '${report.percentage}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppDimensions.space20),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.percentage == 100
                                  ? 'Profile 100% Complete'
                                  : '${100 - report.percentage}% Details Missing',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${report.completedCount} of ${report.totalCoreCount} core statutory eligibility attributes verified.',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space20),

                // 1. Missing Items Section (Highlighted in Amber/Accent)
                if (report.missingItems.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Missing Details to Reach 100% (${report.missingItems.length})',
                    LucideIcons.alertCircle,
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  ...report.missingItems.map(
                    (item) => _buildItemTile(
                      context: context,
                      item: item,
                      theme: theme,
                      onAction: () => _handleItemAction(context, item.key),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space24),
                ],

                // 2. Completed Items Section (Green Checks)
                _buildSectionHeader(
                  'Completed Attributes (${report.completedItems.length})',
                  LucideIcons.checkCircle2,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(height: AppDimensions.space8),
                ...report.completedItems.map(
                  (item) => _buildItemTile(
                    context: context,
                    item: item,
                    theme: theme,
                    onAction: () => _handleItemAction(context, item.key),
                  ),
                ),
                const SizedBox(height: AppDimensions.space24),

                // 3. Optional Concessions & Qualifications
                _buildSectionHeader(
                  'Optional Statutory Concessions (${report.optionalItems.length})',
                  LucideIcons.sliders,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppDimensions.space8),
                ...report.optionalItems.map(
                  (item) => _buildItemTile(
                    context: context,
                    item: item,
                    theme: theme,
                    isOptional: true,
                    onAction: () => _handleItemAction(context, item.key),
                  ),
                ),
                const SizedBox(height: AppDimensions.space32),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text('Unable to load profile data: $err'),
          ),
        ),
      ),
    );
  }

  void _handleItemAction(BuildContext context, String key) {
    if (key == 'avatar_url') {
      // Trigger avatar picker modal
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Update Profile Photograph'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('Tap the avatar circle to select or take an official photo:'),
              SizedBox(height: 16),
              AvatarPickerWidget(radius: 44, editable: true),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } else {
      context.push('/profile/wizard');
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, {required Color color}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: AppDimensions.space8),
        Text(
          title,
          style: AppTypography.sectionHeader.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildItemTile({
    required BuildContext context,
    required ProfileCompletionItem item,
    required ThemeData theme,
    required VoidCallback onAction,
    bool isOptional = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space8),
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(
          color: !item.isCompleted && !isOptional
              ? AppColors.warning.withValues(alpha: 0.5)
              : theme.dividerColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.isCompleted
                ? LucideIcons.circleCheck
                : (isOptional ? LucideIcons.circleDot : LucideIcons.circleAlert),
            size: 18,
            color: item.isCompleted
                ? AppColors.primaryGreen
                : (isOptional ? theme.colorScheme.onSurfaceVariant : AppColors.warning),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.space8),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: !item.isCompleted && !isOptional
                  ? AppColors.primaryGreen
                  : theme.colorScheme.surfaceContainerHighest,
              foregroundColor: !item.isCompleted && !isOptional
                  ? Colors.black
                  : theme.colorScheme.onSurface,
            ),
            onPressed: onAction,
            child: Text(
              item.isCompleted ? 'Edit' : item.actionLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: !item.isCompleted && !isOptional ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

