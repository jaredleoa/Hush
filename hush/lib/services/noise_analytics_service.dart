// lib/services/noise_analytics_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/noise_feedback.dart';
import '../models/household_harmony.dart';

class NoiseAnalyticsService {
  static const String _feedbackKey = 'noise_feedback_history';
  static const String _harmonyKey = 'household_harmony';

  // Log a noise-related event
  static Future<void> logNoiseFeedback(
    NoiseComplaintType type,
    int recipientCount,
    {bool isAnonymous = true}) async {
    final feedback = NoiseFeedback(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: type,
      recipientCount: recipientCount,
      isAnonymous: isAnonymous,
    );

    await _saveFeedback(feedback);
    await _updateHouseholdHarmony();
  }

  static Future<void> _saveFeedback(NoiseFeedback feedback) async {
    final prefs = await SharedPreferences.getInstance();
    final feedbackHistory = await getFeedbackHistory();
    feedbackHistory.add(feedback);

    // Keep only last 50 feedback entries to avoid storage bloat
    if (feedbackHistory.length > 50) {
      feedbackHistory.removeRange(0, feedbackHistory.length - 50);
    }

    final jsonList = feedbackHistory.map((f) => f.toJson()).toList();
    await prefs.setString(_feedbackKey, json.encode(jsonList));
  }

  static Future<List<NoiseFeedback>> getFeedbackHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_feedbackKey);

    if (jsonString == null) return [];

    final jsonList = json.decode(jsonString) as List;
    return jsonList.map((j) => NoiseFeedback.fromJson(j)).toList();
  }

  static Future<void> _updateHouseholdHarmony() async {
    final feedbackHistory = await getFeedbackHistory();
    final recentFeedback =
        feedbackHistory
            .where(
              (f) => f.timestamp.isAfter(
                DateTime.now().subtract(Duration(days: 7)),
              ),
            )
            .toList();

    // Simple harmony calculation
    double harmonyScore = 0.85; // Base score

    // Reduce score based on recent complaints
    final tooLoudComplaints =
        recentFeedback
            .where((f) => f.type == NoiseComplaintType.tooLoud)
            .length;

    final quietRequests =
        recentFeedback
            .where((f) => f.type == NoiseComplaintType.quietRequest)
            .length;

    // Adjust harmony score
    harmonyScore -= (tooLoudComplaints * 0.05); // Each complaint reduces by 5%
    harmonyScore -= (quietRequests * 0.02); // Each request reduces by 2%

    // Keep score between 0 and 1
    harmonyScore = harmonyScore.clamp(0.0, 1.0);

    final harmony = HouseholdHarmony(
      score: harmonyScore,
      quietRequestsRespected: _calculateRequestsRespected(feedbackHistory),
      totalQuietRequests: quietRequests + tooLoudComplaints,
      anonymousFeedbackCount: recentFeedback.length,
    );

    await _saveHouseholdHarmony(harmony);
  }

  static int _calculateRequestsRespected(List<NoiseFeedback> feedback) {
    // Simple heuristic: assume requests are respected if there's a gap after complaints
    int respected = 0;
    for (int i = 0; i < feedback.length - 1; i++) {
      final current = feedback[i];
      final next = feedback[i + 1];

      if (current.type == NoiseComplaintType.tooLoud &&
          next.timestamp.difference(current.timestamp).inHours > 1) {
        respected++;
      }
    }
    return respected;
  }

  static Future<void> _saveHouseholdHarmony(HouseholdHarmony harmony) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_harmonyKey, json.encode(harmony.toJson()));
  }

  static Future<HouseholdHarmony> getHouseholdHarmony() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_harmonyKey);

    if (jsonString == null) {
      return HouseholdHarmony(score: 0.85); // Default good harmony
    }

    return HouseholdHarmony.fromJson(json.decode(jsonString));
  }

  // Get insights for display
  static Future<Map<String, dynamic>> getNoiseInsights() async {
    final feedbackHistory = await getFeedbackHistory();
    final recentFeedback =
        feedbackHistory
            .where(
              (f) => f.timestamp.isAfter(
                DateTime.now().subtract(Duration(days: 7)),
              ),
            )
            .toList();

    return {
      'totalFeedback': recentFeedback.length,
      'tooLoudComplaints':
          recentFeedback
              .where((f) => f.type == NoiseComplaintType.tooLoud)
              .length,
      'quietRequests':
          recentFeedback
              .where((f) => f.type == NoiseComplaintType.quietRequest)
              .length,
      'averageRecipientsPerNotification':
          recentFeedback.isEmpty
              ? 0.0
              : recentFeedback
                      .map((f) => f.recipientCount)
                      .reduce((a, b) => a + b) /
                  recentFeedback.length,
      'peakComplaintHour': _getMostCommonHour(recentFeedback),
    };
  }

  static int? _getMostCommonHour(List<NoiseFeedback> feedback) {
    if (feedback.isEmpty) return null;

    final hourCounts = <int, int>{};
    for (final f in feedback) {
      final hour = f.timestamp.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    return hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}
