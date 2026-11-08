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

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;

  MockAuthRepository() {
    // Default demo user initialized for immediate interactive use
    _currentUser = UserModel(
      id: 'candidate-rexam-001',
      email: 'arjun.sharma@rexam.in',
      displayName: 'Arjun Sharma',
      isGuest: false,
      isEmailVerified: true,
      createdAt: DateTime(2026, 1, 15),
    );
  }

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (email.trim().isEmpty || password.length < 6) {
      throw Exception('Invalid email or password (minimum 6 characters required).');
    }
    _currentUser = UserModel(
      id: 'candidate-rexam-001',
      email: email.trim(),
      displayName: email.split('@').first.toUpperCase(),
      createdAt: DateTime.now(),
    );
    return _currentUser!;
  }

  @override
  Future<UserModel> signUpWithEmail(String email, String password, String fullName) async {
    await Future.delayed(const Duration(milliseconds: 350));
    if (email.trim().isEmpty || !email.contains('@')) {
      throw Exception('Please enter a valid email address.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }
    _currentUser = UserModel(
      id: 'candidate-new-${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim(),
      displayName: fullName.trim().isEmpty ? 'Candidate' : fullName.trim(),
      createdAt: DateTime.now(),
    );
    return _currentUser!;
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = UserModel(
      id: 'google-candidate-001',
      email: 'arjun.google@rexam.in',
      displayName: 'Arjun Sharma',
      isGuest: false,
      isEmailVerified: true,
      createdAt: DateTime(2026, 2, 1),
    );
    return _currentUser!;
  }

  @override
  Future<UserModel> signInAsGuest() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _currentUser = UserModel.guest();
    return _currentUser!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (email.trim().isEmpty || !email.contains('@')) {
      throw Exception('Please enter a valid email address for password reset.');
    }
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _currentUser = null;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }
}
