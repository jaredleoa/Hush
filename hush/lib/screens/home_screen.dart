import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/privacy_settings.dart';
import '../models/user_status.dart';
import '../models/quiet_reason.dart';
import '../models/sharing_mode.dart';
import '../services/notification_service.dart';
import 'privacy_settings_screen.dart';
import 'household_setup_screen.dart';

class HushHomePage extends StatefulWidget {
  @override
  _HushHomePageState createState() => _HushHomePageState();
}

class _HushHomePageState extends State<HushHomePage> with WidgetsBindingObserver {
  bool _isQuietTime = false;
  QuietReason? _currentQuietReason;
  String _householdName = 'Loading...';
  PrivacySettings _privacySettings = PrivacySettings();
  SharingMode _sharingMode = SharingMode.named;

  // Enhanced sample data with new features
  final List<UserStatus> _housemates = [
    UserStatus(
      name: 'You', 
      isQuietTime: false,
      sharingMode: SharingMode.named,
    ),
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

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _householdName = prefs.getString('householdName') ?? 'My Household';
      _isQuietTime = prefs.getBool('isQuietTime') ?? false;
      _currentQuietReason = _isQuietTime 
        ? QuietReason.values[prefs.getInt('quietReason') ?? 0]
        : null;
      _sharingMode = SharingMode.values[prefs.getInt('sharingMode') ?? 0];
      _privacySettings = PrivacySettings(
        shareDetailedStatus: prefs.getBool('shareDetailedStatus') ?? false,
        shareLocation: prefs.getBool('shareLocation') ?? false,
        shareActiveHours: prefs.getBool('shareActiveHours') ?? true,
        allowQuietHours: prefs.getBool('allowQuietHours') ?? true,
      );
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isQuietTime', _isQuietTime);
    if (_currentQuietReason != null) {
      await prefs.setInt('quietReason', _currentQuietReason!.index);
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
      builder: (context) => AlertDialog(
        backgroundColor: _isQuietTime ? Color(0xFF6366F1) : Color(0xFF10B981),
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
          children: QuietReason.values.map((reason) {
            return Container(
              margin: EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  reason.toString().split('.').last,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
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

              // Simple clean toggle button with slower, themed ripple effect
              Material(
                color: Colors.white.withOpacity(0.2),
                shape: CircleBorder(),
                child: InkWell(
                  onTap: _toggleQuietTime,
                  onLongPress: _showQuietReasonDialog,
                  customBorder: CircleBorder(),
                  splashColor: (_isQuietTime 
                      ? Color(0xFF4F46E5) 
                      : Color(0xFF059669)).withOpacity(0.3),
                  highlightColor: (_isQuietTime 
                      ? Color(0xFF6366F1) 
                      : Color(0xFF10B981)).withOpacity(0.2),
                  splashFactory: InkRipple.splashFactory,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: 200,
                    height: 200,
                    child: Center(
                      child: Icon(
                        _isQuietTime ? Icons.nights_stay : Icons.volume_up,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 25),

              // Go Invisible button with toggle functionality
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _sharingMode = _sharingMode == SharingMode.invisible 
                        ? SharingMode.named 
                        : SharingMode.invisible;
                  });
                  _saveSettings();
                  HapticFeedback.lightImpact();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _sharingMode == SharingMode.invisible 
                          ? Icons.visibility 
                          : Icons.visibility_off, 
                      size: 20
                    ),
                    SizedBox(width: 8),
                    Text(_sharingMode == SharingMode.invisible 
                        ? 'Go Visible' 
                        : 'Go Invisible'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHousematesList() {
    // Only show housemates who are sharing details
    final visibleHousemates = _housemates.where((h) => h.shareDetails).toList();
    final hiddenCount = _housemates.length - visibleHousemates.length;

    return Expanded(
      child: Column(
        children: [
          if (hiddenCount > 0) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility_off,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 8),
                    Text(
                      '$hiddenCount housemate${hiddenCount > 1 ? 's' : ''} in private mode',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
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

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors:
                    needsQuiet
                        ? [Color(0xFF6366F1), Color(0xFF4F46E5)]
                        : [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              needsQuiet ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: Colors.white,
              size: 24,
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
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    if (isAway) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Away',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4),
                if (needsQuiet) 
                  Text(
                    person.quietReason?.displayName ?? 'Needs quiet time',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                if (_privacySettings.shareActiveHours &&
                    person.generalActivity != null && !needsQuiet) ...[
                  SizedBox(height: 2),
                  Text(
                    'Currently: ${person.generalActivity}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:
                  needsQuiet
                      ? Color(0xFF6366F1).withOpacity(0.1)
                      : Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              needsQuiet ? 'Quiet' : 'Available',
              style: TextStyle(
                color: needsQuiet ? Color(0xFF4F46E5) : Color(0xFF059669),
                fontWeight: FontWeight.w600,
                fontSize: 14,
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
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invite code copied!')),
                    );
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
