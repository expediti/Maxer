import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/branding.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/supabase_client.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../profile/presentation/providers/profile_provider.dart';

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
  bool _isLoadingPreferences = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _pushNotifications = prefs.getBool('pref_push_notifications') ?? true;
        _deadlineReminders = prefs.getBool('pref_deadline_reminders') ?? true;
        _corrigendaAlerts = prefs.getBool('pref_corrigenda_alerts') ?? true;
        _resultAnnouncements = prefs.getBool('pref_result_announcements') ?? true;
        _isLoadingPreferences = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingPreferences = false);
      }
    }
  }

  Future<void> _updateNotificationPreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);

      // Sync with Supabase candidate_preferences if logged in
      final client = SupabaseConfig.client;
      final userId = client?.auth.currentUser?.id ?? ref.read(authProvider).user?.id;
      if (client != null && userId != null) {
        await client.from('candidate_preferences').upsert({
          'candidate_id': userId,
          'push_notifications_enabled': _pushNotifications,
          'deadline_reminders_enabled': _deadlineReminders,
          'corrigenda_alerts_enabled': _corrigendaAlerts,
          'result_alerts_enabled': _resultAnnouncements,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'candidate_id');
      }
    } catch (_) {}
  }

  void _showLegalDialog(String title, String content) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          side: BorderSide(color: theme.dividerColor),
        ),
        title: Text(title, style: AppTypography.screenTitle.copyWith(fontSize: 18, color: theme.colorScheme.onSurface)),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: AppTypography.caption.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.55,
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
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          side: BorderSide(color: theme.dividerColor),
        ),
        title: Text('Sign Out', style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(
          'Are you sure you want to end your current session?',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).signOut();
              if (mounted) context.go('/welcome');
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          side: BorderSide(color: theme.dividerColor),
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This action is irreversible. All your profile information, educational records, saved opportunities, application tracking history, and notification subscriptions will be permanently erased.',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, height: 1.5, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _executeAccountDeletion();
            },
            child: const Text('Permanently Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeAccountDeletion() async {
    try {
      final client = SupabaseConfig.client;
      final userId = client?.auth.currentUser?.id ?? ref.read(authProvider).user?.id;
      if (client != null && userId != null) {
        // Delete candidate records from profiles (cascades to related tables)
        await client.from('profiles').delete().eq('id', userId);
      }
      await ref.read(authProvider.notifier).signOut();
      if (mounted) {
        context.go('/welcome');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your account and associated data have been deleted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final user = ref.watch(currentUserProvider);
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
          'Settings',
          style: AppTypography.screenTitle.copyWith(fontSize: 18, color: theme.colorScheme.onSurface),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
            vertical: AppDimensions.space12,
          ),
          children: [
            // Section 1: Candidate Account Overview
            _buildSectionHeader('Account & Identity', LucideIcons.user),
            const SizedBox(height: AppDimensions.space8),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(LucideIcons.userCheck, size: 18, color: theme.colorScheme.onPrimaryContainer),
                    ),
                    title: Text(
                      profileAsync.valueOrNull?.fullName.isNotEmpty == true
                          ? profileAsync.valueOrNull!.fullName
                          : (user?.email?.split('@').first ?? 'Candidate'),
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: theme.colorScheme.onSurface),
                    ),
                    subtitle: Text(
                      user?.email ?? 'No email associated',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    trailing: const Icon(LucideIcons.chevronRight, size: 16),
                    onTap: () => context.push('/profile/wizard'),
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  ListTile(
                    title: Text('Edit Profile & Statutory Criteria', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface)),
                    subtitle: Text('Update educational degrees, category & domicile', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                    trailing: const Icon(LucideIcons.chevronRight, size: 16),
                    onTap: () => context.push('/profile/wizard'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space24),

            // Section 2: Appearance & Theme
            _buildSectionHeader('Appearance & Display', LucideIcons.palette),
            const SizedBox(height: AppDimensions.space8),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  _buildThemeOption(
                    title: 'Dark Mode (Pitch-Black)',
                    subtitle: 'Pure black surface with restrained emerald accents',
                    mode: ThemeMode.dark,
                    currentMode: currentThemeMode,
                    onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  _buildThemeOption(
                    title: 'Light Mode (Crisp White)',
                    subtitle: 'Clean white background with high-contrast typography',
                    mode: ThemeMode.light,
                    currentMode: currentThemeMode,
                    onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  _buildThemeOption(
                    title: 'System Default',
                    subtitle: 'Automatically match device operating system mode',
                    mode: ThemeMode.system,
                    currentMode: currentThemeMode,
                    onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space24),

            // Section 3: Notification Preferences
            _buildSectionHeader('Notification Preferences', LucideIcons.bell),
            const SizedBox(height: AppDimensions.space8),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.colorScheme.onSurface)),
                    subtitle: Text('Receive on-device alert dispatches', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                    value: _pushNotifications,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primaryGreen,
                    onChanged: (val) {
                      setState(() => _pushNotifications = val);
                      _updateNotificationPreference('pref_push_notifications', val);
                    },
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  SwitchListTile(
                    title: Text('Upcoming Deadline Reminders', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface)),
                    subtitle: Text('Alert 7 days, 3 days, 2 days, and 24 hours prior to application close', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                    value: _deadlineReminders,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primaryGreen,
                    onChanged: (val) {
                      setState(() => _deadlineReminders = val);
                      _updateNotificationPreference('pref_deadline_reminders', val);
                    },
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  SwitchListTile(
                    title: Text('Official Corrigenda & Addenda', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface)),
                    subtitle: Text('Immediate alerts when vacancy rules or dates change', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                    value: _corrigendaAlerts,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primaryGreen,
                    onChanged: (val) {
                      setState(() => _corrigendaAlerts = val);
                      _updateNotificationPreference('pref_corrigenda_alerts', val);
                    },
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  SwitchListTile(
                    title: Text('Result & Admit Card Announcements', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface)),
                    subtitle: Text('Alerts when hall tickets and merit lists are released', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                    value: _resultAnnouncements,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primaryGreen,
                    onChanged: (val) {
                      setState(() => _resultAnnouncements = val);
                      _updateNotificationPreference('pref_result_announcements', val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space24),

            // Section 4: Legal & Information
            _buildSectionHeader('About & Legal', LucideIcons.fileText),
            const SizedBox(height: AppDimensions.space8),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text('Terms of Service', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface)),
                    trailing: const Icon(LucideIcons.chevronRight, size: 16),
                    onTap: () => _showLegalDialog(
                      'Terms of Service',
                      '1. REXAM aggregates officially announced examinations, recruitments, admissions, and scholarships across Indian central, state, and autonomous authorities.\n\n2. Information provided is for candidate guidance. Candidates must independently verify all statutory eligibility requirements, qualification criteria, and submission deadlines against official government gazettes before paying application fees.\n\n3. Rexam is an opportunity intelligence platform, not an examination conducting body, and does not issue hall tickets or admit candidates to examination venues.',
                    ),
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  ListTile(
                    title: Text('Privacy Policy', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface)),
                    trailing: const Icon(LucideIcons.chevronRight, size: 16),
                    onTap: () => _showLegalDialog(
                      'Privacy Policy',
                      '1. Demographic and educational attributes stored in REXAM are used strictly for deterministic statutory rule evaluation, opportunity matching, and personalized notification delivery.\n\n2. We do not sell, license, or monetize candidate data.\n\n3. Candidate profile information is cryptographically protected and strictly scoped to your authenticated account.',
                    ),
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  ListTile(
                    leading: AppBranding.logoImage(size: 24),
                    title: Text('About REXAM', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface)),
                    subtitle: Text('Indian Examination & Opportunity Intelligence • v1.0.0', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                    trailing: const Icon(LucideIcons.info, size: 16),
                    onTap: () => _showLegalDialog(
                      'About REXAM',
                      'REXAM: Indian Examination & Opportunity Intelligence\n\nBuilt to empower Indian students and job aspirants to discover opportunities, verify statutory eligibility, track application stages, and never miss a deadline.\n\nCoverage: All 36 States & Union Territories across Central, State, PSU, Research, Academic, and Autonomous bodies.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space24),

            // Section 5: Account Actions
            _buildSectionHeader('Account Actions', LucideIcons.shieldAlert),
            const SizedBox(height: AppDimensions.space8),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.logOut, size: 18, color: AppColors.secondaryText),
                    title: Text('Sign Out', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface)),
                    onTap: _showLogoutDialog,
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  ListTile(
                    leading: const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                    title: const Text('Delete Account & Data', style: TextStyle(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w600)),
                    subtitle: Text('Permanently remove your candidate profile and all tracking records', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                    onTap: _showDeleteAccountDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space32),
          ],
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
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
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
    final theme = Theme.of(context);

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
                      color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
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
                  color: isSelected ? AppColors.primaryGreen : theme.dividerColor,
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
