// lib/screens/home_screen.dart (Updated with Home/Away Toggle)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/quiet_time_toggle_button.dart';
import '../widgets/home_away_toggle_button.dart';
import '../services/subscription_service.dart';
import '../services/wifi_location_service.dart';
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
  WiFiLocationService? _locationService;

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
    _initializeServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationService?.removeListener(_onLocationChanged);
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      _locationService = WiFiLocationService();
      await _locationService!.initialize();
      _locationService!.addListener(_onLocationChanged);
      await _loadSettings();
    } catch (e) {
      debugPrint('Error initializing services: $e');
      // Continue without location service if it fails
      await _loadSettings();
    }
  }

  void _onLocationChanged() {
    if (mounted && _locationService != null) {
      setState(() {
        // Update the "You" entry with current location status
        final youIndex = _housemates.indexWhere((h) => h.name == 'You');
        if (youIndex != -1) {
          _housemates[youIndex] = _housemates[youIndex].copyWith(
            isHome: _locationService!.isAtHome,
            generalActivity: _locationService!.isAtHome ? 'active' : 'away',
          );
        }
      });
    }
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
          isHome: _locationService?.isAtHome ?? true,
          quietStartTime: _isQuietTime ? DateTime.now() : null,
        );
      }
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

  void _onHomeAwayToggle(bool isAtHome) {
    _locationService?.setHomeStatus(isAtHome);
  }

  void _showLocationSettings() {
    if (_locationService == null) {
      _showErrorDialog('Location service not available');
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => LocationSettingsDialog(
            isAutoLocationEnabled: _locationService!.autoLocationEnabled,
            homeWifiName: _locationService!.homeWifiName,
            onAutoLocationToggle: (enabled) {
              _locationService!.setAutoLocationEnabled(enabled);
            },
            onSetHomeWifi: () async {
              Navigator.pop(context); // Close settings dialog
              await _showWifiSelection();
            },
          ),
    );
  }

  Future<void> _showWifiSelection() async {
    if (_locationService == null) {
      _showErrorDialog('Location service not available');
      return;
    }

    try {
      // Check permissions first
      final hasPermission = await _locationService!.hasLocationPermission();
      if (!hasPermission) {
        final granted = await _locationService!.requestLocationPermission();
        if (!granted) {
          _showPermissionDeniedDialog();
          return;
        }
      }

      // Show loading dialog while scanning for networks
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Scanning for WiFi networks...'),
                ],
              ),
            ),
      );

      final networks = await _locationService!.getAvailableWifiNetworks();
      Navigator.pop(context); // Close loading dialog

      if (!mounted) return;

      // Show network selection dialog
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Select Home WiFi'),
              content: Container(
                width: double.maxFinite,
                height: 300,
                child: ListView.builder(
                  itemCount: networks.length,
                  itemBuilder: (context, index) {
                    final network = networks[index];
                    final isCurrentHome =
                        network == _locationService!.homeWifiName;

                    return ListTile(
                      leading: Icon(
                        Icons.wifi,
                        color: isCurrentHome ? Color(0xFF10B981) : Colors.grey,
                      ),
                      title: Text(network),
                      trailing:
                          isCurrentHome
                              ? Icon(Icons.check, color: Color(0xFF10B981))
                              : null,
                      onTap: () async {
                        Navigator.pop(context);
                        await _setHomeWifi(network);
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
              ],
            ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if open
      _showErrorDialog('Failed to scan WiFi networks: ${e.toString()}');
    }
  }

  Future<void> _setHomeWifi(String wifiName) async {
    if (_locationService == null) return;

    try {
      await _locationService!.setHomeWifi();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Home WiFi set to: $wifiName'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      _showErrorDialog('Failed to set home WiFi: ${e.toString()}');
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Location Permission Required'),
            content: Text(
              'To automatically detect when you\'re home, Hush needs location permission to access WiFi network information.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  if (_locationService != null) {
                    final granted =
                        await _locationService!.requestLocationPermission();
                    if (granted) {
                      _showWifiSelection();
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Location service is not available'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Grant Permission'),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [_buildHeader(), Expanded(child: _buildHousematesList())],
      ),
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
        child: Stack(
          children: [
            Padding(
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
                        icon: Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 28,
                        ),
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
                  // Only show Too Loud button in center if there are available housemates
                  if (_availableHousemates.isNotEmpty)
                    TooLoudButton(
                      onRequestSent: () {
                        // Optional: Could track noise complaints for household harmony
                      },
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
                            _sharingMode =
                                _sharingMode == SharingMode.invisible
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
            // Home/Away toggle button positioned in bottom left corner
            Positioned(
              bottom: 20, // Increased from 15 to give more space
              left: 20,
              child:
                  _locationService != null
                      ? HomeAwayToggleButton(
                        isAtHome: _locationService!.isAtHome,
                        onToggle: _onHomeAwayToggle,
                        onSettingsPressed: _showLocationSettings,
                      )
                      : Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        child: Icon(
                          Icons.home_rounded,
                          color: Colors.white.withOpacity(0.7),
                          size: 24,
                        ),
                      ), // Show placeholder if service not ready
            ),
            // Request Quiet button positioned in bottom right corner - small round button
            Positioned(
              bottom: 20, // Increased from 15 to give more space
              right: 20,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: CircleBorder(),
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await NotificationService().sendQuietRequest();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text('Quiet request sent anonymously'),
                              ],
                            ),
                            backgroundColor: Color(0xFF6366F1),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    customBorder: CircleBorder(),
                    child: Center(
                      child: Icon(
                        Icons.nightlight_round,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHousemateCard(UserStatus person) {
    final bool isCurrentUser = person.name == 'You';
    final bool needsQuiet = person.isQuietTime;
    final bool isAway = !person.isHome;

    // Apply opacity for away status to both current user and other members
    final double cardOpacity = isAway ? 0.5 : 1.0;

    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: cardOpacity,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                needsQuiet
                    ? Color(0xFF6366F1).withOpacity(0.3)
                    : isAway
                    ? Color(0xFF9CA3AF).withOpacity(0.3)
                    : Color(0xFFE5E7EB),
            width: needsQuiet ? 2 : 1,
          ),
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
            // Avatar with status indicator
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors:
                          needsQuiet
                              ? [Color(0xFF6366F1), Color(0xFF4F46E5)]
                              : isAway
                              ? [Color(0xFF9CA3AF), Color(0xFF6B7280)]
                              : [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      person.displayName.isNotEmpty
                          ? person.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Status indicator dot
                if (needsQuiet || isAway)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color:
                            needsQuiet ? Color(0xFF6366F1) : Color(0xFF9CA3AF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        needsQuiet ? Icons.bedtime : Icons.directions_walk,
                        color: Colors.white,
                        size: 8,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 16),
            // Name and status info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.displayName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isAway ? Color(0xFF6B7280) : Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: 4),
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
                      isAway
                          ? 'Currently: away'
                          : 'Currently: ${person.generalActivity}',
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
                          ? Color(0xFF6B7280)
                          : Color(0xFF059669),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Also update the _buildHousematesList method to use this new card builder:
  Widget _buildHousematesList() {
    // Only show housemates who are not in invisible mode
    final visibleHousemates =
        _housemates
            .where((h) => h.sharingMode != SharingMode.invisible)
            .toList();
    final hiddenCount = _housemates.length - visibleHousemates.length;

    return Expanded(
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Location status indicator for current user (keep existing code)
            if (_privacySettings.shareLocation && _locationService != null)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        _locationService!.isAtHome
                            ? [
                              Color(0xFF10B981).withOpacity(0.1),
                              Color(0xFFE8F5E9),
                            ]
                            : [
                              Color(0xFFFF9800).withOpacity(0.1),
                              Color(0xFFFFF3E0),
                            ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        _locationService!.isAtHome
                            ? Color(0xFF10B981)
                            : Color(0xFFFF9800),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            _locationService!.isAtHome
                                ? Color(0xFF10B981).withOpacity(0.2)
                                : Color(0xFFFF9800).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _locationService!.isAtHome
                            ? Icons.home
                            : Icons.directions_walk,
                        color:
                            _locationService!.isAtHome
                                ? Color(0xFF10B981)
                                : Color(0xFFFF9800),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You are ${_locationService!.statusText}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color:
                                  _locationService!.isAtHome
                                      ? Color(0xFF10B981)
                                      : Color(0xFFFF9800),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _locationService!.statusDescription,
                            style: TextStyle(
                              color:
                                  _locationService!.isAtHome
                                      ? Color(0xFF10B981)
                                      : Color(0xFFFF9800),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.location_on,
                      color:
                          _locationService!.isAtHome
                              ? Color(0xFF10B981)
                              : Color(0xFFFF9800),
                      size: 18,
                    ),
                  ],
                ),
              ),

            // Use the new card builder for all household members
            ...visibleHousemates.map((person) => _buildHousemateCard(person)),

            // Hidden count indicator (keep existing code)
            if (hiddenCount > 0)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility_off,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '$hiddenCount housemate${hiddenCount > 1 ? 's' : ''} in private mode',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 100), // Bottom padding for floating buttons
          ],
        ),
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

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Hush',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.nights_stay,
        size: 40,
        color: Theme.of(context).colorScheme.primary,
      ),
      applicationLegalese: '© 2025 Hush App. All rights reserved.',
      children: [
        SizedBox(height: 16),
        Text(
          'A privacy-first app for coordinating quiet times with your housemates.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: 16),
        Text('Version 1.0.0', style: Theme.of(context).textTheme.bodySmall),
      ],
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Subscription Management
                  Consumer<SubscriptionService>(
                    builder: (context, subscription, child) {
                      return ListTile(
                        leading: Icon(
                          subscription.isPremium
                              ? Icons.star
                              : Icons.star_border,
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
                    leading: Icon(Icons.location_on),
                    title: Text('Location Settings'),
                    subtitle: Text('Configure home/away detection'),
                    onTap: () {
                      Navigator.pop(context);
                      _showLocationSettings();
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
                                  onPressed:
                                      () => Navigator.pop(context, false),
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
          ),
    );
  }
}
