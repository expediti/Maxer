import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rexam/core/supabase_client.dart';

const String _kThemePrefKey = 'rexam_theme_mode';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    // 1. Immediate local cache retrieval (Default to Light Mode on fresh install)
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_kThemePrefKey);
      if (savedTheme == 'dark') {
        state = ThemeMode.dark;
      } else if (savedTheme == 'system') {
        state = ThemeMode.system;
      } else {
        // Strict requirement: Default to Light mode for fresh installs
        state = ThemeMode.light;
      }
    } catch (_) {}

    // 2. Cross-device sync: If user is authenticated, retrieve saved preference from Supabase
    try {
      final client = SupabaseConfig.client;
      final userId = client?.auth.currentUser?.id;
      if (client != null && userId != null) {
        final data = await client
            .from('candidate_preferences')
            .select('theme_mode')
            .eq('candidate_id', userId)
            .maybeSingle();

        if (data != null && data['theme_mode'] != null) {
          final remoteTheme = data['theme_mode'] as String;
          ThemeMode remoteMode;
          if (remoteTheme == 'light') {
            remoteMode = ThemeMode.light;
          } else if (remoteTheme == 'dark') {
            remoteMode = ThemeMode.dark;
          } else {
            remoteMode = ThemeMode.system;
          }

          if (state != remoteMode) {
            state = remoteMode;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_kThemePrefKey, remoteTheme);
          }
        }
      }
    } catch (_) {
      // Non-blocking fallback to local preference
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;

    // 1. Persist locally immediately
    final modeStr = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemePrefKey, modeStr);
    } catch (_) {}

    // 2. Synchronize to Supabase profile preferences
    try {
      final client = SupabaseConfig.client;
      final userId = client?.auth.currentUser?.id;
      if (client != null && userId != null) {
        await client.from('candidate_preferences').upsert({
          'candidate_id': userId,
          'theme_mode': modeStr,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'candidate_id');
      }
    } catch (_) {
      // Offline or network error gracefully ignored
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
