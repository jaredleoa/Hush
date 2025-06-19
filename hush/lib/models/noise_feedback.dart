// lib/models/noise_feedback.dart
enum NoiseComplaintType { tooLoud, quietRequest, general }

class NoiseFeedback {
  final String id;
  final DateTime timestamp;
  final NoiseComplaintType type;
  final bool isAnonymous;
  final String? householdId;
  final int recipientCount; // How many people received the notification

  NoiseFeedback({
    required this.id,
    required this.timestamp,
    required this.type,
    this.isAnonymous = true,
    this.householdId,
    this.recipientCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'type': type.index,
    'isAnonymous': isAnonymous,
    'householdId': householdId,
    'recipientCount': recipientCount,
  };

  factory NoiseFeedback.fromJson(Map<String, dynamic> json) => NoiseFeedback(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    type: NoiseComplaintType.values[json['type']],
    isAnonymous: json['isAnonymous'] ?? true,
    householdId: json['householdId'],
    recipientCount: json['recipientCount'] ?? 0,
  );
}
