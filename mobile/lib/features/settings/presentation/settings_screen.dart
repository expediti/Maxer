import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
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
  String _selectedLanguage = 'English';

  void _showLegalDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.roundedDefault,
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(title, style: AppTypography.screenTitle),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: AppTypography.bodyMuted.copyWith(height: 1.45),
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
          borderRadius: AppDimensions.roundedDefault,
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Sign Out', style: AppTypography.screenTitle),
        content: Text('Are you sure you want to end your current session?', style: AppTypography.bodyMuted),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).signOut();
              if (mounted) context.go('/auth');
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          children: [
            // Preference Section
            Text('APPLICATION PREFERENCES', style: AppTypography.label.copyWith(color: AppColors.primaryGreen)),
            const SizedBox(height: AppDimensions.space8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppDimensions.roundedDefault,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.dark_mode_outlined, size: 20, color: AppColors.primaryGreen),
                    title: Text('Appearance', style: AppTypography.cardTitle),
                    subtitle: Text('Rexam Deep Charcoal & Muted Green (System Default)', style: AppTypography.caption),
                  ),
                  const Divider(color: AppColors.border),
                  ListTile(
                    leading: const Icon(Icons.language_outlined, size: 20, color: AppColors.textMuted),
                    title: Text('Display Language', style: AppTypography.cardTitle),
                    trailing: DropdownButton<String>(
                      value: _selectedLanguage,
                      dropdownColor: AppColors.surface,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'English', child: Text('English')),
                        DropdownMenuItem(value: 'Hindi', child: Text('हिंदी (Hindi)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedLanguage = val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space20),

            // Notification Controls
            Text('NOTIFICATIONS & ALERTS', style: AppTypography.label.copyWith(color: AppColors.primaryGreen)),
            const SizedBox(height: AppDimensions.space8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppDimensions.roundedDefault,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    activeThumbColor: AppColors.primaryGreen,
                    title: Text('Push Notifications', style: AppTypography.cardTitle),
                    subtitle: Text('Receive real-time alerts on your device', style: AppTypography.caption),
                    value: _pushNotifications,
                    onChanged: (val) => setState(() => _pushNotifications = val),
                  ),
                  const Divider(color: AppColors.border),
                  SwitchListTile(
                    activeThumbColor: AppColors.primaryGreen,
                    title: Text('Urgent Deadline Reminders', style: AppTypography.cardTitle),
                    subtitle: Text('Notifications 48 hours and 24 hours prior to portal closure', style: AppTypography.caption),
                    value: _deadlineReminders,
                    onChanged: (val) => setState(() => _deadlineReminders = val),
                  ),
                  const Divider(color: AppColors.border),
                  SwitchListTile(
                    activeThumbColor: AppColors.primaryGreen,
                    title: Text('Official Corrigenda & Amendments', style: AppTypography.cardTitle),
                    subtitle: Text('Instant updates when exam dates or criteria change', style: AppTypography.caption),
                    value: _corrigendaAlerts,
                    onChanged: (val) => setState(() => _corrigendaAlerts = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space20),

            // Legal & About
            Text('LEGAL & PLATFORM INTEGRITY', style: AppTypography.label.copyWith(color: AppColors.primaryGreen)),
            const SizedBox(height: AppDimensions.space8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppDimensions.roundedDefault,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.policy_outlined, size: 20, color: AppColors.textMuted),
                    title: Text('Privacy Policy', style: AppTypography.cardTitle),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => _showLegalDialog(
                      'Privacy Policy',
                      'Rexam does not sell candidate data. Personal attributes entered in your profile are utilized strictly for deterministic eligibility checks and personalized opportunity matching. All sensitive tokens are securely stored locally using secure hardware storage, with PostgreSQL Row-Level Security ensuring multi-tenant isolation.',
                    ),
                  ),
                  const Divider(color: AppColors.border),
                  ListTile(
                    leading: const Icon(Icons.gavel_outlined, size: 20, color: AppColors.textMuted),
                    title: Text('Terms of Service & Disclaimer', style: AppTypography.cardTitle),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => _showLegalDialog(
                      'Terms of Service & Disclaimer',
                      'Rexam is an independent discovery and eligibility intelligence platform. We do not represent any government agency, PSU, or recruiting body. We do not submit application forms on behalf of candidates. Users must verify all critical dates, eligibility clauses, and instructions against the official notification PDF before submitting applications.',
                    ),
                  ),
                  const Divider(color: AppColors.border),
                  ListTile(
                    leading: const Icon(Icons.support_agent_outlined, size: 20, color: AppColors.textMuted),
                    title: Text('Contact Support & Source Suggestions', style: AppTypography.cardTitle),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => _showLegalDialog(
                      'Support & Official Source Intake',
                      'For support, reporting broken official links, or suggesting official state gazettes and university recruitment sources, contact us at official@rexam.app.',
                    ),
                  ),
                  const Divider(color: AppColors.border),
                  ListTile(
                    leading: const Icon(Icons.info_outline, size: 20, color: AppColors.textMuted),
                    title: Text('About Rexam', style: AppTypography.cardTitle),
                    subtitle: Text('Version 1.0.0-prod (Build 2026.11)', style: AppTypography.caption),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space24),

            // Sign out
            OutlinedButton.icon(
              icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
              label: Text('Sign Out of Rexam', style: AppTypography.button.copyWith(color: AppColors.error)),
              onPressed: _showLogoutDialog,
            ),
            const SizedBox(height: AppDimensions.space32),
          ],
        ),
      ),
    );
  }
}
