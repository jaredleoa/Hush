// lib/services/notification_service.dart
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

    await _notifications.show(0, 'Hush', message, notificationDetails);
  }

  static Future<void> sendNoiseAlert(String message) async {
    // Slightly more noticeable for noise alerts
    HapticFeedback.mediumImpact();

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'hush_noise_alerts',
        'Noise Alerts',
        channelDescription: 'Anonymous noise level notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        enableVibration: true,
        playSound: false, // Still no sound to maintain household peace
        vibrationPattern: Int64List.fromList([
          0,
          300,
          100,
          300,
        ]), // Gentle pattern
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      ),
    );

    await _notifications.show(
      1, // Different ID from gentle reminders
      'Hush 🤫',
      message,
      notificationDetails,
    );
  }

  static Future<void> householdStatusUpdate(int quietCount) async {
    if (quietCount > 0) {
      final message =
          quietCount == 1
              ? "Someone needs quiet right now"
              : "$quietCount people need quiet right now";
      await sendGentleReminder(message);
    }
  }

  static Future<void> tooLoudNotification() async {
    await sendNoiseAlert("Someone has asked to please keep it down 🤫");
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

  Future<void> sendQuietTimeNotification(
    List<UserStatus> quietHousemates,
  ) async {
    if (!_isAppInBackground || quietHousemates.isEmpty) return;

    await GentleNotificationService.householdStatusUpdate(
      quietHousemates.length,
    );
  }

  Future<void> sendQuietRequest() async {
    await GentleNotificationService.sendGentleReminder(
      "Someone has requested quiet in common areas",
    );
  }

  // NEW: Send "too loud" notification
  Future<void> sendTooLoudNotification() async {
    await GentleNotificationService.tooLoudNotification();
  }
}
