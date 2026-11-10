import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import 'package:rexam/core/supabase_client.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_state.dart';
import '../../domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  StreamSubscription<supa.AuthState>? _authStateSubscription;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    _setupAuthStateListener();
    await checkInitialSession();
  }

  void _setupAuthStateListener() {
    try {
      final client = SupabaseConfig.client;
      if (client == null) return;

      _authStateSubscription = client.auth.onAuthStateChange.listen((data) async {
        final supa.AuthChangeEvent event = data.event;
        final supa.Session? session = data.session;
        final supa.User? user = session?.user ?? client.auth.currentUser;

        debugPrint('[REXAM] Auth state changed: $event, user: ${user?.id}');

        if ((event == supa.AuthChangeEvent.signedIn || event == supa.AuthChangeEvent.userUpdated) && user != null) {
          final profileExists = await _repository.checkProfileExists(user.id);
          final userModel = UserModel(
            id: user.id,
            email: user.email ?? '',
            displayName: user.userMetadata?['full_name'] ??
                user.userMetadata?['name'] ??
                user.email?.split('@').first ??
                'Candidate',
            isEmailVerified: true,
            createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
          );

          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: userModel,
            hasCompletedOnboarding: profileExists,
            errorMessage: null,
          );
        } else if (event == supa.AuthChangeEvent.signedOut) {
          state = const AuthState(status: AuthStatus.unauthenticated);
        }
      }, onError: (error) {
        debugPrint('[REXAM] Auth state stream error: $error');
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: error.toString().replaceFirst('AuthException: ', '').replaceFirst('Exception: ', ''),
        );
      });
    } catch (e) {
      debugPrint('[REXAM] Notice setting up auth state listener: $e');
    }
  }

  Future<void> checkInitialSession() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        final profileExists = await _repository.checkProfileExists(user.id);
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          hasCompletedOnboarding: profileExists,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          hasCompletedOnboarding: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(hasCompletedOnboarding: true);
  }

  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.signInWithEmail(email, password);
      final profileExists = await _repository.checkProfileExists(user.id);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        hasCompletedOnboarding: profileExists,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, String fullName) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.signUpWithEmail(email, password, fullName);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        hasCompletedOnboarding: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.signInWithGoogle();
      if (user != null) {
        final profileExists = await _repository.checkProfileExists(user.id);
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          hasCompletedOnboarding: profileExists,
        );
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _repository.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
