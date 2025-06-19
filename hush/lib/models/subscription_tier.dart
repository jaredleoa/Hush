// lib/models/subscription_tier.dart
enum SubscriptionTier { free, basic, pro, premium }

extension SubscriptionTierExtension on SubscriptionTier {
  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.basic:
        return 'Hush Basic';
      case SubscriptionTier.pro:
        return 'Hush Pro';
      case SubscriptionTier.premium: // This should match the enum value
        return 'Hush Premium';
    }
  }

  String get description {
    switch (this) {
      case SubscriptionTier.free:
        return 'Basic household coordination';
      case SubscriptionTier.basic:
        return 'Unlimited members & smart scheduling';
      case SubscriptionTier.pro:
        return 'Advanced features & integrations';
      case SubscriptionTier.premium:
        return 'Complete household management suite';
    }
  }

  double get monthlyPrice {
    switch (this) {
      case SubscriptionTier.free:
        return 0.0;
      case SubscriptionTier.basic:
        return 2.99;
      case SubscriptionTier.pro:
        return 4.99;
      case SubscriptionTier.premium:
        return 7.99;
    }
  }

  int get maxHouseholdMembers {
    switch (this) {
      case SubscriptionTier.free:
        return 4;
      case SubscriptionTier.basic:
      case SubscriptionTier.pro:
      case SubscriptionTier.premium:
        return 999; // Unlimited
    }
  }

  List<String> get features {
    switch (this) {
      case SubscriptionTier.free:
        return [
          'Up to 4 household members',
          'Basic quiet time coordination',
          'Simple notifications',
          'Privacy controls',
        ];
      case SubscriptionTier.basic:
        return [
          'Unlimited household members',
          'Smart scheduling',
          'Enhanced notifications',
          'Weekly harmony reports',
          'Guest mode',
        ];
      case SubscriptionTier.pro:
        return [
          'All Basic features',
          'Advanced privacy controls',
          'Custom quiet reasons',
          'Household rules & agreements',
          'Conflict resolution tools',
          'Priority support',
        ];
      case SubscriptionTier.premium:
        return [
          'All Pro features',
          'Multi-household management',
          'Advanced analytics',
          'Smart home integrations',
          'White-label options',
          'API access',
        ];
    }
  }

  bool get hasSmartScheduling => this != SubscriptionTier.free;
  bool get hasAdvancedPrivacy =>
      this == SubscriptionTier.pro || this == SubscriptionTier.premium;
  bool get hasAnalytics => this == SubscriptionTier.premium;
  bool get hasMultiHousehold => this == SubscriptionTier.premium;
}

// lib/models/user_subscription.dart
class UserSubscription {
  final SubscriptionTier tier;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime? purchasedAt;
  final String? transactionId;

  UserSubscription({
    required this.tier,
    required this.isActive,
    this.expiresAt,
    this.purchasedAt,
    this.transactionId,
  });

  bool get isPremium => tier != SubscriptionTier.free;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory UserSubscription.free() {
    return UserSubscription(tier: SubscriptionTier.free, isActive: true);
  }

  UserSubscription copyWith({
    SubscriptionTier? tier,
    bool? isActive,
    DateTime? expiresAt,
    DateTime? purchasedAt,
    String? transactionId,
  }) {
    return UserSubscription(
      tier: tier ?? this.tier,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      transactionId: transactionId ?? this.transactionId,
    );
  }

  Map<String, dynamic> toJson() => {
    'tier': tier.index,
    'isActive': isActive,
    'expiresAt': expiresAt?.toIso8601String(),
    'purchasedAt': purchasedAt?.toIso8601String(),
    'transactionId': transactionId,
  };

  factory UserSubscription.fromJson(Map<String, dynamic> json) =>
      UserSubscription(
        tier: SubscriptionTier.values[json['tier'] ?? 0],
        isActive: json['isActive'] ?? false,
        expiresAt:
            json['expiresAt'] != null
                ? DateTime.parse(json['expiresAt'])
                : null,
        purchasedAt:
            json['purchasedAt'] != null
                ? DateTime.parse(json['purchasedAt'])
                : null,
        transactionId: json['transactionId'],
      );
}
