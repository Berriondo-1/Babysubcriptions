enum AppAuthProvider { email, google, apple, github }

class AppUser {
  final int? id;
  final String email;
  final String? displayName;
  final AppAuthProvider provider;
  final String? passwordHash;
  final DateTime createdAt;

  const AppUser({
    this.id,
    required this.email,
    this.displayName,
    required this.provider,
    this.passwordHash,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'provider': provider.name,
      'password_hash': passwordHash,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int?,
      email: map['email'] as String,
      displayName: map['display_name'] as String?,
      provider: AppAuthProvider.values.firstWhere(
        (p) => p.name == map['provider'],
        orElse: () => AppAuthProvider.email,
      ),
      passwordHash: map['password_hash'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  AppUser copyWith({
    int? id,
    String? email,
    String? displayName,
    AppAuthProvider? provider,
    String? passwordHash,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      provider: provider ?? this.provider,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
