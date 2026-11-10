import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';
import '../domain/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> signInWithEmail(String email, String password);
  Future<UserModel> signUpWithEmail(String email, String password, String fullName);
  Future<UserModel?> signInWithGoogle();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<bool> checkProfileExists(String userId);
}

class SupabaseAuthRepository implements AuthRepository {
  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw Exception('Supabase connection unavailable. Please check your internet connectivity.');
    }

    try {
      final res = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = res.user;
      if (user == null) throw Exception('Authentication failed.');
      return UserModel(
        id: user.id,
        email: user.email ?? email.trim(),
        displayName: user.userMetadata?['full_name'] ?? email.split('@').first,
        isEmailVerified: user.emailConfirmedAt != null,
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', '').replaceFirst('AuthException: ', ''));
    }
  }

  @override
  Future<UserModel> signUpWithEmail(String email, String password, String fullName) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw Exception('Supabase connection unavailable. Please check your internet connectivity.');
    }

    try {
      final res = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );
      final user = res.user;
      if (user == null) throw Exception('Registration could not be completed.');
      return UserModel(
        id: user.id,
        email: user.email ?? email.trim(),
        displayName: fullName.trim().isEmpty ? 'Candidate' : fullName.trim(),
        isEmailVerified: user.emailConfirmedAt != null,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', '').replaceFirst('AuthException: ', ''));
    }
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw Exception('Supabase connection unavailable.');
    }

    try {
      final launched = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.rexam://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception('Failed to open browser for Google authentication.');
      }
      final user = client.auth.currentUser;
      if (user != null) {
        return UserModel(
          id: user.id,
          email: user.email ?? '',
          displayName: user.userMetadata?['full_name'] ??
              user.userMetadata?['name'] ??
              user.email?.split('@').first ??
              'Candidate',
          isEmailVerified: true,
          createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      debugPrint('[REXAM] Google Auth Error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', '').replaceFirst('AuthException: ', ''));
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw Exception('Supabase connection unavailable.');
    }
    try {
      await client.auth.resetPasswordForEmail(email.trim());
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', '').replaceFirst('AuthException: ', ''));
    }
  }

  @override
  Future<void> signOut() async {
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (e) {
        debugPrint('[REXAM] Sign out notice: $e');
      }
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final client = SupabaseConfig.client;
    if (client != null) {
      final user = client.auth.currentUser;
      if (user != null) {
        return UserModel(
          id: user.id,
          email: user.email ?? '',
          displayName: user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? 'Candidate',
          isEmailVerified: user.emailConfirmedAt != null,
          createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
        );
      }
    }
    return null;
  }

  @override
  Future<bool> checkProfileExists(String userId) async {
    final client = SupabaseConfig.client;
    if (client == null) return false;
    try {
      final res = await client
          .from('profiles')
          .select('id, full_name, date_of_birth, state, social_category, onboarding_completed_at')
          .eq('id', userId)
          .maybeSingle();

      if (res == null) return false;

      // 1. Explicit onboarding completion timestamp
      if (res['onboarding_completed_at'] != null) {
        return true;
      }

      final fullName = (res['full_name'] as String?)?.trim() ?? '';
      final hasName = fullName.isNotEmpty;
      final hasDob = res['date_of_birth'] != null;
      final hasState = (res['state'] as String?)?.trim().isNotEmpty == true;
      final hasCategory = (res['social_category'] as String?)?.trim().isNotEmpty == true;

      // 2. Core demographic criteria met
      if (hasName && hasDob && (hasState || hasCategory)) {
        return true;
      }

      // 3. Fallback verification: check if candidate education details are recorded
      try {
        final edu = await client
            .from('candidate_education')
            .select('id, highest_qualification')
            .eq('candidate_id', userId)
            .maybeSingle();
        if (hasName && hasDob && edu != null) {
          return true;
        }
      } catch (_) {}

      return false;
    } catch (e) {
      // Column onboarding_completed_at might not exist yet; query basic columns
      try {
        final fallbackRes = await client
            .from('profiles')
            .select('id, full_name, date_of_birth, state, social_category')
            .eq('id', userId)
            .maybeSingle();
        if (fallbackRes == null) return false;
        final fullName = (fallbackRes['full_name'] as String?)?.trim() ?? '';
        final hasName = fullName.isNotEmpty;
        final hasDob = fallbackRes['date_of_birth'] != null;
        final hasState = (fallbackRes['state'] as String?)?.trim().isNotEmpty == true;
        return hasName && hasDob && hasState;
      } catch (fallbackErr) {
        debugPrint('[REXAM] Profile check fallback error: $fallbackErr');
        return false;
      }
    }
  }
}
