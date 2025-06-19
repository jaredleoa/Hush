// lib/services/subscription_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription_tier.dart';

class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  UserSubscription _currentSubscription = UserSubscription.free();
  bool _isInitialized = false;

  UserSubscription get currentSubscription => _currentSubscription;
  bool get isPremium => _currentSubscription.isPremium;
  SubscriptionTier get currentTier => _currentSubscription.tier;

  // Initialize the subscription service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load subscription status from local storage only
      await _loadSubscriptionFromStorage();
      _isInitialized = true;
    } catch (e) {
      print('Failed to initialize subscription service: $e');
      _currentSubscription = UserSubscription.free();
    }

    notifyListeners();
  }

  // Load subscription from SharedPreferences
  Future<void> _loadSubscriptionFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tierIndex = prefs.getInt('subscription_tier') ?? 0;
      final isActive = prefs.getBool('subscription_active') ?? false;
      final expiresAtString = prefs.getString('subscription_expires');

      _currentSubscription = UserSubscription(
        tier: SubscriptionTier.values[tierIndex],
        isActive: isActive,
        expiresAt:
            expiresAtString != null ? DateTime.parse(expiresAtString) : null,
      );
    } catch (e) {
      print('Error loading subscription from storage: $e');
    }
  }

  // Save subscription to SharedPreferences
  Future<void> _saveSubscriptionToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('subscription_tier', _currentSubscription.tier.index);
      await prefs.setBool('subscription_active', _currentSubscription.isActive);

      if (_currentSubscription.expiresAt != null) {
        await prefs.setString(
          'subscription_expires',
          _currentSubscription.expiresAt!.toIso8601String(),
        );
      }
    } catch (e) {
      print('Error saving subscription to storage: $e');
    }
  }

  // Purchase a subscription (mock implementation)
  Future<bool> purchaseSubscription(SubscriptionTier tier) async {
    if (!_isInitialized) await initialize();

    // For now, just simulate the purchase
    return await simulatePurchase(tier);
  }

  // Restore purchases (mock implementation)
  Future<void> restorePurchases() async {
    if (!_isInitialized) await initialize();

    try {
      await _loadSubscriptionFromStorage();
      notifyListeners();
    } catch (e) {
      print('Restore failed: $e');
    }
  }

  // Check if user can access premium features
  bool canAccessFeature(String feature) {
    switch (feature) {
      case 'unlimited_members':
        return _currentSubscription.tier.maxHouseholdMembers > 4;
      case 'smart_scheduling':
        return _currentSubscription.tier.hasSmartScheduling;
      case 'advanced_privacy':
        return _currentSubscription.tier.hasAdvancedPrivacy;
      case 'analytics':
        return _currentSubscription.tier.hasAnalytics;
      case 'multi_household':
        return _currentSubscription.tier.hasMultiHousehold;
      default:
        return true; // Free features
    }
  }

  // Get household member limit
  int get maxHouseholdMembers => _currentSubscription.tier.maxHouseholdMembers;

  // FOR TESTING: Simulate subscription purchase
  Future<bool> simulatePurchase(SubscriptionTier tier) async {
    _currentSubscription = UserSubscription(
      tier: tier,
      isActive: true,
      expiresAt: DateTime.now().add(Duration(days: 30)),
      purchasedAt: DateTime.now(),
    );

    await _saveSubscriptionToStorage();
    notifyListeners();
    return true;
  }

  // FOR TESTING: Reset to free tier
  Future<void> resetToFree() async {
    _currentSubscription = UserSubscription.free();
    await _saveSubscriptionToStorage();
    notifyListeners();
  }
}
