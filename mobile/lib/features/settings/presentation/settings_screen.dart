// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        title: Text(title, style: AppTypography.screenTitle),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: AppTypography.bodyMuted.copyWith(height: 1.5),
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
    final theme = Theme.of(context);
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          children: [
            // Section 1: Appearance & Theme
            _buildSectionHeader('Appearance & Theme'),
            const SizedBox(height: AppDimensions.space8),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: AppDimensions.roundedDefault,
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('System Default'),
                    subtitle: const Text('Match Android system display settings', style: TextStyle(fontSize: 12)),
                    value: ThemeMode.system,
                    groupValue: currentThemeMode,
                    activeColor: AppColors.primaryBlue,
                    onChanged: (mode) {
                      if (mode != null) {
                        ref.read(themeModeProvider.notifier).setThemeMode(mode);
                      }
                    },
                  ),
                  Divider(color: theme.colorScheme.outline, height: 1),
                  RadioListTile<ThemeMode>(
                    title: const Text('Light Theme'),
                    subtitle: const Text('Warm off-white background with dark charcoal typography', style: TextStyle(fontSize: 12)),
                    value: ThemeMode.light,
                    groupValue: currentThemeMode,
                    activeColor: AppColors.primaryBlue,
                    onChanged: (mode) {
                      if (mode != null) {
                        ref.read(themeModeProvider.notifier).setThemeMode(mode);
                      }
                    },
                  ),
                  Divider(color: theme.colorScheme.outline, height: 1),
                  RadioListTile<ThemeMode>(
                    title: const Text('Dark Theme'),
                    subtitle: const Text('Deep slate background with restrained borders', style: TextStyle(fontSize: 12)),
                    value: ThemeMode.dark,
                    groupValue: currentThemeMode,
                    activeColor: AppColors.primaryBlue,
                    onChanged: (mode) {
                      if (mode != null) {
                        ref.read(themeModeProvider.notifier).setThemeMode(mode);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space24),

            // Section 2: Notification Preferences
            _buildSectionHeader('Notification Preferences'),
            const SizedBox(height: AppDimensions.space8),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: AppDimensions.roundedDefault,
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Receive on-device alert dispatches', style: TextStyle(fontSize: 12)),
                    value: _pushNotifications,
                    activeTrackColor: AppColors.primaryBlue,
                    activeThumbColor: Colors.white,
                    onChanged: (val) => setState(() => _pushNotifications = val),
                  ),
                  Divider(color: theme.colorScheme.outline, height: 1),
                  SwitchListTile(
                    title: const Text('Upcoming Deadline Reminders'),
                    subtitle: const Text('Alert 7 days, 3 days, and 24 hours prior to application close', style: TextStyle(fontSize: 12)),
                    value: _deadlineReminders,
                    activeTrackColor: AppColors.primaryBlue,
                    activeThumbColor: Colors.white,
                    onChanged: (val) => setState(() => _deadlineReminders = val),
                  ),
                  Divider(color: theme.colorScheme.outline, height: 1),
                  SwitchListTile(
                    title: const Text('Official Corrigenda & Addenda'),
                    subtitle: const Text('Immediate alert when vacancy rules or exam dates change', style: TextStyle(fontSize: 12)),
                    value: _corrigendaAlerts,
                    activeTrackColor: AppColors.primaryBlue,
                    activeThumbColor: Colors.white,
                    onChanged: (val) => setState(() => _corrigendaAlerts = val),
                  ),
                  Divider(color: theme.colorScheme.outline, height: 1),
                  SwitchListTile(
                    title: const Text('Result & Admit Card Announcements'),
                    subtitle: const Text('Alerts when hall tickets and merit lists are released', style: TextStyle(fontSize: 12)),
                    value: _resultAnnouncements,
                    activeTrackColor: AppColors.primaryBlue,
                    activeThumbColor: Colors.white,
                    onChanged: (val) => setState(() => _resultAnnouncements = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space24),

            // Section 3: Supabase Backend Status
            _buildSectionHeader('Backend Infrastructure'),
            const SizedBox(height: AppDimensions.space8),
            Container(
              padding: const EdgeInsets.all(AppDimensions.space16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: AppDimensions.roundedDefault,
                border: Border.all(color: theme.colorScheme.outline),
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
                          color: SupabaseConfig.isInitialized ? AppColors.success : AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space8),
                      Text(
                        SupabaseConfig.isInitialized ? 'Supabase Connected' : 'Supabase Connecting',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Endpoint: ${SupabaseConfig.supabaseUrl}',
                    style: AppTypography.caption.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'All candidate queries are authenticated and protected under Row Level Security (RLS).',
                    style: TextStyle(fontSize: 11, color: AppColors.success),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space24),

            // Section 4: Legal & About
            _buildSectionHeader('About & Legal'),
            const SizedBox(height: AppDimensions.space8),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: AppDimensions.roundedDefault,
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Terms of Service'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _showLegalDialog(
                      'Terms of Service',
                      '1. REXAM aggregates officially announced examinations and job recruitments across Indian central, state, and PSU authorities.\n\n2. Information provided is for candidate guidance. Candidates must independently verify all eligibility requirements and submission deadlines against official gazettes before paying application fees.\n\n3. Rexam is not an examination conducting body and does not issue admit cards or admit candidates to examination venues.',
                    ),
                  ),
                  Divider(color: theme.colorScheme.outline, height: 1),
                  ListTile(
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _showLegalDialog(
                      'Privacy Policy',
                      '1. Demographic and educational attributes stored in REXAM are used strictly for deterministic rule checking and notification delivery.\n\n2. We do not sell or monetize personal candidate data.\n\n3. All data stored in Supabase uses PostgreSQL Row Level Security restricting profile access solely to your authenticated account.',
                    ),
                  ),
                  Divider(color: theme.colorScheme.outline, height: 1),
                  ListTile(
                    title: const Text('About Rexam'),
                    subtitle: const Text('Version 1.0.0+1 (Production Release)'),
                    trailing: const Icon(Icons.info_outline, size: 20),
                    onTap: () => _showLegalDialog(
                      'About REXAM',
                      'REXAM: Indian Examination & Opportunity Intelligence\n\nBuilt to empower Indian students and job aspirants to discover opportunities, verify statutory eligibility, track application stages, and never miss a deadline.\n\nEngine: Deterministic Rule Validator\nDatabase: Supabase PostgreSQL (RLS Enforced)\nTarget: All India Recruitment & Admissions',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space24),

            // Sign Out
            ElevatedButton.icon(
              onPressed: _showLogoutDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign Out'),
            ),
            const SizedBox(height: AppDimensions.space32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 3, height: 16, color: AppColors.primaryBlue),
        const SizedBox(width: AppDimensions.space8),
        Text(title, style: AppTypography.sectionHeader),
      ],
    );
  }
}
