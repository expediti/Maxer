import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';
import '../domain/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> signInWithEmail(String email, String password);
  Future<UserModel> signUpWithEmail(String email, String password, String fullName);
  Future<UserModel> signInWithGoogle();
  Future<UserModel> signInAsGuest();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
}

class SupabaseAuthRepository implements AuthRepository {
  UserModel? _cachedGuestUser;

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      if (email.trim().isEmpty || password.length < 6) {
        throw Exception('Invalid email or password (minimum 6 characters required).');
      }
      _cachedGuestUser = UserModel(
        id: 'candidate-rexam-001',
        email: email.trim(),
        displayName: email.split('@').first.toUpperCase(),
        createdAt: DateTime.now(),
      );
      return _cachedGuestUser!;
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
        email: user.email ?? email,
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
      _cachedGuestUser = UserModel(
        id: 'candidate-new-${DateTime.now().millisecondsSinceEpoch}',
        email: email.trim(),
        displayName: fullName.trim().isEmpty ? 'Candidate' : fullName.trim(),
        createdAt: DateTime.now(),
      );
      return _cachedGuestUser!;
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
        email: user.email ?? email,
        displayName: fullName.trim().isEmpty ? 'Candidate' : fullName.trim(),
        isEmailVerified: user.emailConfirmedAt != null,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', '').replaceFirst('AuthException: ', ''));
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    final client = SupabaseConfig.client;
    if (client == null) {
      _cachedGuestUser = UserModel(
        id: 'google-candidate-001',
        email: 'candidate.google@rexam.in',
        displayName: 'Google Candidate',
        createdAt: DateTime.now(),
      );
      return _cachedGuestUser!;
    }

    try {
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.rexam://login-callback',
      );
      final user = client.auth.currentUser;
      return UserModel(
        id: user?.id ?? 'candidate-rexam-001',
        email: user?.email ?? 'candidate@rexam.in',
        displayName: user?.userMetadata?['full_name'] ?? 'Candidate',
        isEmailVerified: true,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[REXAM] Google Auth Notice: $e');
      throw Exception('Google sign-in could not be completed: $e');
    }
  }

  @override
  Future<UserModel> signInAsGuest() async {
    _cachedGuestUser = UserModel.guest();
    return _cachedGuestUser!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.auth.resetPasswordForEmail(email.trim());
      } catch (e) {
        throw Exception(e.toString().replaceFirst('Exception: ', '').replaceFirst('AuthException: ', ''));
      }
    }
  }

  @override
  Future<void> signOut() async {
    _cachedGuestUser = null;
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
    if (_cachedGuestUser != null) return _cachedGuestUser;
    final client = SupabaseConfig.client;
    if (client != null) {
      final user = client.auth.currentUser;
      if (user != null) {
        return UserModel(
          id: user.id,
          email: user.email ?? '',
          displayName: user.userMetadata?['full_name'] ?? user.email?.split('@').first,
          isEmailVerified: user.emailConfirmedAt != null,
          createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
        );
      }
    }
    return null;
  }
}
