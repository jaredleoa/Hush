class HouseholdMember {
  final String id;
  final String householdId;
  final String userId;
  final bool isAtHome;
  final bool isSleeping;
  final DateTime updatedAt;

  HouseholdMember({
    required this.id,
    required this.householdId,
    required this.userId,
    this.isAtHome = true,
    this.isSleeping = false,
    required this.updatedAt,
  });

  factory HouseholdMember.fromJson(Map<String, dynamic> json) {
    return HouseholdMember(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      userId: json['user_id'] as String,
      isAtHome: json['is_at_home'] as bool? ?? true,
      isSleeping: json['is_sleeping'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'household_id': householdId,
      'user_id': userId,
      'is_at_home': isAtHome,
      'is_sleeping': isSleeping,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  HouseholdMember copyWith({
    String? id,
    String? householdId,
    String? userId,
    bool? isAtHome,
    bool? isSleeping,
    DateTime? updatedAt,
  }) {
    return HouseholdMember(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      userId: userId ?? this.userId,
      isAtHome: isAtHome ?? this.isAtHome,
      isSleeping: isSleeping ?? this.isSleeping,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
