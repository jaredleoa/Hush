// lib/screens/home_screen.dart (Updated imports section)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/quiet_time_toggle_button.dart';
import '../services/subscription_service.dart';
import 'paywall_screen.dart';
import '../models/privacy_settings.dart';
import '../models/user_status.dart';
import '../models/quiet_reason.dart';
import '../models/sharing_mode.dart';
import '../services/notification_service.dart';
import '../models/subscription_tier.dart';
import 'privacy_settings_screen.dart';
import 'household_setup_screen.dart';
import '../widgets/quiet_request_button.dart';
import '../widgets/too_loud_button.dart';

class HushHomePage extends StatefulWidget {
  @override
  _HushHomePageState createState() => _HushHomePageState();
}

class _HushHomePageState extends State<HushHomePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  bool _isQuietTime = false;
  QuietReason? _currentQuietReason;
  String _householdName = 'My Household';
  PrivacySettings _privacySettings = PrivacySettings();
  SharingMode _sharingMode = SharingMode.named;

  // Enhanced sample data with new features
  final List<UserStatus> _housemates = [
    UserStatus(name: 'You', isQuietTime: false, sharingMode: SharingMode.named),
    UserStatus(
      name: 'Alex',
      isQuietTime: true,
      quietReason: QuietReason.sleeping,
      sharingMode: SharingMode.named,
      generalActivity: 'resting',
      quietStartTime: DateTime.now().subtract(Duration(hours: 1)),
    ),
    UserStatus(
      name: 'Jordan',
      isQuietTime: false,
      sharingMode: SharingMode.anonymous,
      isHome: false,
      generalActivity: 'away',
    ),
    UserStatus(
      name: 'Sam',
      isQuietTime: true,
      quietReason: QuietReason.working,
      sharingMode: SharingMode.anonymous,
      quietStartTime: DateTime.now().subtract(Duration(minutes: 30)),
    ),
    UserStatus(
      name: 'Riley',
      isQuietTime: false,
      sharingMode: SharingMode.invisible,
      shareDetails: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Update notification service about app state
    NotificationService().setAppState(state != AppLifecycleState.resumed);
  }

  // Helper method to get available (non-quiet, at-home) housemates
  List<UserStatus> get _availableHousemates {
    return _housemates
        .where(
          (housemate) =>
              housemate.name != 'You' && // Exclude the current user
              !housemate.isQuietTime && // Not in quiet time
              housemate.isHome && // Currently at home
              housemate.sharingMode != SharingMode.invisible, // Not invisible
        )
        .toList();
  }

  // Helper method to get quiet housemates
  List<UserStatus> get _quietHousemates {
    return _housemates
        .where(
          (housemate) =>
              housemate.isQuietTime &&
              housemate.isHome &&
              housemate.sharingMode != SharingMode.invisible,
        )
        .toList();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _householdName = prefs.getString('householdName') ?? 'My Household';
      _isQuietTime = prefs.getBool('isQuietTime') ?? false;
      _currentQuietReason =
          _isQuietTime
              ? QuietReason.values[prefs.getInt('quietReason') ?? 0]
              : null;
      _sharingMode = SharingMode.values[prefs.getInt('sharingMode') ?? 0];
      _privacySettings = PrivacySettings(
        shareDetailedStatus: prefs.getBool('shareDetailedStatus') ?? false,
        shareLocation: prefs.getBool('shareLocation') ?? false,
        shareActiveHours: prefs.getBool('shareActiveHours') ?? true,
        allowQuietHours: prefs.getBool('allowQuietHours') ?? true,
      );

      // Update the "You" entry in housemates with loaded settings
      final youIndex = _housemates.indexWhere((h) => h.name == 'You');
      if (youIndex != -1) {
        _housemates[youIndex] = _housemates[youIndex].copyWith(
          isQuietTime: _isQuietTime,
          quietReason: _currentQuietReason,
          sharingMode: _sharingMode,
          quietStartTime: _isQuietTime ? DateTime.now() : null,
        );
      }

      // Handle breathing animation after loading settings

    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isQuietTime', _isQuietTime);
    if (_currentQuietReason != null) {
       await prefs.setInt('quietReason', _currentQuietReason?.index ?? 0);
    }
    await prefs.setInt('sharingMode', _sharingMode.index);
  }

  void _toggleQuietTime() {
    setState(() {
      _isQuietTime = !_isQuietTime;
      if (!_isQuietTime) {
        _currentQuietReason = null;
      }

      // Update the "You" entry in housemates
      final youIndex = _housemates.indexWhere((h) => h.name == 'You');
      if (youIndex != -1) {
        _housemates[youIndex] = _housemates[youIndex].copyWith(
          isQuietTime: _isQuietTime,
          quietReason: _currentQuietReason,
          quietStartTime: _isQuietTime ? DateTime.now() : null,
        );
      }
    });

    _saveSettings();
    HapticFeedback.lightImpact();

    // Send notifications to other housemates if app is in background
    if (_isQuietTime) {
      final quietHousemates = _housemates.where((h) => h.isQuietTime).toList();
      NotificationService().sendQuietTimeNotification(quietHousemates);
    }
  }

  void _onQuietReasonSelected(QuietReason reason) {
    setState(() {
      _currentQuietReason = reason;
      _isQuietTime = true;

      // Update the "You" entry in housemates
      final youIndex = _housemates.indexWhere((h) => h.name == 'You');
      if (youIndex != -1) {
        _housemates[youIndex] = _housemates[youIndex].copyWith(
          isQuietTime: true,
          quietReason: reason,
          quietStartTime: DateTime.now(),
        );
      }

      // Start breathing animation

    });

    _saveSettings();
    HapticFeedback.lightImpact();

    // Send notifications
    final quietHousemates = _housemates.where((h) => h.isQuietTime).toList();
    NotificationService().sendQuietTimeNotification(quietHousemates);
  }

  void _showQuietReasonDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder:
          (context) => AlertDialog(
            backgroundColor:
                _isQuietTime ? Color(0xFF6366F1) : Color(0xFF10B981),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Select Quiet Reason',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  QuietReason.values.map((reason) {
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          reason.displayName,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _onQuietReasonSelected(reason);
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [_buildHeader(), _buildHousematesList()]),
    );
  }

  Widget _buildHeader() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              _isQuietTime
                  ? [Color(0xFF6366F1), Color(0xFF4F46E5)]
                  : [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: (_isQuietTime ? Color(0xFF6366F1) : Color(0xFF10B981))
                .withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 50),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _householdName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.white, size: 28),
                    onPressed: () => _showSettingsMenu(),
                  ),
                ],
              ),
              SizedBox(height: 30),

              Text(
                'Household Status',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 30),

              QuietTimeToggleButton(
                isQuietTime: _isQuietTime,
                onTap: _toggleQuietTime,
                onLongPress: _showQuietReasonDialog,
              ),
              SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  QuietRequestButton(
                    onRequestSent: () {
                      // Optional: Could show analytics about requests sent
                    },
                  ),

                  SizedBox(width: 16),

                  if (_availableHousemates.isNotEmpty)
                    TooLoudButton(
                      onRequestSent: () {
                        // Optional: Could track noise complaints for household harmony
                      },
                    ),
                ],
              ),

              SizedBox(height: 15),

              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        _sharingMode == SharingMode.invisible
                            ? (_isQuietTime
                                ? [
                                  Color(0xFF6366F1),
                                  Color(0xFF8B5CF6),
                                ] // Purple when quiet + invisible
                                : [
                                  Color(0xFF34D399),
                                  Color(0xFF059669),
                                ]) // Green when available + invisible
                            : [
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.1),
                            ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: (_sharingMode == SharingMode.invisible
                              ? (_isQuietTime
                                  ? Color(0xFF6366F1)
                                  : Color(0xFF10B981))
                              : Colors.white)
                          .withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        // Toggle between invisible and named sharing mode
                        _sharingMode = _sharingMode == SharingMode.invisible
                            ? SharingMode.named
                            : SharingMode.invisible;
                        
                        // Update the "You" entry in housemates with new sharing mode
                        final youIndex = _housemates.indexWhere(
                          (h) => h.name == 'You',
                        );
                        if (youIndex != -1) {
                          _housemates[youIndex] = _housemates[youIndex]
                              .copyWith(sharingMode: _sharingMode);
                        }
                        
                        // Save settings after all changes are made
                        _saveSettings();
                      });
                      HapticFeedback.mediumImpact();
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _sharingMode == SharingMode.invisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 24,
                            color:
                                _sharingMode == SharingMode.invisible
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.9),
                          ),
                          SizedBox(width: 12),
                          AnimatedDefaultTextStyle(
                            duration: Duration(milliseconds: 300),
                            style: TextStyle(
                              color:
                                  _sharingMode == SharingMode.invisible
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            child: Text(
                              _sharingMode == SharingMode.invisible
                                  ? 'Go Visible'
                                  : 'Go Invisible',
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildHousematesList() {
    // Only show housemates who are not in invisible mode
    final visibleHousemates =
        _housemates
            .where((h) => h.sharingMode != SharingMode.invisible)
            .toList();
    final hiddenCount = _housemates.length - visibleHousemates.length;

    return Expanded(
      child: Column(
        children: [
          // NEW: Noise management status section
          if (_quietHousemates.isNotEmpty || _availableHousemates.isEmpty)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE3F2FD), Color(0xFFE8F5E9)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFF2196F3), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFFBBDEFB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.volume_down,
                      color: Color(0xFF2196F3),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _quietHousemates.length == 1
                              ? 'Someone needs quiet'
                              : '${_quietHousemates.length} people need quiet',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF90CAF9),
                            fontSize: 14,
                          ),
                        ),
                        if (_availableHousemates.isEmpty) ...[
                          SizedBox(height: 4),
                          Text(
                            'No one available for noise notifications right now',
                            style: TextStyle(
                              color: Color(0xFF1976D2), // Using hex value instead of Colors.blue[600] to avoid null safety issues
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.info_outline, color: Color(0xFF1976D2), size: 18),
                ],
              ),
            ),

          if (hiddenCount > 0) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF6366F1).withOpacity(0.1),
                      Color(0xFF8B5CF6).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color(0xFF6366F1).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF6366F1).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.visibility_off,
                        size: 18,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$hiddenCount housemate${hiddenCount > 1 ? 's' : ''} in private mode',
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: visibleHousemates.length,
              itemBuilder: (context, index) {
                final person = visibleHousemates[index];
                return _buildHousemateTile(person);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHousemateTile(UserStatus person) {
    final needsQuiet = person.isQuietTime;
    final isAway = !person.isHome && _privacySettings.shareLocation;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color:
              needsQuiet
                  ? Color(0xFF6366F1).withOpacity(0.1)
                  : Color(0xFF10B981).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Enhanced avatar with subtle pulse animation for quiet users
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors:
                    needsQuiet
                        ? [Color(0xFF6366F1), Color(0xFF4F46E5)]
                        : isAway
                        ? [Color(0xFF6B7280), Color(0xFF4B5563)]
                        : [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (needsQuiet
                          ? Color(0xFF6366F1)
                          : isAway
                          ? Color(0xFF6B7280)
                          : Color(0xFF10B981))
                      .withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              needsQuiet
                  ? Icons.volume_off_rounded
                  : isAway
                  ? Icons.location_off_rounded
                  : Icons.volume_up_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      person.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Color(0xFF1F2937),
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (isAway) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF6B7280).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(0xFF6B7280).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Away',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 6),
                if (needsQuiet)
                  Text(
                    person.quietReason?.displayName ?? 'Needs quiet time',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (_privacySettings.shareActiveHours &&
                    person.generalActivity != null &&
                    !needsQuiet) ...[
                  Text(
                    'Currently: ${person.generalActivity}',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Enhanced status badge
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    needsQuiet
                        ? [
                          Color(0xFF6366F1).withOpacity(0.15),
                          Color(0xFF4F46E5).withOpacity(0.1),
                        ]
                        : isAway
                        ? [
                          Color(0xFF6B7280).withOpacity(0.15),
                          Color(0xFF4B5563).withOpacity(0.1),
                        ]
                        : [
                          Color(0xFF10B981).withOpacity(0.15),
                          Color(0xFF059669).withOpacity(0.1),
                        ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    needsQuiet
                        ? Color(0xFF6366F1).withOpacity(0.2)
                        : isAway
                        ? Color(0xFF6B7280).withOpacity(0.2)
                        : Color(0xFF10B981).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              needsQuiet
                  ? 'Quiet'
                  : isAway
                  ? 'Away'
                  : 'Available',
              style: TextStyle(
                color:
                    needsQuiet
                        ? Color(0xFF4F46E5)
                        : isAway
                        ? Color(0xFF4B5563)
                        : Color(0xFF059669),
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Subscription Management
                Consumer<SubscriptionService>(
                  builder: (context, subscription, child) {
                    return ListTile(
                      leading: Icon(
                        subscription.isPremium ? Icons.star : Icons.star_border,
                        color: subscription.isPremium ? Colors.amber : null,
                      ),
                      title: Text(
                        subscription.isPremium
                            ? 'Manage Subscription'
                            : 'Upgrade to Premium',
                      ),
                      subtitle: Text(
                        subscription.isPremium
                            ? subscription.currentTier.displayName
                            : 'Unlock unlimited members & more',
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PaywallScreen()),
                        );
                      },
                    );
                  },
                ),
                Divider(),
                // Privacy Settings
                ListTile(
                  leading: Icon(Icons.privacy_tip),
                  title: Text('Privacy Settings'),
                  subtitle: Text('Control what you share'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrivacySettingsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.vpn_key),
                  title: Text('Invite Code'),
                  subtitle: FutureBuilder<String>(
                    future: SharedPreferences.getInstance().then(
                      (prefs) => prefs.getString('inviteCode') ?? 'N/A',
                    ),
                    builder:
                        (context, snapshot) =>
                            Text(snapshot.data ?? 'Loading...'),
                  ),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final code = prefs.getString('inviteCode') ?? '';
                    await Clipboard.setData(ClipboardData(text: code));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invite code copied!')),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About Hush'),
                  subtitle: Text('Privacy-first household coordination'),
                  onTap: () => _showAboutDialog(),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.exit_to_app, color: Colors.red),
                  title: Text(
                    'Leave Household',
                    style: TextStyle(color: Colors.red),
                  ),
                  subtitle: Text('Reset and return to setup'),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text('Leave Household?'),
                            content: Text(
                              'This will clear all your data and return you to setup.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  'Leave',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                    );

                    if (confirmed == true) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HouseholdSetupScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.volume_off_rounded, color: Color(0xFF6366F1)),
                SizedBox(width: 8),
                Text('About Hush'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hush helps housemates coordinate quiet times respectfully.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'Privacy Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '• Minimal data sharing by default\n'
                  '• "Invisible mode" for complete privacy\n'
                  '• No tracking of specific activities\n'
                  '• You control all sharing settings\n'
                  '• Data stays within your household',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Got it'),
              ),
            ],
          ),
    );
  }
}
