// lib/screens/household_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../models/subscription_tier.dart';
import 'privacy_onboarding_screen.dart';
import 'paywall_screen.dart';
import '../services/subscription_service.dart';

class HouseholdSetupScreen extends StatefulWidget {
  @override
  _HouseholdSetupScreenState createState() => _HouseholdSetupScreenState();
}

class _HouseholdSetupScreenState extends State<HouseholdSetupScreen> {
  final _joinCodeController = TextEditingController();
  final _householdNameController = TextEditingController();
  bool _isCreating = false;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    // Initialize subscription service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubscriptionService>(context, listen: false).initialize();
    });
  }

  @override
  void dispose() {
    _joinCodeController.dispose();
    _householdNameController.dispose();
    super.dispose();
  }

  void _joinHousehold() async {
    if (_joinCodeController.text.length != 6) {
      _showError('Please enter a 6-character code');
      return;
    }

    // Check if user can join (member limit check would happen on backend)
    final subscriptionService = Provider.of<SubscriptionService>(
      context,
      listen: false,
    );

    setState(() => _isJoining = true);

    // Simulate checking if household is full
    await Future.delayed(Duration(seconds: 1));

    // Mock: Simulate household with 4 members (free tier limit)
    final householdMemberCount = 4; // This would come from your backend

    if (householdMemberCount >= subscriptionService.maxHouseholdMembers) {
      setState(() => _isJoining = false);
      _showMemberLimitDialog();
      return;
    }

    await Future.delayed(Duration(seconds: 1)); // Simulate API call

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasHousehold', true);
    await prefs.setString('householdName', 'The Apartment');
    await prefs.setString('householdId', 'generated-id');
    await prefs.setString('inviteCode', _joinCodeController.text);

    setState(() => _isJoining = false);

    // Show privacy onboarding before entering main app
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PrivacyOnboardingScreen()),
    );
  }

  void _createHousehold() async {
    if (_householdNameController.text.isEmpty) {
      _showError('Please enter a household name');
      return;
    }

    setState(() => _isCreating = true);
    await Future.delayed(Duration(seconds: 2));

    final inviteCode = _generateInviteCode();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasHousehold', true);
    await prefs.setString('householdName', _householdNameController.text);
    await prefs.setString('householdId', 'generated-id');
    await prefs.setString('inviteCode', inviteCode);
    await prefs.setBool('isHouseholdCreator', true);

    setState(() => _isCreating = false);
    _showInviteCode(inviteCode);
  }

  void _showMemberLimitDialog() {
    final subscriptionService = Provider.of<SubscriptionService>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.group_off, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Household Full',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This household has reached the ${subscriptionService.maxHouseholdMembers} member limit for free accounts.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.blue[700], size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Upgrade to Hush Basic',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Unlimited household members\n• Smart scheduling\n• Enhanced notifications\n• Only \$2.99/month',
                        style: TextStyle(color: Colors.blue[700], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Maybe Later'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showPaywall('unlimited_members');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
                child: Text('Upgrade Now'),
              ),
            ],
          ),
    );
  }

  void _showPaywall(String feature) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PaywallScreen(
              feature: feature,
              onUpgraded: () {
                // Retry joining after upgrade
                _joinHousehold();
              },
            ),
      ),
    );
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    for (int i = 0; i < 6; i++) {
      final index = (random * (i + 1)) % chars.length;
      code += chars[index.toInt()];
    }
    return code;
  }

  void _showInviteCode(String code) {
    final subscriptionService = Provider.of<SubscriptionService>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text('Household Created!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Share this code with your housemates:'),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                      letterSpacing: 8,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Code copied to clipboard'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: Icon(Icons.copy),
                  label: Text('Copy Code'),
                ),
                SizedBox(height: 16),
                // Show member limit info
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        subscriptionService.isPremium
                            ? Colors.green[50]
                            : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          subscriptionService.isPremium
                              ? Colors.green[200]!
                              : Colors.orange[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        subscriptionService.isPremium
                            ? Icons.check_circle
                            : Icons.info,
                        color:
                            subscriptionService.isPremium
                                ? Colors.green[700]
                                : Colors.orange[700],
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subscriptionService.isPremium
                              ? 'Unlimited members with your premium plan!'
                              : 'Free plan: Up to ${subscriptionService.maxHouseholdMembers} members',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                subscriptionService.isPremium
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PrivacyOnboardingScreen(),
                    ),
                  );
                },
                child: Text('Continue'),
              ),
            ],
          ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                Text(
                  'Set Up Your\nHousehold',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Create a household focused on respectful living',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 40),

                // Join Household Card
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.people,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              'Join Household',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Enter the 6-character invite code',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: TextField(
                            controller: _joinCodeController,
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 6,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                            ),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: 'XXXXXX',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                              ),
                              border: InputBorder.none,
                              counterText: '',
                              contentPadding: EdgeInsets.all(16),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Z0-9]'),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isJoining ? null : _joinHousehold,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Color(0xFF6366F1),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child:
                                _isJoining
                                    ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF6366F1),
                                            ),
                                      ),
                                    )
                                    : Text(
                                      'Join Household',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 30),

                // OR divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),

                SizedBox(height: 30),

                // Create Household Card
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFA574), Color(0xFFFF6B9D)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFF6B9D).withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.add_home,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              'Create New',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Start your own household',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: TextField(
                            controller: _householdNameController,
                            style: TextStyle(color: Colors.white, fontSize: 18),
                            decoration: InputDecoration(
                              hintText: 'e.g., The Apartment',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 18,
                              ),
                              prefixIcon: Icon(
                                Icons.home,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isCreating ? null : _createHousehold,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Color(0xFFFF6B9D),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child:
                                _isCreating
                                    ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFFFF6B9D),
                                            ),
                                      ),
                                    )
                                    : Text(
                                      'Create Household',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Privacy note with subscription info
                Consumer<SubscriptionService>(
                  builder: (context, subscription, child) {
                    return Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            subscription.isPremium
                                ? Colors.purple[50]
                                : Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            subscription.isPremium
                                ? Icons.star
                                : Icons.privacy_tip_outlined,
                            color:
                                subscription.isPremium
                                    ? Colors.purple[700]
                                    : Colors.green[700],
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              subscription.isPremium
                                  ? '${subscription.currentTier.displayName} - Unlimited members & premium features'
                                  : 'Free plan: Up to ${subscription.currentTier.maxHouseholdMembers} members. Privacy-first design.',
                              style: TextStyle(
                                color:
                                    subscription.isPremium
                                        ? Colors.purple[700]
                                        : Colors.green[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
