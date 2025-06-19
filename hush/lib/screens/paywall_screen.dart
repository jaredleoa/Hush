// lib/screens/paywall_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription_tier.dart';
import '../services/subscription_service.dart';

class PaywallScreen extends StatefulWidget {
  final String? feature; // Which feature triggered the paywall
  final VoidCallback? onUpgraded;

  const PaywallScreen({Key? key, this.feature, this.onUpgraded})
    : super(key: key);

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  SubscriptionTier selectedTier = SubscriptionTier.basic;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildContent()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                'Upgrade Hush',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 48), // Balance the close button
            ],
          ),
          SizedBox(height: 20),
          Icon(Icons.volume_off_rounded, size: 60, color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Unlock Premium Features',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            widget.feature != null
                ? 'Upgrade to access ${_getFeatureName(widget.feature!)}'
                : 'Get the most out of your household coordination',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSubscriptionOptions(),
          SizedBox(height: 30),
          _buildFeatureComparison(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionOptions() {
    return Column(
      children:
          SubscriptionTier.values
              .where((tier) => tier != SubscriptionTier.free)
              .map((tier) => _buildSubscriptionTile(tier))
              .toList(),
    );
  }

  Widget _buildSubscriptionTile(SubscriptionTier tier) {
    final isSelected = selectedTier == tier;
    final isRecommended = tier == SubscriptionTier.basic;

    return GestureDetector(
      onTap: () => setState(() => selectedTier = tier),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF6366F1).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Color(0xFF6366F1) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            tier.displayName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          if (isRecommended) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'POPULAR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        tier.description,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${tier.monthlyPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    Text(
                      'per month',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            ...tier.features
                .take(3)
                .map(
                  (feature) => Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              color: Color(0xFF374151),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            if (tier.features.length > 3) ...[
              SizedBox(height: 8),
              Text(
                '+ ${tier.features.length - 3} more features',
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureComparison() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why upgrade?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 16),
          _buildComparisonRow('Unlimited household members', true),
          _buildComparisonRow('Smart scheduling & automation', true),
          _buildComparisonRow(
            'Advanced privacy controls',
            selectedTier.hasAdvancedPrivacy,
          ),
          _buildComparisonRow(
            'Household harmony analytics',
            selectedTier.hasAnalytics,
          ),
          _buildComparisonRow(
            'Priority customer support',
            selectedTier != SubscriptionTier.basic,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String feature, bool included) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            included ? Icons.check_circle : Icons.cancel,
            color: included ? Colors.green : Colors.grey,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                color: included ? Color(0xFF374151) : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handlePurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  isLoading
                      ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Text(
                        'Start ${selectedTier.displayName} - \$${selectedTier.monthlyPrice.toStringAsFixed(2)}/month',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
          SizedBox(height: 12),
          TextButton(
            onPressed: isLoading ? null : _handleRestore,
            child: Text(
              'Restore Purchases',
              style: TextStyle(color: Color(0xFF6366F1), fontSize: 14),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Cancel anytime. Terms and Privacy Policy apply.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchase() async {
    setState(() => isLoading = true);

    try {
      final subscriptionService = Provider.of<SubscriptionService>(
        context,
        listen: false,
      );

      // Use the simulate purchase method since we don't have real payments yet
      final success = await subscriptionService.simulatePurchase(selectedTier);

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully upgraded to ${selectedTier.displayName}!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        widget.onUpgraded?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleRestore() async {
    setState(() => isLoading = true);

    try {
      final subscriptionService = Provider.of<SubscriptionService>(
        context,
        listen: false,
      );
      await subscriptionService.restorePurchases();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchases restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No purchases found to restore.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _getFeatureName(String feature) {
    switch (feature) {
      case 'unlimited_members':
        return 'unlimited household members';
      case 'smart_scheduling':
        return 'smart scheduling';
      case 'advanced_privacy':
        return 'advanced privacy controls';
      case 'analytics':
        return 'household analytics';
      default:
        return 'premium features';
    }
  }
}
