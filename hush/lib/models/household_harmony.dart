import 'dart:ui';

class HouseholdHarmony {
  final double score; // 0.0 to 1.0
  final int quietRequestsRespected;
  final int totalQuietRequests;
  final int anonymousFeedbackCount;
  final DateTime lastUpdated;

  HouseholdHarmony({
    required this.score,
    this.quietRequestsRespected = 0,
    this.totalQuietRequests = 0,
    this.anonymousFeedbackCount = 0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  String get statusText {
    if (score >= 0.9) return 'Harmonious';
    if (score >= 0.8) return 'Peaceful';
    if (score >= 0.7) return 'Considerate';
    if (score >= 0.6) return 'Improving';
    if (score >= 0.5) return 'Needs Attention';
    return 'Needs Work';
  }

  Color get statusColor {
    if (score >= 0.8) return const Color(0xFF10B981); // Green
    if (score >= 0.7) return const Color(0xFF3B82F6); // Blue
    if (score >= 0.6) return const Color(0xFFF59E0B); // Yellow
    return const Color(0xFFEF4444); // Red
  }

  String get emoji {
    if (score >= 0.9) return '🌿';
    if (score >= 0.8) return '🕊️';
    if (score >= 0.7) return '🤝';
    if (score >= 0.6) return '📈';
    if (score >= 0.5) return '⚠️';
    return '🔄';
  }

  int get percentageScore => (score * 100).round();

  HouseholdHarmony copyWith({
    double? score,
    int? quietRequestsRespected,
    int? totalQuietRequests,
    int? anonymousFeedbackCount,
    DateTime? lastUpdated,
  }) {
    return HouseholdHarmony(
      score: score ?? this.score,
      quietRequestsRespected: quietRequestsRespected ?? this.quietRequestsRespected,
      totalQuietRequests: totalQuietRequests ?? this.totalQuietRequests,
      anonymousFeedbackCount: anonymousFeedbackCount ?? this.anonymousFeedbackCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
    'score': score,
    'quietRequestsRespected': quietRequestsRespected,
    'totalQuietRequests': totalQuietRequests,
    'anonymousFeedbackCount': anonymousFeedbackCount,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory HouseholdHarmony.fromJson(Map<String, dynamic> json) => HouseholdHarmony(
    score: json['score']?.toDouble() ?? 0.85,
    quietRequestsRespected: json['quietRequestsRespected'] ?? 0,
    totalQuietRequests: json['totalQuietRequests'] ?? 0,
    anonymousFeedbackCount: json['anonymousFeedbackCount'] ?? 0,
    lastUpdated: DateTime.tryParse(json['lastUpdated'] ?? '') ?? DateTime.now(),
  );
}
