import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/user_status.dart';

// Gentle Notifications Service
class GentleNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static Future<void> initialize() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    
    await _notifications.initialize(initializationSettings);
  }
  
  static Future<void> sendGentleReminder(String message) async {
    // Only haptic feedback for gentle notifications
    HapticFeedback.selectionClick();
    
    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'hush_gentle',
        'Gentle Reminders',
        channelDescription: 'Subtle household notifications',
        importance: Importance.low, // Very subtle
        priority: Priority.low,
        enableVibration: true,
        playSound: false, // NO SOUND
        vibrationPattern: Int64List.fromList([0, 200]), // Very brief vibration
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      ),
    );
    
    // Only show notification if app is in background
    await _notifications.show(
      0,
      'Hush',
      message,
      notificationDetails,
    );
  }
  
  static Future<void> householdStatusUpdate(int quietCount) async {
    if (quietCount > 0) {
      final message = quietCount == 1 
          ? "Someone needs quiet right now"
          : "$quietCount people need quiet right now";
      await sendGentleReminder(message);
    }
  }
}

// Legacy compatibility wrapper
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isAppInBackground = false;

  void setAppState(bool isInBackground) {
    _isAppInBackground = isInBackground;
  }

  Future<void> sendQuietTimeNotification(List<UserStatus> quietHousemates) async {
    if (!_isAppInBackground || quietHousemates.isEmpty) return;
    
    await GentleNotificationService.householdStatusUpdate(quietHousemates.length);
  }

  Future<void> sendQuietRequest() async {
    await GentleNotificationService.sendGentleReminder(
      "Someone has requested quiet in common areas"
    );
  }
}
