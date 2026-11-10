class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final bool isEmailVerified;
  final DateTime createdAt;

  bool get isGuest => false;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.isEmailVerified = true,
    required this.createdAt,
  });
}
