import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/supabase_client.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushNotifications = true;
  bool _deadlineReminders = true;
  bool _corrigendaAlerts = true;
  bool _resultAnnouncements = true;

  void _showLegalDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(title, style: AppTypography.screenTitle.copyWith(fontSize: 18)),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMain,
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to end your current session?',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).signOut();
              if (mounted) context.go('/welcome');
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ref.watch(themeModeProvider);

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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textMain, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
          ),
          title: Text(
            'Settings',
            style: AppTypography.screenTitle.copyWith(fontSize: 18),
          ),
        ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
            vertical: AppDimensions.space12,
          ),
          children: [
            // Section 1: Appearance & Theme
            _buildSectionHeader('Appearance & Theme', LucideIcons.palette),
            const SizedBox(height: AppDimensions.space8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildThemeOption(
                    title: 'Pitch-Black Emerald (Default Dark)',
                    subtitle: 'Pitch-black background with subtle emerald accents',
                    mode: ThemeMode.dark,
                    currentMode: currentThemeMode,
                    onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _buildThemeOption(
                    title: 'Light Theme',
                    subtitle: 'Warm light surface with dark typography',
                    mode: ThemeMode.light,
                    currentMode: currentThemeMode,
                    onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _buildThemeOption(
                    title: 'System Default',
                    subtitle: 'Match Android system display mode',
                    mode: ThemeMode.system,
                    currentMode: currentThemeMode,
                    onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space24),

            // Section 2: Notification Preferences
            _buildSectionHeader('Notification Preferences', LucideIcons.bell),
            const SizedBox(height: AppDimensions.space8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textMain)),
                    subtitle: const Text('Receive on-device alert dispatches', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    value: _pushNotifications,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primaryGreen,
                    onChanged: (val) => setState(() => _pushNotifications = val),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  SwitchListTile(
                    title: const Text('Upcoming Deadline Reminders', style: TextStyle(fontSize: 13, color: AppColors.textMain)),
                    subtitle: const Text('Alert 7 days, 3 days, and 24 hours prior to application close', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    value: _deadlineReminders,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primaryGreen,
                    onChanged: (val) => setState(() => _deadlineReminders = val),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  SwitchListTile(
                    title: const Text('Official Corrigenda & Addenda', style: TextStyle(fontSize: 13, color: AppColors.textMain)),
                    subtitle: const Text('Immediate alert when vacancy rules or dates change', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    value: _corrigendaAlerts,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primaryGreen,
                    onChanged: (val) => setState(() => _corrigendaAlerts = val),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  SwitchListTile(
                    title: const Text('Result & Admit Card Announcements', style: TextStyle(fontSize: 13, color: AppColors.textMain)),
                    subtitle: const Text('Alerts when hall tickets and merit lists are released', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    value: _resultAnnouncements,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primaryGreen,
                    onChanged: (val) => setState(() => _resultAnnouncements = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space24),

            // Section 3: Supabase Backend Infrastructure
            _buildSectionHeader('Backend Infrastructure', LucideIcons.database),
            const SizedBox(height: AppDimensions.space8),
            Container(
              padding: const EdgeInsets.all(AppDimensions.space16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: SupabaseConfig.isInitialized ? AppColors.primaryGreen : AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space8),
                      Text(
                        SupabaseConfig.isInitialized ? 'Supabase Connected' : 'Supabase Connecting',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textMain),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Endpoint: ${SupabaseConfig.supabaseUrl}',
                    style: AppTypography.caption.copyWith(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'All candidate queries are authenticated and protected under PostgreSQL Row Level Security (RLS).',
                    style: TextStyle(fontSize: 11, color: AppColors.primaryGreen),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space24),

            // Section 4: Legal & About
            _buildSectionHeader('About & Legal', LucideIcons.fileText),
            const SizedBox(height: AppDimensions.space8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Terms of Service', style: TextStyle(fontSize: 13, color: AppColors.textMain)),
                    trailing: const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textMuted),
                    onTap: () => _showLegalDialog(
                      'Terms of Service',
                      '1. REXAM aggregates officially announced examinations and job recruitments across Indian central, state, and PSU authorities.\n\n2. Information provided is for candidate guidance. Candidates must independently verify all eligibility requirements and submission deadlines against official gazettes before paying application fees.\n\n3. Rexam is not an examination conducting body and does not issue admit cards or admit candidates to examination venues.',
                    ),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  ListTile(
                    title: const Text('Privacy Policy', style: TextStyle(fontSize: 13, color: AppColors.textMain)),
                    trailing: const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textMuted),
                    onTap: () => _showLegalDialog(
                      'Privacy Policy',
                      '1. Demographic and educational attributes stored in REXAM are used strictly for deterministic rule checking and notification delivery.\n\n2. We do not sell or monetize personal candidate data.\n\n3. All data stored in Supabase uses PostgreSQL Row Level Security restricting profile access solely to your authenticated account.',
                    ),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  ListTile(
                    title: const Text('About Rexam', style: TextStyle(fontSize: 13, color: AppColors.textMain)),
                    subtitle: const Text('Version 1.0.0 (Production Build)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    trailing: const Icon(LucideIcons.info, size: 16, color: AppColors.textMuted),
                    onTap: () => _showLegalDialog(
                      'About REXAM',
                      'REXAM: Indian Examination & Opportunity Intelligence\n\nBuilt to empower Indian students and job aspirants to discover opportunities, verify statutory eligibility, track application stages, and never miss a deadline.\n\nEngine: Deterministic Rule Validator\nDatabase: Supabase PostgreSQL (RLS Enforced)\nTarget: All India Recruitment & Admissions',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space24),

            // Sign Out Button
            ElevatedButton.icon(
              onPressed: _showLogoutDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
              ),
              icon: const Icon(LucideIcons.logOut, size: 16),
              label: const Text('Sign Out'),
            ),
            const SizedBox(height: AppDimensions.space32),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primaryGreen),
        const SizedBox(width: AppDimensions.space8),
        Text(
          title,
          style: AppTypography.sectionHeader.copyWith(
            color: AppColors.textMain,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption({
    required String title,
    required String subtitle,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required VoidCallback onTap,
  }) {
    final isSelected = mode == currentMode;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppColors.textMain : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSubtle),
                  ),
                ],
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryGreen : AppColors.border,
                  width: isSelected ? 5.0 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
