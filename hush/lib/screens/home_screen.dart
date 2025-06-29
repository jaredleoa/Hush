// lib/screens/home_screen.dart (Complete Fixed Version)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
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
    await prefs.setBool(
      'shareDetailedStatus',
      _privacySettings.shareDetailedStatus,
    );
    await prefs.setBool('shareLocation', _privacySettings.shareLocation);
    await prefs.setBool('shareActiveHours', _privacySettings.shareActiveHours);
    await prefs.setBool('allowQuietHours', _privacySettings.allowQuietHours);
  }

  void _onQuietReasonSelected(QuietReason reason) {
    setState(() {
      _isQuietTime = true;
      _currentQuietReason = reason;

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
    HapticFeedback.mediumImpact();
  }

  void _onQuietToggle(bool isQuiet) {
    if (isQuiet) {
      // Show reason selection dialog
      _showQuietReasonDialog();
    } else {
      setState(() {
        _isQuietTime = false;
        _currentQuietReason = null;

        // Update the "You" entry in housemates
        final youIndex = _housemates.indexWhere((h) => h.name == 'You');
        if (youIndex != -1) {
          _housemates[youIndex] = _housemates[youIndex].copyWith(
            isQuietTime: false,
            quietReason: null,
            quietStartTime: null,
          );
        }
      });
      _saveSettings();
      HapticFeedback.lightImpact();
    }
  }

  void _showQuietReasonDialog() {
    showDialog(
      context: context,
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
            onAutoLocationToggle: (enabled) async {
              try {
                final success = await _locationService!.setAutoLocationEnabled(
                  enabled,
                );
                if (!success && enabled) {
                  // Show error message if enabling auto location failed
                  if (mounted) {
                    Navigator.of(context).pop(); // Close the dialog first

                    // Show permission error dialog
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.location_off,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Permission Required',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WiFi-based auto detection requires location permission to access your network information.',
                                  style: TextStyle(fontSize: 16, height: 1.4),
                                ),
                                SizedBox(height: 16),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Your location data stays private and is only used locally to detect your home WiFi.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue[800],
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
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  openAppSettings();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF6366F1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Open Settings',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                    );
                  }
                }
              } catch (e) {
                debugPrint('Error toggling auto location: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to change location settings. Please try again.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
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
            (context) => Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Detecting WiFi networks...'),
                    ],
                  ),
                ),
              ),
            ),
      );

      // Get available networks
      final networks = await _locationService!.getAvailableWifiNetworks();

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show network selection dialog
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Select Home WiFi'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      networks.map((network) {
                        return ListTile(
                          leading: Icon(Icons.wifi),
                          title: Text(network),
                          onTap: () async {
                            Navigator.pop(context);
                            try {
                              // Set this as home WiFi
                              _locationService!._homeWifiName = network;
                              await _locationService!._saveSettings();
                              _locationService!.notifyListeners();

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Home WiFi set to: $network'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                _showErrorDialog('Failed to set home WiFi: $e');
                              }
                            }
                          },
                        );
                      }).toList(),
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
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if open
        _showErrorDialog('Failed to get WiFi networks: $e');
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Permission Required'),
            content: Text(
              'Location permission is required to detect WiFi networks for automatic home/away detection.',
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
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Location service is not available'),
                          ),
                        );
                      }
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

  // Build household member card with consistent styling
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
        child: Stack(
          children: [
            // Settings button
            Positioned(
              top: 15,
              left: 20,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showSettingsSheet,
                    borderRadius: BorderRadius.circular(12),
                    child: Icon(Icons.settings, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
            // Header content
            Padding(
              padding: EdgeInsets.fromLTRB(20, 70, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        DateTime.now().hour < 12
                            ? 'Good morning'
                            : DateTime.now().hour < 17
                            ? 'Good afternoon'
                            : 'Good evening',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        DateTime.now().hour < 12
                            ? Icons.wb_sunny
                            : DateTime.now().hour < 17
                            ? Icons.wb_sunny_outlined
                            : Icons.nights_stay,
                        color: Colors.white.withOpacity(0.8),
                        size: 20,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    _householdName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 24),
                  // Main action button
                  Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      child: QuietTimeToggleButton(
                        isQuietTime: _isQuietTime,
                        currentReason: _currentQuietReason,
                        onToggle: _onQuietToggle,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  // Invisible mode toggle
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
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
                  ),
                ],
              ),
            ),
            // Home/Away toggle button positioned in bottom left corner
            Positioned(
              bottom: 20,
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
            // Request Quiet button positioned in bottom right corner
            Positioned(
              bottom: 20,
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

  Widget _buildHousematesList() {
    // Only show housemates who are not in invisible mode
    final visibleHousemates =
        _housemates
            .where((h) => h.sharingMode != SharingMode.invisible)
            .toList();
    final hiddenCount = _housemates.length - visibleHousemates.length;

    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Location status indicator for current user
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

          // Hidden count indicator
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
    );
  }

  void _showSettingsSheet() {
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
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                // Settings title
                Text(
                  'Settings',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                // Settings options
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
                SizedBox(height: 20),
              ],
            ),
          ),
    );
  }
}

