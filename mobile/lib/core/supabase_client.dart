import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  // Configurable through compile-time environment (--dart-define / --dart-define-from-file)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://bryatogngcaissitkgvv.supabase.co',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_beeGHXpm0_UYo41OyoLPDg_jPGR_GfV',
  );

  // Fallback to legacy anon key if specifically requested or needed
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJyeWF0b2duZ2NhaXNzaXRrZ3Z2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQxMTkzMDIsImV4cCI6MjEwOTY5NTMwMn0.by5xepgYaKjHPJuR7Srt5TcP2scwLVZIoUxtXkiRj3U',
  );

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static SupabaseClient? get client {
    if (!_isInitialized) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Use publishable key as preferred, with graceful fallback to anon key
      final keyToUse = supabasePublishableKey.isNotEmpty ? supabasePublishableKey : supabaseAnonKey;
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: keyToUse,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _isInitialized = true;
      debugPrint('[REXAM] Supabase successfully connected to: $supabaseUrl');
    } catch (e) {
      debugPrint('[REXAM] Supabase initialization notice: $e');
      _isInitialized = false;
    }
  }
}
