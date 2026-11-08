import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  // Configurable constants or loaded from environment
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://demo-project.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'demo-anon-key-placeholder',
  );

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static Future<void> initialize() async {
    // Only attempt Supabase SDK init if valid non-placeholder credentials exist
    if (supabaseUrl.contains('demo-project') || supabaseAnonKey.contains('demo-anon-key')) {
      debugPrint('[REXAM] Operating in local offline-first development mode with authentic test data.');
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _isInitialized = true;
      debugPrint('[REXAM] Supabase successfully connected with RLS.');
    } catch (e) {
      debugPrint('[REXAM] Supabase connection error: $e. Falling back to local offline mode.');
      _isInitialized = false;
    }
  }
}