// Location settings dialog
class LocationSettingsDialog extends StatefulWidget {
  final bool isAutoLocationEnabled;
  final String? homeWifiName;
  final Function(bool) onAutoLocationToggle;
  final VoidCallback? onSetHomeWifi;

  const LocationSettingsDialog({
    Key? key,
    required this.isAutoLocationEnabled,
    this.homeWifiName,
    required this.onAutoLocationToggle,
    this.onSetHomeWifi,
  }) : super(key: key);

  @override
  State<LocationSettingsDialog> createState() => _LocationSettingsDialogState();
}

class _LocationSettingsDialogState extends State<LocationSettingsDialog> {
  late bool _autoLocationEnabled;

  @override
  void initState() {
    super.initState();
    _autoLocationEnabled = widget.isAutoLocationEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.location_on, color: Color(0xFF6366F1), size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Location Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose how you want to manage your home/away status:',
            style: TextStyle(fontSize: 16, height: 1.4),
          ),
          SizedBox(height: 20),
          // Manual Option
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  !_autoLocationEnabled
                      ? Color(0xFF6366F1).withOpacity(0.1)
                      : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    !_autoLocationEnabled
                        ? Color(0xFF6366F1).withOpacity(0.3)
                        : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Radio<bool>(
                  value: false,
                  groupValue: _autoLocationEnabled,
                  onChanged: (value) {
                    setState(() => _autoLocationEnabled = false);
                    widget.onAutoLocationToggle(false);
                  },
                  activeColor: Color(0xFF6366F1),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manual Control',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tap the button to toggle between home and away',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          // Automatic Option
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  _autoLocationEnabled
                      ? Color(0xFF10B981).withOpacity(0.1)
                      : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    _autoLocationEnabled
                        ? Color(0xFF10B981).withOpacity(0.3)
                        : Colors.grey[300]!,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: _autoLocationEnabled,
                      onChanged: (value) {
                        setState(() => _autoLocationEnabled = true);
                        widget.onAutoLocationToggle(true);
                      },
                      activeColor: Color(0xFF10B981),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WiFi-Based Auto Detection',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Automatically detect when you\'re home based on WiFi network',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_autoLocationEnabled) ...[
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          widget.homeWifiName != null
                              ? Color(0xFF10B981).withOpacity(0.1)
                              : Color(0xFFFF9800).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.homeWifiName != null
                          ? 'Home WiFi: ${widget.homeWifiName}'
                          : 'No home WiFi set',
                      style: TextStyle(
                        color:
                            widget.homeWifiName != null
                                ? Color(0xFF10B981)
                                : Color(0xFFFF9800),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onSetHomeWifi,
                      icon: Icon(Icons.wifi, size: 18),
                      label: Text('Set Home WiFi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF10B981),
                        side: BorderSide(color: Color(0xFF10B981)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your location data is private and only used to show home/away status to your housemates.',
                    style: TextStyle(fontSize: 14, color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Done'),
        ),
      ],
    );
  }
}
