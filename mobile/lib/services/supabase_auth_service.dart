import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class UserSession {
  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;

  const UserSession({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
  });
}

abstract class AuthService {
  Future<UserSession> signInWithGoogle();
  Future<UserSession> signInWithEmail(String email, String password);
  Future<UserSession> signUpWithEmail(String email, String password, String fullName);
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
  Future<UserSession?> getCurrentUser();
  Stream<UserSession?> get onAuthStateChange;
}

class SupabaseAuthService implements AuthService {
  @override
  Future<UserSession> signInWithGoogle() async {
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
      return UserSession(
        id: user?.id ?? '',
        email: user?.email ?? '',
        displayName: user?.userMetadata?['full_name'] ?? 'Candidate',
        createdAt: user != null ? (DateTime.tryParse(user.createdAt) ?? DateTime.now()) : DateTime.now(),
      );
    } catch (e) {
      debugPrint('[REXAM] Google Auth Error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', '').replaceFirst('AuthException: ', ''));
    }
  }

  @override
  Future<UserSession> signInWithEmail(String email, String password) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw Exception('Supabase connection unavailable.');
    }

    try {
      final res = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = res.user;
      if (user == null) throw Exception('Authentication failed.');
      return UserSession(
        id: user.id,
        email: user.email ?? email,
        displayName: user.userMetadata?['full_name'] ?? email.split('@').first,
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', '').replaceFirst('AuthException: ', ''));
    }
  }

  @override
  Future<UserSession> signUpWithEmail(String email, String password, String fullName) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw Exception('Supabase connection unavailable.');
    }

    try {
      final res = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );
      final user = res.user;
      if (user == null) throw Exception('Registration failed.');
      return UserSession(
        id: user.id,
        email: user.email ?? email,
        displayName: fullName.trim(),
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', '').replaceFirst('AuthException: ', ''));
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    final client = SupabaseConfig.client;
    if (client == null) return;
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
        debugPrint('[REXAM] Sign out error: $e');
      }
    }
  }

  @override
  Future<UserSession?> getCurrentUser() async {
    final client = SupabaseConfig.client;
    if (client != null) {
      final user = client.auth.currentUser;
      if (user != null) {
        return UserSession(
          id: user.id,
          email: user.email ?? '',
          displayName: user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? 'Candidate',
          createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
        );
      }
    }
    return null;
  }

  @override
  Stream<UserSession?> get onAuthStateChange {
    final client = SupabaseConfig.client;
    if (client == null) return Stream.value(null);
    return client.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      if (user == null) return null;
      return UserSession(
        id: user.id,
        email: user.email ?? '',
        displayName: user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? 'Candidate',
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      );
    });
  }
}
