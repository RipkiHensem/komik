/// Model User yang disesuaikan dengan Supabase Auth + profiles table
class User {
  final String id;
  final String username;
  final String email;
  final DateTime createdAt;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
    this.avatarUrl,
  });

  /// Buat dari Supabase user + profile data yang digabung
  factory User.fromSupabase({
    required String id,
    required String email,
    String? username,
    String? avatarUrl,
    dynamic createdAt,
  }) {
    DateTime parsedDate;
    if (createdAt is DateTime) {
      parsedDate = createdAt;
    } else if (createdAt is String) {
      parsedDate = DateTime.tryParse(createdAt) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }
    return User(
      id: id,
      username: username ?? email.split('@').first,
      email: email,
      createdAt: parsedDate,
      avatarUrl: avatarUrl,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String? ?? json['email']?.toString().split('@').first ?? '',
      email: json['email'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'avatar_url': avatarUrl,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    DateTime? createdAt,
    String? avatarUrl,
    bool clearAvatar = false,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
    );
  }
}
