class Profile {
  final String id;
  final String? username;
  final String email;
  final String? householdId;
  final bool? isSleeping;
  final bool? isHome;
  final DateTime? updatedAt;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.email,
    this.username,
    this.householdId,
    this.isSleeping = false,
    this.isHome = true,
    this.updatedAt,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      householdId: json['household_id'] as String?,
      isSleeping: json['is_sleeping'] as bool?,
      isHome: json['is_home'] as bool?,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'household_id': householdId,
      'is_sleeping': isSleeping,
      'is_home': isHome,
      'updated_at': updatedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Profile copyWith({
    String? id,
    String? email,
    String? username,
    String? householdId,
    bool? isSleeping,
    bool? isHome,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      householdId: householdId ?? this.householdId,
      isSleeping: isSleeping ?? this.isSleeping,
      isHome: isHome ?? this.isHome,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
