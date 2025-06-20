// lib/screens/household_setup_screen.dart (Updated to match app design)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../models/subscription_tier.dart';
import '../services/auth_service.dart';
import 'privacy_onboarding_screen.dart';
import 'paywall_screen.dart';
import 'auth/login_screen.dart';
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

    final subscriptionService = Provider.of<SubscriptionService>(
      context,
      listen: false,
    );
    final authService = Provider.of<AuthService>(context, listen: false);

    // Check if user is authenticated
    if (!authService.isAuthenticated) {
      _showError('You must be signed in to join a household');
      return;
    }

    setState(() => _isJoining = true);

    try {
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
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PrivacyOnboardingScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isJoining = false);
        _showError('Failed to join household. Please try again.');
      }
    }
  }

  void _createHousehold() async {
    if (_householdNameController.text.isEmpty) {
      _showError('Please enter a household name');
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);

    // Check if user is authenticated
    if (!authService.isAuthenticated) {
      _showError('You must be signed in to create a household');
      return;
    }

    setState(() => _isCreating = true);

    try {
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
    } catch (e) {
      setState(() => _isCreating = false);
      _showError('Failed to create household. Please try again.');
    }
  }

  void _showMemberLimitDialog() {
    final subscriptionService = Provider.of<SubscriptionService>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
        builder: (_) => PaywallScreen(
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFFAFAFA)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24),
              
              Text(
                'Household Created!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Share this code with your housemates:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 28),
              
              // Code Display
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6366F1).withOpacity(0.1),
                      Color(0xFF4F46E5).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color(0xFF6366F1).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                    letterSpacing: 8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20),
              
              // Copy Button
              Container(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('Code copied to clipboard'),
                          ],
                        ),
                        backgroundColor: Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    Icons.copy,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                  label: Text(
                    'Copy Code',
                    style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              
              // Plan Info Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: subscriptionService.isPremium
                      ? Color(0xFF6366F1).withOpacity(0.1)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: subscriptionService.isPremium
                        ? Color(0xFF6366F1).withOpacity(0.2)
                        : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: subscriptionService.isPremium
                            ? Color(0xFF6366F1)
                            : Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        subscriptionService.isPremium
                            ? Icons.star
                            : Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subscriptionService.isPremium
                                ? 'Premium Plan Active'
                                : 'Free Plan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: subscriptionService.isPremium
                                  ? Color(0xFF6366F1)
                                  : Colors.grey[700],
                            ),
                          ),
                          Text(
                            subscriptionService.isPremium
                                ? 'Unlimited members & premium features'
                                : 'Up to ${subscriptionService.maxHouseholdMembers} members • Privacy-first design',
                            style: TextStyle(
                              fontSize: 14,
                              color: subscriptionService.isPremium
                                  ? Color(0xFF6366F1).withOpacity(0.8)
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 28),
              
              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrivacyOnboardingScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return PopupMenuButton(
                icon: Icon(Icons.more_vert, color: Color(0xFF6366F1)),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(Icons.logout, color: Colors.red, size: 20),
                      title: Text('Sign Out', style: TextStyle(fontSize: 14)),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onTap: () async {
                      // Small delay to allow popup to close
                      await Future.delayed(Duration(milliseconds: 100));
                      
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Sign Out?'),
                          content: Text('Are you sure you want to sign out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                'Sign Out',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        try {
                          await authService.signOut();
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => LoginScreen()),
                            (route) => false,
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error signing out. Please try again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              children: [
                SizedBox(height: 40),
                // App Icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
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
                    child: Icon(
                      Icons.nightlight_round,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Center(
                  child: Text(
                    'Set Up Your\nHousehold',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 12),
                Center(
                  child: Text(
                    'Create a household focused on respectful living',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 40),

                // Join Household Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
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
                            Expanded(
                              child: Text(
                                'Join Household',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
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
                        SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
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
                              contentPadding: EdgeInsets.all(20),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Z0-9]'),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isJoining ? null : _joinHousehold,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Color(0xFF6366F1),
                              padding: EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isJoining
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
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
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
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
                            Expanded(
                              child: Text(
                                'Create New',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
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
                        SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
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
                              contentPadding: EdgeInsets.all(20),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isCreating ? null : _createHousehold,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Color(0xFF10B981),
                              padding: EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isCreating
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF10B981),
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

                SizedBox(height: 30),

                // Privacy note with subscription info
                Consumer<SubscriptionService>(
                  builder: (context, subscription, child) {
                    return Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: subscription.isPremium
                            ? Color(0xFF6366F1).withOpacity(0.1)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: subscription.isPremium
                              ? Color(0xFF6366F1).withOpacity(0.2)
                              : Colors.grey[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: subscription.isPremium
                                  ? Color(0xFF6366F1)
                                  : Colors.grey[400],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              subscription.isPremium
                                  ? Icons.star
                                  : Icons.privacy_tip_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subscription.isPremium
                                      ? subscription.currentTier.displayName
                                      : 'Free Plan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: subscription.isPremium
                                        ? Color(0xFF6366F1)
                                        : Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  subscription.isPremium
                                      ? 'Unlimited members & premium features'
                                      : 'Up to ${subscription.currentTier.maxHouseholdMembers} members • Privacy-first design',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: subscription.isPremium
                                        ? Color(0xFF6366F1).withOpacity(0.8)
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}