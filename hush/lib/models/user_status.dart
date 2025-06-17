import 'quiet_reason.dart';
import 'sharing_mode.dart';

// User Status Model - Minimal info focused on noise consideration
class UserStatus {
  final String name;
  final bool isQuietTime; // Core feature: do they need quiet?
  final QuietReason? quietReason; // Why they need quiet
  final SharingMode sharingMode; // How they want to appear
  final bool isHome; // Only if user chose to share location
  final String? generalActivity; // Vague: "resting", "active", "away"
  final bool shareDetails; // Whether they're sharing any details at all
  final DateTime? quietStartTime; // When quiet time started

  UserStatus({
    required this.name,
    required this.isQuietTime,
    this.quietReason,
    this.sharingMode = SharingMode.named,
    this.isHome = true,
    this.generalActivity,
    this.shareDetails = true,
    this.quietStartTime,
  });

  String get displayName {
    switch (sharingMode) {
      case SharingMode.named:
        return name;
      case SharingMode.anonymous:
        return 'Someone';
      case SharingMode.invisible:
        return '';
    }
  }

  String get quietStatusText {
    if (!isQuietTime) return '';
    
    final reason = quietReason?.displayName ?? 'needs quiet';
    switch (sharingMode) {
      case SharingMode.named:
        return '$name $reason';
      case SharingMode.anonymous:
        return 'Someone $reason';
      case SharingMode.invisible:
        return '';
    }
  }

  UserStatus copyWith({
    String? name,
    bool? isQuietTime,
    QuietReason? quietReason,
    SharingMode? sharingMode,
    bool? isHome,
    String? generalActivity,
    bool? shareDetails,
    DateTime? quietStartTime,
  }) {
    return UserStatus(
      name: name ?? this.name,
      isQuietTime: isQuietTime ?? this.isQuietTime,
      quietReason: quietReason ?? this.quietReason,
      sharingMode: sharingMode ?? this.sharingMode,
      isHome: isHome ?? this.isHome,
      generalActivity: generalActivity ?? this.generalActivity,
      shareDetails: shareDetails ?? this.shareDetails,
      quietStartTime: quietStartTime ?? this.quietStartTime,
    );
  }
}
