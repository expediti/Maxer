import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class UserSession {
  final String id;
  final String email;
  final String displayName;
  final bool isGuest;
  final DateTime createdAt;

  const UserSession({
    required this.id,
    required this.email,
    required this.displayName,
    this.isGuest = false,
    required this.createdAt,
  });

  static UserSession guest() {
    return UserSession(
      id: 'guest-candidate-id',
      email: 'guest@rexam.app',
      displayName: 'Guest Candidate',
      isGuest: true,
      createdAt: DateTime.now(),
    );
  }
}

abstract class AuthService {
  Future<UserSession> signInWithGoogle();
  Future<UserSession> signInWithEmail(String email, String password);
  Future<UserSession> signUpWithEmail(String email, String password, String fullName);
  Future<UserSession> signInAsGuest();
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
  Future<UserSession?> getCurrentUser();
  Stream<UserSession?> get onAuthStateChange;
}

class SupabaseAuthService implements AuthService {
  UserSession? _cachedGuestUser;

  @override
  Future<UserSession> signInWithGoogle() async {
    final client = SupabaseConfig.client;
    if (client == null) {
      // Offline / demo fallback
      debugPrint('[REXAM] Supabase not connected. Emulating Google sign-in.');
      _cachedGuestUser = UserSession(
        id: 'google-candidate-001',
        email: 'arjun.sharma@rexam.in',
        displayName: 'Arjun Sharma',
        createdAt: DateTime(2026, 1, 15),
      );
      return _cachedGuestUser!;
    }

    try {
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.rexam://login-callback',
      );
      final currentUser = client.auth.currentUser;
      return UserSession(
        id: currentUser?.id ?? 'candidate-rexam-001',
        email: currentUser?.email ?? 'candidate@rexam.in',
        displayName: currentUser?.userMetadata?['full_name'] ?? 'Candidate',
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[REXAM] Google Auth Error: $e');
      throw Exception('Google sign-in could not be completed: $e');
    }
  }

  @override
  Future<UserSession> signInWithEmail(String email, String password) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      if (email.trim().isEmpty || password.length < 6) {
        throw Exception('Invalid email or password (minimum 6 characters required).');
      }
      _cachedGuestUser = UserSession(
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
      return UserSession(
        id: user.id,
        email: user.email ?? email,
        displayName: user.userMetadata?['full_name'] ?? email.split('@').first,
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<UserSession> signUpWithEmail(String email, String password, String fullName) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      _cachedGuestUser = UserSession(
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
      if (user == null) throw Exception('Sign-up failed.');
      return UserSession(
        id: user.id,
        email: user.email ?? email,
        displayName: fullName.trim(),
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<UserSession> signInAsGuest() async {
    _cachedGuestUser = UserSession.guest();
    return _cachedGuestUser!;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    final client = SupabaseConfig.client;
    if (client != null) {
      await client.auth.resetPasswordForEmail(email.trim());
    }
  }

  @override
  Future<void> signOut() async {
    _cachedGuestUser = null;
    final client = SupabaseConfig.client;
    if (client != null) {
      await client.auth.signOut();
    }
  }

  @override
  Future<UserSession?> getCurrentUser() async {
    if (_cachedGuestUser != null) return _cachedGuestUser;
    final client = SupabaseConfig.client;
    if (client == null) {
      // Default initial session for immediate interactive exploration
      return UserSession(
        id: 'candidate-rexam-001',
        email: 'arjun.sharma@rexam.in',
        displayName: 'Arjun Sharma',
        createdAt: DateTime(2026, 1, 15),
      );
    }

    final user = client.auth.currentUser;
    if (user == null) return null;
    return UserSession(
      id: user.id,
      email: user.email ?? '',
      displayName: user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? 'Candidate',
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    );
  }

  @override
  Stream<UserSession?> get onAuthStateChange async* {
    final client = SupabaseConfig.client;
    if (client == null) {
      yield await getCurrentUser();
      return;
    }

    yield* client.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      if (user == null) return _cachedGuestUser;
      return UserSession(
        id: user.id,
        email: user.email ?? '',
        displayName: user.userMetadata?['full_name'] ?? 'Candidate',
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      );
    });
  }
}
