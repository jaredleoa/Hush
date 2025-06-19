// lib/widgets/subscription_status_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/subscription_service.dart';
import '../screens/paywall_screen.dart';
import '../models/subscription_tier.dart';

class SubscriptionStatusWidget extends StatelessWidget {
  const SubscriptionStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionService>(
      builder: (context, subscription, child) {
        if (subscription.isPremium) {
          return _buildPremiumStatus(context, subscription);
        } else {
          return _buildUpgradePrompt(context, subscription);
        }
      },
    );
  }

  Widget _buildPremiumStatus(
    BuildContext context,
    SubscriptionService subscription,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1).withOpacity(0.1),
            Color(0xFF8B5CF6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF6366F1).withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.star, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.currentTier.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Unlimited members & premium features',
                  style: TextStyle(
                    color: Color(0xFF6366F1).withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.green, size: 24),
        ],
      ),
    );
  }

  Widget _buildUpgradePrompt(
    BuildContext context,
    SubscriptionService subscription,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPaywall(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFA574).withOpacity(0.1),
                  Color(0xFFFF6B9D).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(0xFFFF6B9D).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFA574), Color(0xFFFF6B9D)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.rocket_launch,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upgrade to Premium',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B9D),
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Unlimited members • Smart scheduling • \$2.99/mo',
                        style: TextStyle(
                          color: Color(0xFFFF6B9D).withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFFF6B9D),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPaywall(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PaywallScreen()));
  }
}

class FeatureLockWidget extends StatelessWidget {
  final String featureName;
  final String description;
  final IconData icon;
  final VoidCallback onUpgrade;

  const FeatureLockWidget({
    Key? key,
    required this.featureName,
    required this.description,
    required this.icon,
    required this.onUpgrade,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          Text(
            featureName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Upgrade to Unlock',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
