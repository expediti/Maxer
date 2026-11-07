class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final bool isGuest;
  final bool isEmailVerified;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.isGuest = false,
    this.isEmailVerified = true,
    required this.createdAt,
  });

  static UserModel guest() {
    return UserModel(
      id: 'guest-candidate-id',
      email: 'guest@rexam.app',
      displayName: 'Guest Candidate',
      isGuest: true,
      isEmailVerified: false,
      createdAt: DateTime.now(),
    );
  }
}
