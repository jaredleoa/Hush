// lib/services/wifi_location_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class WiFiLocationService extends ChangeNotifier {
  static final WiFiLocationService _instance = WiFiLocationService._internal();
  factory WiFiLocationService() => _instance;
  WiFiLocationService._internal();

  bool _isAtHome = true;
  bool _autoLocationEnabled = false;
  String? _homeWifiName;
  String? _currentWifiName;
  Timer? _locationCheckTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool get isAtHome => _isAtHome;
  bool get autoLocationEnabled => _autoLocationEnabled;
  String? get homeWifiName => _homeWifiName;
  String? get currentWifiName => _currentWifiName;

  // Initialize the service
  Future<void> initialize() async {
    await _loadSettings();
    if (_autoLocationEnabled) {
      _startLocationMonitoring();
    }
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAtHome = prefs.getBool('isAtHome') ?? true;
      _autoLocationEnabled = prefs.getBool('autoLocationEnabled') ?? false;
      _homeWifiName = prefs.getString('homeWifiName');

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading location settings: $e');
    }
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAtHome', _isAtHome);
      await prefs.setBool('autoLocationEnabled', _autoLocationEnabled);
      if (_homeWifiName != null) {
        await prefs.setString('homeWifiName', _homeWifiName!);
      }
    } catch (e) {
      debugPrint('Error saving location settings: $e');
    }
  }

  // Manually set home/away status
  Future<void> setHomeStatus(bool isAtHome) async {
    if (_isAtHome != isAtHome) {
      _isAtHome = isAtHome;
      await _saveSettings();
      notifyListeners();
      debugPrint('Location manually set to: ${isAtHome ? "Home" : "Away"}');
    }
  }

  // Enable/disable auto location detection
  Future<void> setAutoLocationEnabled(bool enabled) async {
    _autoLocationEnabled = enabled;
    await _saveSettings();

    if (enabled) {
      final hasPermission = await hasLocationPermission();
      if (hasPermission) {
        _startLocationMonitoring();
      } else {
        final granted = await requestLocationPermission();
        if (granted) {
          _startLocationMonitoring();
        } else {
          // Permission denied, disable auto location
          _autoLocationEnabled = false;
          await _saveSettings();
          throw Exception('Location permission required for auto detection');
        }
      }
    } else {
      _stopLocationMonitoring();
    }

    notifyListeners();
    debugPrint('Auto location ${enabled ? "enabled" : "disabled"}');
  }

  // Set the home WiFi network
  Future<void> setHomeWifi() async {
    try {
      final currentWifi = await _getCurrentWifiName();

      if (currentWifi != null) {
        _homeWifiName = currentWifi;
        await _saveSettings();

        // Check if we're currently at home
        if (_autoLocationEnabled) {
          await _checkLocationBasedOnWifi();
        }

        notifyListeners();
        debugPrint('Home WiFi set to: $currentWifi');
      } else {
        throw Exception(
          'No WiFi network detected. Please connect to your home WiFi first.',
        );
      }
    } catch (e) {
      debugPrint('Error setting home WiFi: $e');
      rethrow;
    }
  }

  // Start monitoring location changes
  void _startLocationMonitoring() {
    _stopLocationMonitoring(); // Stop any existing monitoring

    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      _checkLocationBasedOnWifi();
    });

    // Also check periodically in case of WiFi network changes
    _locationCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _checkLocationBasedOnWifi();
    });

    // Do an immediate check
    _checkLocationBasedOnWifi();

    debugPrint('Location monitoring started');
  }

  // Stop monitoring location changes
  void _stopLocationMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _locationCheckTimer?.cancel();
    _locationCheckTimer = null;
    debugPrint('Location monitoring stopped');
  }

  // Check if user is at home based on WiFi
  Future<void> _checkLocationBasedOnWifi() async {
    if (!_autoLocationEnabled || _homeWifiName == null) return;

    try {
      final currentWifi = await _getCurrentWifiName();
      _currentWifiName = currentWifi;

      // Clean WiFi names for comparison (remove quotes if present)
      final cleanCurrentWifi = currentWifi?.replaceAll('"', '');
      final cleanHomeWifi = _homeWifiName?.replaceAll('"', '');

      final isAtHome =
          cleanCurrentWifi != null &&
          cleanHomeWifi != null &&
          cleanCurrentWifi == cleanHomeWifi;

      if (_isAtHome != isAtHome) {
        _isAtHome = isAtHome;
        await _saveSettings();
        notifyListeners();
        debugPrint(
          'Location auto-detected: ${isAtHome ? "Home" : "Away"} (WiFi: $cleanCurrentWifi)',
        );
      }
    } catch (e) {
      debugPrint('Error checking WiFi location: $e');
    }
  }

  // Get current WiFi network name
  Future<String?> _getCurrentWifiName() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      // Check if connected to WiFi
      if (!connectivityResult.contains(ConnectivityResult.wifi)) {
        return null;
      }

      // Get WiFi network info
      final networkInfo = NetworkInfo();
      final wifiName = await networkInfo.getWifiName();

      return wifiName;
    } catch (e) {
      debugPrint('Error getting WiFi name: $e');
      return null;
    }
  }

  // Get available WiFi networks (Note: This is limited on mobile platforms)
  Future<List<String>> getAvailableWifiNetworks() async {
    // Note: On iOS and Android, apps cannot scan for available WiFi networks
    // due to privacy restrictions. We can only get the currently connected network.

    try {
      final currentWifi = await _getCurrentWifiName();
      final networks = <String>[];

      if (currentWifi != null) {
        networks.add(currentWifi.replaceAll('"', ''));
      }

      // Add some common network name suggestions
      networks.addAll([
        'Home_Network_5G',
        'Home_Network_2.4G',
        'MyWiFi',
        'Home_WiFi',
      ]);

      // Remove duplicates
      return networks.toSet().toList();
    } catch (e) {
      debugPrint('Error getting available networks: $e');
      // Return some common suggestions if we can't get the current network
      return ['Home_Network_5G', 'Home_Network_2.4G', 'MyWiFi', 'Home_WiFi'];
    }
  }

  // Check if location permissions are granted
  Future<bool> hasLocationPermission() async {
    try {
      final status = await Permission.location.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return false;
    }
  }

  // Request location permissions
  Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _stopLocationMonitoring();
    super.dispose();
  }
}

// Extension for easy access from other parts of the app
extension WiFiLocationServiceExtension on WiFiLocationService {
  // Quick method to toggle home/away manually
  Future<void> toggleHomeStatus() async {
    await setHomeStatus(!isAtHome);
  }

  // Get status text for UI
  String get statusText => isAtHome ? 'At Home' : 'Away';

  // Get status description
  String get statusDescription {
    if (!autoLocationEnabled) {
      return 'Manual control';
    } else if (homeWifiName == null) {
      return 'Auto (no home WiFi set)';
    } else {
      return 'Auto (WiFi: ${homeWifiName?.replaceAll('"', '') ?? 'Unknown'})';
    }
  }
}
