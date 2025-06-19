// lib/services/subscription_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
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
      // Initialize RevenueCat (you'll need to set up your API keys)
      await Purchases.setLogLevel(LogLevel.debug);

      // TODO: Replace with your actual RevenueCat API keys
      // Get these from https://app.revenuecat.com
      const apiKey = 'your_revenuecat_api_key_here';

      if (defaultTargetPlatform == TargetPlatform.android) {
        await Purchases.configure(PurchasesConfiguration(apiKey));
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        await Purchases.configure(PurchasesConfiguration(apiKey));
      }

      // Load subscription status from local storage
      await _loadSubscriptionFromStorage();

      // Check for any active subscriptions on the platform
      await _checkRemoteSubscription();

      _isInitialized = true;
    } catch (e) {
      print('Failed to initialize subscription service: $e');
      // Fall back to free tier
      _currentSubscription = UserSubscription.free();
    }

    notifyListeners();
  }

  // Load subscription from SharedPreferences
  Future<void> _loadSubscriptionFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subscriptionJson = prefs.getString('user_subscription');

      if (subscriptionJson != null) {
        // In a real app, you'd parse the JSON
        // For now, just check if they have a saved tier
        final tierIndex = prefs.getInt('subscription_tier') ?? 0;
        final isActive = prefs.getBool('subscription_active') ?? false;
        final expiresAtString = prefs.getString('subscription_expires');

        _currentSubscription = UserSubscription(
          tier: SubscriptionTier.values[tierIndex],
          isActive: isActive,
          expiresAt:
              expiresAtString != null ? DateTime.parse(expiresAtString) : null,
        );
      }
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

  // Check subscription status with RevenueCat
  Future<void> _checkRemoteSubscription() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();

      // Check if user has any active entitlements
      if (customerInfo.activeSubscriptions.isNotEmpty) {
        // Determine tier based on active subscription
        final activeSubscription = customerInfo.activeSubscriptions.first;
        SubscriptionTier tier = _mapProductIdToTier(activeSubscription);

        _currentSubscription = UserSubscription(
          tier: tier,
          isActive: true,
          expiresAt: customerInfo.latestExpirationDate != null 
              ? DateTime.parse(customerInfo.latestExpirationDate!)
              : null,
          purchasedAt: customerInfo.firstSeen != null 
              ? DateTime.parse(customerInfo.firstSeen!)
              : DateTime.now(),
        );

        await _saveSubscriptionToStorage();
      }
    } catch (e) {
      print('Error checking remote subscription: $e');
    }
  }

  // Map RevenueCat product IDs to subscription tiers
  SubscriptionTier _mapProductIdToTier(String productId) {
    switch (productId) {
      case 'hush_basic_monthly':
        return SubscriptionTier.basic;
      case 'hush_pro_monthly':
        return SubscriptionTier.pro;
      case 'hush_premium_monthly':
        return SubscriptionTier.premium;
      default:
        return SubscriptionTier.free;
    }
  }

  // Purchase a subscription
  Future<bool> purchaseSubscription(SubscriptionTier tier) async {
    if (!_isInitialized) await initialize();

    try {
      final productId = _getProductIdForTier(tier);
      if (productId == null) return false;

      final customerInfo = await Purchases.purchaseProduct(productId);

      if (customerInfo.activeSubscriptions.isNotEmpty) {
        _currentSubscription = UserSubscription(
          tier: tier,
          isActive: true,
          expiresAt: customerInfo.latestExpirationDate != null 
              ? DateTime.tryParse(customerInfo.latestExpirationDate!) ?? DateTime.now().add(const Duration(days: 30))
              : null,
          purchasedAt: DateTime.now(),
        );

        await _saveSubscriptionToStorage();
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Purchase failed: $e');
    }

    return false;
  }

  // Get product ID for subscription tier
  String? _getProductIdForTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.basic:
        return 'hush_basic_monthly';
      case SubscriptionTier.pro:
        return 'hush_pro_monthly';
      case SubscriptionTier.premium:
        return 'hush_premium_monthly';
      default:
        return null;
    }
  }

  // Restore purchases
  Future<void> restorePurchases() async {
    if (!_isInitialized) await initialize();

    try {
      final customerInfo = await Purchases.restorePurchases();
      await _checkRemoteSubscription();
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
  Future<void> simulatePurchase(SubscriptionTier tier) async {
    _currentSubscription = UserSubscription(
      tier: tier,
      isActive: true,
      expiresAt: DateTime.now().add(Duration(days: 30)),
      purchasedAt: DateTime.now(),
    );

    await _saveSubscriptionToStorage();
    notifyListeners();
  }

  // FOR TESTING: Reset to free tier
  Future<void> resetToFree() async {
    _currentSubscription = UserSubscription.free();
    await _saveSubscriptionToStorage();
    notifyListeners();
  }
}
